import Darwin
import Foundation

@main
struct Beard {
    static func main() {
        do {
            let request = try CLI.parse(arguments: Array(CommandLine.arguments.dropFirst()))

            switch request {
            case .help:
                print(CLI.helpText)
            case .version:
                print(BeardVersion.current)
            case .report(let options):
                let report = try ReportBuilder(commandRunner: ProcessCommandRunner()).build(options: options)

                if options.outputJSON {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let data = try encoder.encode(report)
                    guard let json = String(data: data, encoding: .utf8) else {
                        throw BeardError.runtime("failed to encode report as UTF-8 JSON")
                    }
                    print(json)
                } else {
                    print(TextRenderer.render(report))
                }
            }
        } catch {
            FileHandle.standardError.writeString("beard: error: \(error.localizedDescription)\n")
            FileHandle.standardError.writeString("Run `beard --help` for usage.\n")
            exit(1)
        }
    }
}
