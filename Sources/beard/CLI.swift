import Foundation

enum CLIRequest: Equatable {
    case help
    case version
    case report(ReportOptions)
}

struct ReportOptions: Codable, Equatable {
    var outputJSON = false
    var samples = 2
    var intervalSeconds = 1
    var limit = 8
    var rulesPath: String? = nil
}

enum CLI {
    static let helpText = """
    Beard monitors local macOS battery impact by app/process.

    Usage:
      beard [report] [--json] [--samples N] [--interval SECONDS] [--limit N] [--rules PATH]
      beard --help
      beard --version

    Options:
      --json              Emit a versioned JSON report instead of text.
      --samples N         Number of usable top samples to collect. Default: 2, range: 1-10.
      --interval SECONDS  Seconds between top samples. Default: 1, range: 1-10.
      --limit N           Number of app/process groups to show. Default: 8, range: 1-25.
      --rules PATH        Overlay suggestion rules from a JSON file.

    Notes:
      Beard uses local Apple command-line tools and prints to stdout only.
      Relative power scores often track CPU impact and are not watts or watt-hours.
      Exact per-app battery energy is not exposed by public macOS APIs.
    """

    static func parse(arguments: [String]) throws -> CLIRequest {
        var args = arguments

        if args.isEmpty {
            return .report(ReportOptions())
        }

        if args == ["--help"] || args == ["-h"] || args == ["help"] {
            return .help
        }

        if args == ["--version"] || args == ["version"] {
            return .version
        }

        if args.first == "report" {
            args.removeFirst()
        } else if let first = args.first, first.hasPrefix("-") {
            // Allow `beard --json` as shorthand for `beard report --json`.
        } else {
            throw BeardError.usage("unknown command `\(args[0])`")
        }

        if args == ["--help"] || args == ["-h"] {
            return .help
        }

        var options = ReportOptions()
        var index = 0

        while index < args.count {
            let arg = args[index]

            switch arg {
            case "--json":
                options.outputJSON = true
                index += 1
            case "--samples":
                let value = try value(after: arg, in: args, index: index)
                options.samples = try boundedInteger(value, name: arg, range: 1...10)
                index += 2
            case "--interval":
                let value = try value(after: arg, in: args, index: index)
                options.intervalSeconds = try boundedInteger(value, name: arg, range: 1...10)
                index += 2
            case "--limit":
                let value = try value(after: arg, in: args, index: index)
                options.limit = try boundedInteger(value, name: arg, range: 1...25)
                index += 2
            case "--rules":
                options.rulesPath = try value(after: arg, in: args, index: index)
                index += 2
            default:
                if arg.hasPrefix("--samples=") {
                    options.samples = try boundedInteger(String(arg.dropFirst("--samples=".count)), name: "--samples", range: 1...10)
                    index += 1
                } else if arg.hasPrefix("--interval=") {
                    options.intervalSeconds = try boundedInteger(String(arg.dropFirst("--interval=".count)), name: "--interval", range: 1...10)
                    index += 1
                } else if arg.hasPrefix("--limit=") {
                    options.limit = try boundedInteger(String(arg.dropFirst("--limit=".count)), name: "--limit", range: 1...25)
                    index += 1
                } else if arg.hasPrefix("--rules=") {
                    options.rulesPath = String(arg.dropFirst("--rules=".count))
                    index += 1
                } else {
                    throw BeardError.usage("unknown option `\(arg)`")
                }
            }
        }

        return .report(options)
    }

    private static func value(after option: String, in args: [String], index: Int) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < args.count else {
            throw BeardError.usage("\(option) requires a value")
        }
        return args[valueIndex]
    }

    private static func boundedInteger(_ rawValue: String, name: String, range: ClosedRange<Int>) throws -> Int {
        guard let value = Int(rawValue) else {
            throw BeardError.usage("\(name) must be an integer")
        }

        guard range.contains(value) else {
            throw BeardError.usage("\(name) must be between \(range.lowerBound) and \(range.upperBound)")
        }

        return value
    }
}
