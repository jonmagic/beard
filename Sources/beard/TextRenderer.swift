import Foundation

enum TextRenderer {
    static func render(_ report: BatteryReport) -> String {
        var lines: [String] = []

        lines.append("Beard battery report")
        lines.append("")
        lines.append("Battery: \(batterySummary(report.battery))")
        lines.append("Low Power Mode: \(lowPowerModeSummary(report.powerSettings.lowPowerModeLikelyEnabled))")

        if let displaySleep = report.powerSettings.displaySleepMinutes {
            lines.append("Display sleep on battery: \(displaySleep == 0 ? "disabled" : "\(displaySleep) min")")
        }

        lines.append("Sample: \(report.sample.usableSamples) usable top sample(s), \(report.sample.intervalSeconds)s interval")
        lines.append("Scores: relative current impact, often CPU-derived; not watts or watt-hours")
        lines.append("")
        lines.append("Top app/process impact:")

        if report.apps.isEmpty {
            lines.append("  No active app/process impact found in this sample.")
        } else {
            for (index, app) in report.apps.enumerated() {
                let paddedName = app.name.count < 28 ? app.name.padding(toLength: 28, withPad: " ", startingAt: 0) : app.name
                let pidList = app.pids.map(String.init).joined(separator: ",")
                lines.append(String(format: "  %2d. %@ power %6.1f  cpu %6.1f%%  pids %@", index + 1, paddedName, app.relativePower, app.cpuPercent, pidList))
            }
        }

        lines.append("")
        lines.append("Suggestions:")
        for suggestion in report.suggestions {
            lines.append("  - \(suggestion)")
        }

        lines.append("")
        lines.append("Limitations:")
        for limitation in report.limitations {
            lines.append("  - \(limitation)")
        }

        return lines.joined(separator: "\n")
    }

    private static func batterySummary(_ battery: BatteryStatus) -> String {
        var parts: [String] = []
        if let charge = battery.chargePercent {
            parts.append("\(charge)%")
        }
        if let state = battery.state {
            parts.append(state)
        }
        if let remaining = battery.timeRemaining {
            parts.append("\(remaining) remaining")
        }
        parts.append("source: \(battery.powerSource)")
        return parts.joined(separator: ", ")
    }

    private static func lowPowerModeSummary(_ enabled: Bool?) -> String {
        switch enabled {
        case .some(true):
            return "on"
        case .some(false):
            return "off"
        case .none:
            return "unknown"
        }
    }
}
