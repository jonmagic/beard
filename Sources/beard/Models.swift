import Foundation

struct BatteryStatus: Codable, Equatable {
    let powerSource: String
    let batteryID: String?
    let chargePercent: Int?
    let state: String?
    let timeRemaining: String?
}

struct PowerSettings: Codable, Equatable {
    let batteryPowerMode: Int?
    let lowPowerModeLikelyEnabled: Bool?
    let displaySleepMinutes: Int?
    let systemSleepMinutes: Int?
    let diskSleepMinutes: Int?
}

struct TopProcessMetric: Equatable {
    let pid: Int
    let command: String
    let cpuPercent: Double
    let relativePower: Double
}

struct AppImpact: Codable, Equatable {
    let name: String
    var category: String? = nil
    var categoryName: String? = nil
    let relativePower: Double
    let cpuPercent: Double
    let processCount: Int
    let pids: [Int]
    let processNames: [String]
}

struct ReportSample: Codable, Equatable {
    let usableSamples: Int
    let topPasses: Int
    let intervalSeconds: Int
}

struct BatteryReport: Codable, Equatable {
    let schemaVersion: Int
    let generatedAt: String
    let sample: ReportSample
    let battery: BatteryStatus
    let powerSettings: PowerSettings
    let apps: [AppImpact]
    let suggestions: [String]
    let limitations: [String]
}
