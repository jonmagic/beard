import Testing
@testable import beard

@Test func parsesBatteryStatus() throws {
    let output = """
    Now drawing from 'Battery Power'
     -InternalBattery-0 (id=35324003)\t87%; discharging; 4:06 remaining present: true
    """

    let battery = try Parsers.parseBatteryStatus(output)

    #expect(battery.powerSource == "Battery Power")
    #expect(battery.batteryID == "35324003")
    #expect(battery.chargePercent == 87)
    #expect(battery.state == "discharging")
    #expect(battery.timeRemaining == "4:06")
}

@Test func parsesBatteryPowerSettings() {
    let output = """
    Battery Power:
     Sleep On Power Button 1
     powermode            1
     displaysleep         2
     sleep                1
     disksleep            10
    AC Power:
     powermode            0
     displaysleep         0
    """

    let settings = Parsers.parsePowerSettings(output)

    #expect(settings.batteryPowerMode == 1)
    #expect(settings.lowPowerModeLikelyEnabled == true)
    #expect(settings.displaySleepMinutes == 2)
    #expect(settings.systemSleepMinutes == 1)
    #expect(settings.diskSleepMinutes == 10)
}

@Test func parsesOnlyLastTopSample() throws {
    let output = """
    Processes: 1004 total
    PID    COMMAND          %CPU POWER
    99949  com.apple.WebKit 0.0  0.0
    99230  OrbStack         0.0  0.0
    Processes: 1009 total
    PID    COMMAND          %CPU POWER
    51482  Code - Insiders  50.8 50.8
    23521  Slack Helper (Re 30.6 30.6
    """

    let processes = try Parsers.parseTopProcesses(output)

    #expect(processes.count == 2)
    #expect(processes[0] == TopProcessMetric(pid: 51482, command: "Code - Insiders", cpuPercent: 50.8, relativePower: 50.8))
    #expect(processes[1] == TopProcessMetric(pid: 23521, command: "Slack Helper (Re", cpuPercent: 30.6, relativePower: 30.6))
}

@Test func parsesAllTopSamplesForAveraging() throws {
    let output = """
    Processes: 1004 total
    PID    COMMAND          %CPU POWER
    99949  com.apple.WebKit 0.0  0.0
    Processes: 1009 total
    PID    COMMAND          %CPU POWER
    51482  Code - Insiders  50.0 50.0
    Processes: 1010 total
    PID    COMMAND          %CPU POWER
    51482  Code - Insiders  30.0 34.0
    23521  Slack Helper (Re 20.0 22.0
    """

    let samples = try Parsers.parseTopProcessSamples(output)
    let averages = ImpactAggregator.average(topSamples: Array(samples.dropFirst()))

    #expect(samples.count == 3)
    #expect(averages.first == TopProcessMetric(pid: 51482, command: "Code - Insiders", cpuPercent: 40.0, relativePower: 42.0))
    #expect(averages.count == 2)
}

@Test func parsesProcessCommands() {
    let output = """
      209 /Applications/OrbStack.app/Contents/Frameworks/OrbStack Helper.app/Contents/MacOS/OrbStack Helper ssh-proxy
    51482 /Applications/Visual Studio Code - Insiders.app/Contents/MacOS/Electron
      600 /System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer
    """

    let commands = Parsers.parseProcessCommands(output)

    #expect(commands[209]?.contains("OrbStack.app") == true)
    #expect(commands[51482]?.contains("Visual Studio Code - Insiders.app") == true)
    #expect(commands[600]?.contains("WindowServer") == true)
}

@Test func aggregatesByResponsibleAppName() {
    let topProcesses = [
        TopProcessMetric(pid: 1, command: "Code - Insiders", cpuPercent: 10, relativePower: 11),
        TopProcessMetric(pid: 2, command: "Code Helper", cpuPercent: 20, relativePower: 21),
        TopProcessMetric(pid: 3, command: "WindowServer", cpuPercent: 5, relativePower: 6),
    ]
    let commands = [
        1: "/Applications/Visual Studio Code - Insiders.app/Contents/MacOS/Electron",
        2: "/Applications/Visual Studio Code - Insiders.app/Contents/Frameworks/Code Helper.app/Contents/MacOS/Code Helper",
        3: "/System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer",
    ]

    let apps = ImpactAggregator.aggregate(topProcesses: topProcesses, processCommands: commands, limit: 8)

    #expect(apps.first?.name == "Visual Studio Code - Insiders")
    #expect(apps.first?.relativePower == 32)
    #expect(apps.first?.cpuPercent == 30)
    #expect(apps.first?.processCount == 2)
}

@Test func cleansParenthesizedProcessDisplayNames() {
    let apps = ImpactAggregator.aggregate(
        topProcesses: [
            TopProcessMetric(pid: 123, command: "git", cpuPercent: 40, relativePower: 40),
        ],
        processCommands: [
            123: "(git)",
        ],
        limit: 8
    )

    #expect(apps.first?.name == "git")
}

@Test func parsesCLIOptions() throws {
    let request = try CLI.parse(arguments: ["report", "--json", "--samples", "3", "--interval=2", "--limit", "5"])

    #expect(request == .report(ReportOptions(outputJSON: true, samples: 3, intervalSeconds: 2, limit: 5)))
}

@Test func parsesVersionOption() throws {
    #expect(try CLI.parse(arguments: ["--version"]) == .version)
    let versionFile = try String(contentsOfFile: "VERSION", encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(BeardVersion.current == versionFile)
}

@Test func doesNotRecommendDisablingSecurityTooling() {
    let suggestions = SuggestionEngine.suggestions(
        battery: BatteryStatus(powerSource: "Battery Power", batteryID: nil, chargePercent: 80, state: "discharging", timeRemaining: "4:00"),
        powerSettings: PowerSettings(batteryPowerMode: 1, lowPowerModeLikelyEnabled: true, displaySleepMinutes: 2, systemSleepMinutes: 1, diskSleepMinutes: 10),
        apps: [
            AppImpact(
                name: "Microsoft Defender",
                relativePower: 80,
                cpuPercent: 80,
                processCount: 1,
                pids: [809],
                processNames: ["wdavdaemon"]
            ),
        ]
    )

    #expect(suggestions.contains { $0.contains("do not disable security tooling") })
    #expect(!suggestions.contains { $0.contains("Quit it") })
}
