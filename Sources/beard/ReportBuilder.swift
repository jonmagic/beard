import Foundation

struct ReportBuilder {
    let commandRunner: CommandRunning

    func build(options: ReportOptions) throws -> BatteryReport {
        let batteryOutput = try commandRunner.run("/usr/bin/pmset", arguments: ["-g", "batt"])
        let settingsOutput = try commandRunner.run("/usr/bin/pmset", arguments: ["-g", "custom"])
        let topOutput = try commandRunner.run(
            "/usr/bin/top",
            arguments: [
                "-l", String(options.samples + 1),
                "-s", String(options.intervalSeconds),
                "-n", String(max(options.limit * 4, options.limit)),
                "-stats", "pid,command,cpu,power",
            ]
        )
        let processOutput = try commandRunner.run("/bin/ps", arguments: ["axww", "-o", "pid=", "-o", "command="])
        let suggestionRules = try SuggestionRuleLoader.load(explicitPath: options.rulesPath)

        let battery = try Parsers.parseBatteryStatus(batteryOutput)
        let settings = Parsers.parsePowerSettings(settingsOutput)
        let topSamples = try Parsers.parseTopProcessSamples(topOutput)
        let usableTopSamples = Array(topSamples.dropFirst())
        guard !usableTopSamples.isEmpty else {
            throw BeardError.parse("top did not return a usable process sample")
        }
        let topProcesses = ImpactAggregator.average(topSamples: usableTopSamples)
        let processCommands = Parsers.parseProcessCommands(processOutput)
        let apps = ImpactAggregator.aggregate(
            topProcesses: topProcesses,
            processCommands: processCommands,
            limit: options.limit,
            rules: suggestionRules
        )
        let suggestions = SuggestionEngine.suggestions(
            battery: battery,
            powerSettings: settings,
            apps: apps,
            rules: suggestionRules
        )

        return BatteryReport(
            schemaVersion: 2,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            sample: ReportSample(
                usableSamples: usableTopSamples.count,
                topPasses: options.samples + 1,
                intervalSeconds: options.intervalSeconds
            ),
            battery: battery,
            powerSettings: settings,
            apps: apps,
            suggestions: suggestions,
            limitations: [
                "Relative power is a current macOS process score, not watts or watt-hours.",
                "Exact per-app battery energy is not exposed by public macOS APIs.",
                "Output includes local running process names and PIDs but is not transmitted or written by beard.",
            ]
        )
    }
}

enum ImpactAggregator {
    static func average(topSamples: [[TopProcessMetric]]) -> [TopProcessMetric] {
        var buckets: [Int: ProcessAverageBucket] = [:]

        for sample in topSamples {
            for process in sample {
                buckets[process.pid, default: ProcessAverageBucket(pid: process.pid, command: process.command)].add(process)
            }
        }

        return buckets.values
            .map { $0.average }
            .sorted {
                if $0.relativePower == $1.relativePower {
                    return $0.cpuPercent > $1.cpuPercent
                }
                return $0.relativePower > $1.relativePower
            }
    }

    static func aggregate(topProcesses: [TopProcessMetric], processCommands: [Int: String], limit: Int, rules: SuggestionRules? = nil) -> [AppImpact] {
        var buckets: [String: ImpactBucket] = [:]

        for process in topProcesses where process.cpuPercent > 0 || process.relativePower > 0 {
            let name = displayName(
                commandLine: processCommands[process.pid],
                fallback: process.command
            )
            buckets[name, default: ImpactBucket(name: name)].add(process)
        }

        let apps = buckets.values
            .map { $0.impact }
            .sorted {
                if $0.relativePower == $1.relativePower {
                    return $0.cpuPercent > $1.cpuPercent
                }
                return $0.relativePower > $1.relativePower
            }
            .prefix(limit)
            .map { $0 }

        guard let rules else {
            return apps
        }

        return apps.map { app in
            app.categorized(by: rules.matchingCategory(for: app))
        }
    }

    static func displayName(commandLine: String?, fallback: String) -> String {
        guard let commandLine, !commandLine.trimmed.isEmpty else {
            return fallback
        }

        let components = commandLine.split(separator: "/").map(String.init)
        if let appComponent = components.first(where: { $0.hasSuffix(".app") }) {
            return String(appComponent.dropLast(".app".count))
        }

        let executable = commandLine.split(maxSplits: 1, whereSeparator: { $0 == " " || $0 == "\t" }).first.map(String.init) ?? fallback
        if executable.contains("/") {
            return cleanedDisplayName(URL(fileURLWithPath: executable).lastPathComponent)
        }

        return cleanedDisplayName(executable)
    }

