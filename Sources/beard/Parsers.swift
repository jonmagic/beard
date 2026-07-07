import Foundation

enum Parsers {
    static func parseBatteryStatus(_ output: String) throws -> BatteryStatus {
        let lines = output.lines
        let powerSource = lines
            .compactMap { line -> String? in
                guard let start = line.range(of: "'"), let end = line[start.upperBound...].range(of: "'") else {
                    return nil
                }
                return String(line[start.upperBound..<end.lowerBound])
            }
            .first ?? "Unknown"

        guard let batteryLine = lines.first(where: { $0.contains("%;") }) else {
            return BatteryStatus(
                powerSource: powerSource,
                batteryID: nil,
                chargePercent: nil,
                state: nil,
                timeRemaining: nil
            )
        }

        let batteryID = batteryLine.slice(between: "(id=", and: ")")
        let chargePercent = batteryLine
            .slice(before: "%")
            .flatMap { prefix -> Int? in
                let digits = prefix.reversed().prefix(while: \.isNumber).reversed()
                return Int(String(digits))
            }

        let segments = batteryLine
            .split(separator: ";")
            .map { String($0).trimmed }

        let state = segments.count > 1 ? segments[1] : nil
        let timeRemaining = segments
            .dropFirst(2)
            .first(where: { $0.contains("remaining") })
            .map { segment in
                segment.replacingOccurrences(of: " remaining present: true", with: "")
                    .replacingOccurrences(of: " remaining present: false", with: "")
                    .replacingOccurrences(of: " remaining", with: "")
                    .trimmed
            }

        return BatteryStatus(
            powerSource: powerSource,
            batteryID: batteryID,
            chargePercent: chargePercent,
            state: state,
            timeRemaining: timeRemaining
        )
    }

    static func parsePowerSettings(_ output: String) -> PowerSettings {
        var inBatterySection = false
        var values: [String: Int] = [:]

        for line in output.lines {
            let trimmed = line.trimmed
            if trimmed == "Battery Power:" {
                inBatterySection = true
                continue
            }
            if trimmed == "AC Power:" {
                inBatterySection = false
                continue
            }
            guard inBatterySection else {
                continue
            }

            let parts = trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard parts.count >= 2, let value = Int(parts[1]) else {
                continue
            }
            values[String(parts[0])] = value
        }

        let powerMode = values["powermode"]

        return PowerSettings(
            batteryPowerMode: powerMode,
            lowPowerModeLikelyEnabled: powerMode.map { $0 == 1 },
            displaySleepMinutes: values["displaysleep"],
            systemSleepMinutes: values["sleep"],
            diskSleepMinutes: values["disksleep"]
        )
    }

    static func parseTopProcesses(_ output: String) throws -> [TopProcessMetric] {
        guard let lastSample = try parseTopProcessSamples(output).last else {
            throw BeardError.parse("could not find a top process table in output")
        }
        return lastSample
    }

    static func parseTopProcessSamples(_ output: String) throws -> [[TopProcessMetric]] {
        let lines = output.lines
        var samples: [[TopProcessMetric]] = []
        var currentSample: [TopProcessMetric]?

        for line in lines {
            let trimmed = line.trimmed

            if isTopHeader(trimmed) {
                if let sample = currentSample, !sample.isEmpty {
                    samples.append(sample)
                }
                currentSample = []
                continue
            }

            guard currentSample != nil else {
                continue
            }

            if trimmed.isEmpty || trimmed.hasPrefix("Processes:") {
                if let sample = currentSample, !sample.isEmpty {
                    samples.append(sample)
                }
                currentSample = nil
                continue
            }

            if let metric = parseTopProcessLine(trimmed) {
                currentSample?.append(metric)
            }
        }

        if let sample = currentSample, !sample.isEmpty {
            samples.append(sample)
        }

        guard !samples.isEmpty else {
            throw BeardError.parse("could not find a top process table in output")
        }

        return samples
    }

    private static func isTopHeader(_ line: String) -> Bool {
        line.hasPrefix("PID") && line.contains("COMMAND") && line.contains("%CPU") && line.contains("POWER")
    }

    private static func parseTopProcessLine(_ line: String) -> TopProcessMetric? {
        let tokens = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
        guard tokens.count >= 4,
              let pid = Int(tokens[0]),
              let cpuPercent = Double(tokens[tokens.count - 2]),
              let relativePower = Double(tokens[tokens.count - 1]) else {
            return nil
        }

        let command = tokens[1..<(tokens.count - 2)].joined(separator: " ")
        return TopProcessMetric(
            pid: pid,
            command: command,
            cpuPercent: cpuPercent,
            relativePower: relativePower
        )
    }

    static func parseProcessCommands(_ output: String) -> [Int: String] {
        var commands: [Int: String] = [:]

        for line in output.lines {
            let parts = line.trimmed.split(maxSplits: 1, whereSeparator: { $0 == " " || $0 == "\t" })
            guard parts.count == 2, let pid = Int(parts[0]) else {
                continue
            }
            commands[pid] = String(parts[1])
        }

        return commands
    }
}

extension String {
    var lines: [String] {
        split(whereSeparator: \.isNewline).map(String.init)
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func slice(before marker: String) -> String? {
        guard let range = range(of: marker) else {
            return nil
        }
        return String(self[..<range.lowerBound])
    }

    func slice(between start: String, and end: String) -> String? {
        guard let startRange = range(of: start),
              let endRange = self[startRange.upperBound...].range(of: end) else {
            return nil
        }
        return String(self[startRange.upperBound..<endRange.lowerBound])
    }
}