    private static func cleanedDisplayName(_ name: String) -> String {
        if name.hasPrefix("("), name.hasSuffix(")"), name.count > 2 {
            return String(name.dropFirst().dropLast())
        }

        return name
    }
}

private struct ProcessAverageBucket {
    let pid: Int
    var command: String
    var relativePower = 0.0
    var cpuPercent = 0.0
    var observations = 0

    mutating func add(_ process: TopProcessMetric) {
        command = process.command
        relativePower += process.relativePower
        cpuPercent += process.cpuPercent
        observations += 1
    }

    var average: TopProcessMetric {
        TopProcessMetric(
            pid: pid,
            command: command,
            cpuPercent: (cpuPercent / Double(observations)).rounded(toPlaces: 1),
            relativePower: (relativePower / Double(observations)).rounded(toPlaces: 1)
        )
    }
}

private struct ImpactBucket {
    let name: String
    var relativePower = 0.0
    var cpuPercent = 0.0
    var pids: [Int] = []
    var processNames: Set<String> = []

    mutating func add(_ process: TopProcessMetric) {
        relativePower += process.relativePower
        cpuPercent += process.cpuPercent
        pids.append(process.pid)
        processNames.insert(process.command)
    }

    var impact: AppImpact {
        AppImpact(
            name: name,
            relativePower: relativePower.rounded(toPlaces: 1),
            cpuPercent: cpuPercent.rounded(toPlaces: 1),
            processCount: pids.count,
            pids: pids.sorted(),
            processNames: processNames.sorted()
        )
    }
}

enum SuggestionEngine {
    static func suggestions(battery: BatteryStatus, powerSettings: PowerSettings, apps: [AppImpact], rules: SuggestionRules? = nil) -> [String] {
        var suggestions: [String] = []
        let suggestionRules: SuggestionRules
        if let rules {
            suggestionRules = rules
        } else {
            suggestionRules = (try? SuggestionRules.embeddedDefaults()) ?? fallbackRules()
        }

        if let state = battery.state, !state.localizedCaseInsensitiveContains("discharging") {
            suggestions.append("You are not currently discharging; rankings still show current relative app impact.")
        }

        for app in apps.prefix(3) where app.relativePower >= suggestionRules.highImpactThreshold || app.cpuPercent >= suggestionRules.highImpactThreshold {
            suggestions.append(highImpactSuggestion(for: app, rules: suggestionRules))
        }

        if apps.isEmpty {
            suggestions.append("No high-impact app/process appeared in the latest sample.")
        }

        switch powerSettings.lowPowerModeLikelyEnabled {
        case .some(true):
            suggestions.append("Low Power Mode appears to be on.")
        case .some(false):
            suggestions.append("Turn on Low Power Mode while on battery to reduce background activity and peak CPU use.")
        case .none:
            suggestions.append("Could not determine Low Power Mode from pmset output.")
        }

        if let displaySleep = powerSettings.displaySleepMinutes {
            if displaySleep == 0 {
                suggestions.append("Set display sleep on battery; it is currently disabled.")
            } else if displaySleep > 5 {
                suggestions.append("Lower display sleep on battery to 2-5 minutes if you want longer runtime.")
            } else {
                suggestions.append("Display sleep is already set to \(displaySleep) minute(s) on battery.")
            }
        }

        suggestions.append("Lower screen brightness and stop local VMs, browser video, builds, or sync-heavy apps when you need maximum battery life.")

        return suggestions
    }

    private static func highImpactSuggestion(for app: AppImpact, rules: SuggestionRules) -> String {
        let category = rules.matchingCategory(for: app)
        let template = category?.suggestion ?? rules.genericSuggestion
        return render(template: template, app: app)
    }

    private static func render(template: String, app: AppImpact) -> String {
        template
            .replacingOccurrences(of: "{app}", with: app.name)
            .replacingOccurrences(of: "{power}", with: String(format: "%.1f", app.relativePower))
            .replacingOccurrences(of: "{cpu}", with: String(format: "%.1f", app.cpuPercent))
    }

    private static func fallbackRules() -> SuggestionRules {
        SuggestionRules(
            schemaVersion: 1,
            highImpactThreshold: 20,
            genericSuggestion: "{app} is using high current impact (power {power}, CPU {cpu}%). Quit it, pause active work, or stop background tasks if you do not need it on battery.",
            categories: []
        )
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
