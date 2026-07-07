import Foundation

struct SuggestionRules: Codable, Equatable {
    let schemaVersion: Int
    var highImpactThreshold: Double
    var genericSuggestion: String
    var categories: [SuggestionCategoryRule]

    static let embeddedDefaultJSON = """
    {
      "schemaVersion": 1,
      "highImpactThreshold": 20,
      "genericSuggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Quit it, pause active work, or stop background tasks if you do not need it on battery.",
      "categories": [
        {
          "id": "security",
          "name": "Security tooling",
          "exactMatches": [
            "microsoft defender"
          ],
          "containsMatches": [
            "wdavdaemon",
            "defender",
            "endpointsecurity",
            "epsext",
            "crowdstrike",
            "falcon",
            "sentinelone",
            "jamfprotect"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Check for an active scan or update, but do not disable security tooling just to save battery."
        },
        {
          "id": "system-display",
          "name": "Display server",
          "exactMatches": [
            "windowserver"
          ],
          "containsMatches": [],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Lower brightness, disconnect extra displays, or close graphics-heavy windows."
        },
        {
          "id": "thermal-system",
          "name": "Thermal management",
          "exactMatches": [
            "kernel_task"
          ],
          "containsMatches": [],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Reduce heat or stop other high-CPU work so macOS can leave thermal management sooner."
        },
        {
          "id": "browser",
          "name": "Browser or web content",
          "exactMatches": [
            "arc",
            "brave",
            "firefox",
            "safari"
          ],
          "containsMatches": [
            "webkit",
            "safari",
            "chrome",
            "firefox",
            "brave",
            "microsoft edge"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Close or pause browser tabs, video, calls, or heavy web apps you do not need on battery."
        },
        {
          "id": "container-vm",
          "name": "Containers or virtual machines",
          "exactMatches": [],
          "containsMatches": [
            "orbstack",
            "docker",
            "colima",
            "podman",
            "qemu",
            "virtualbox",
            "vmware",
            "parallels"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Stop local containers or VMs you do not need on battery."
        },
        {
          "id": "ide-build",
          "name": "Developer tools or builds",
          "exactMatches": [
            "cmux",
            "copilot",
            "git",
            "go",
            "java",
            "node",
            "python",
            "ruby",
            "swift"
          ],
          "containsMatches": [
            "xcode",
            "visual studio code",
            "code - insiders",
            "clang",
            "npm",
            "bun",
            "gradle",
            "cargo",
            "rustc",
            "git-remote",
            "copilot",
            "cmux"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Pause builds, indexing, agent sessions, or background developer tasks you do not need on battery."
        },
        {
          "id": "chat-call",
          "name": "Chat or calls",
          "exactMatches": [
            "discord",
            "slack",
            "zoom"
          ],
          "containsMatches": [
            "slack",
            "zoom",
            "teams",
            "discord",
            "webex"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Leave calls, pause screen sharing, or quit chat helpers you do not need on battery."
        },
        {
          "id": "media",
          "name": "Media processing",
          "exactMatches": [],
          "containsMatches": [
            "mediaanalysisd",
            "photo",
            "vtdecoder",
            "quicktime",
            "music",
            "spotify",
            "youtube"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Pause media playback, video processing, or photo analysis until you are on power."
        },
        {
          "id": "sync-storage",
          "name": "Sync or storage",
          "exactMatches": [],
          "containsMatches": [
            "dropbox",
            "onedrive",
            "icloud",
            "bird",
            "cloudd",
            "fileprovider",
            "googledrive"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Pause sync-heavy work or let file syncing finish while plugged in."
        },
        {
          "id": "device-management",
          "name": "Device management",
          "exactMatches": [
            "jamf"
          ],
          "containsMatches": [
            "jamf"
          ],
          "suggestion": "{app} is using high current impact (power {power}, CPU {cpu}%). Check whether device management is installing updates or running inventory; do not disable required management tooling."
        }
      ]
    }
    """

    static func embeddedDefaults() throws -> SuggestionRules {
        try decode(Data(embeddedDefaultJSON.utf8), sourceDescription: "embedded defaults")
    }

    static func decode(_ data: Data, sourceDescription: String) throws -> SuggestionRules {
        do {
            let rules = try JSONDecoder().decode(SuggestionRules.self, from: data)
            try rules.validate(sourceDescription: sourceDescription)
            return rules
        } catch let error as BeardError {
            throw error
        } catch {
            throw BeardError.parse("could not parse suggestion rules from \(sourceDescription): \(error.localizedDescription)")
        }
    }

    func mergingOverlay(_ overlay: SuggestionRulesOverlay) -> SuggestionRules {
        var merged = self
        if let highImpactThreshold = overlay.highImpactThreshold {
            merged.highImpactThreshold = highImpactThreshold
        }
        if let genericSuggestion = overlay.genericSuggestion, !genericSuggestion.trimmed.isEmpty {
            merged.genericSuggestion = genericSuggestion
        }

        for category in overlay.categories ?? [] {
            if let index = merged.categories.firstIndex(where: { $0.id == category.id }) {
                merged.categories[index] = category
            } else {
                merged.categories.append(category)
            }
        }

        return merged
    }

    func matchingCategory(for app: AppImpact) -> SuggestionCategoryRule? {
        categories.first { $0.matches(app: app) }
    }

    fileprivate func validate(sourceDescription: String) throws {
        guard schemaVersion == 1 else {
            throw BeardError.parse("unsupported suggestion rules schema \(schemaVersion) in \(sourceDescription)")
        }
        guard highImpactThreshold >= 0 else {
            throw BeardError.parse("suggestion rules threshold must be non-negative in \(sourceDescription)")
        }
        guard !genericSuggestion.trimmed.isEmpty else {
            throw BeardError.parse("suggestion rules genericSuggestion is empty in \(sourceDescription)")
        }

        var seenIDs = Set<String>()
        for category in categories {
            try category.validate(sourceDescription: sourceDescription)
            guard seenIDs.insert(category.id).inserted else {
                throw BeardError.parse("duplicate suggestion category id \(category.id) in \(sourceDescription)")
            }
        }
    }
}

struct SuggestionRulesOverlay: Decodable, Equatable {
    let schemaVersion: Int
    let highImpactThreshold: Double?
    let genericSuggestion: String?
    let categories: [SuggestionCategoryRule]?

    static func decode(_ data: Data, sourceDescription: String) throws -> SuggestionRulesOverlay {
        do {
            let overlay = try JSONDecoder().decode(SuggestionRulesOverlay.self, from: data)
            try overlay.validate(sourceDescription: sourceDescription)
            return overlay
        } catch let error as BeardError {
            throw error
        } catch {
            throw BeardError.parse("could not parse suggestion rules from \(sourceDescription): \(error.localizedDescription)")
        }
    }

    private func validate(sourceDescription: String) throws {
        guard schemaVersion == 1 else {
            throw BeardError.parse("unsupported suggestion rules schema \(schemaVersion) in \(sourceDescription)")
        }
        if let highImpactThreshold, highImpactThreshold < 0 {
            throw BeardError.parse("suggestion rules threshold must be non-negative in \(sourceDescription)")
        }
        if let genericSuggestion, genericSuggestion.trimmed.isEmpty {
            throw BeardError.parse("suggestion rules genericSuggestion is empty in \(sourceDescription)")
        }

        var seenIDs = Set<String>()
        for category in categories ?? [] {
            try category.validate(sourceDescription: sourceDescription)
            guard seenIDs.insert(category.id).inserted else {
                throw BeardError.parse("duplicate suggestion category id \(category.id) in \(sourceDescription)")
            }
        }
    }
}

struct SuggestionCategoryRule: Codable, Equatable {
    let id: String
    let name: String
    let exactMatches: [String]
    let containsMatches: [String]
    let suggestion: String

    func matches(app: AppImpact) -> Bool {
        let targets = ([app.name] + app.processNames).map { $0.lowercased() }
        let exactTerms = exactMatches.map { $0.lowercased() }
        let containsTerms = containsMatches.map { $0.lowercased() }

        for target in targets {
            if exactTerms.contains(target) {
                return true
            }
            if containsTerms.contains(where: { target.contains($0) }) {
                return true
            }
        }

        return false
    }

    fileprivate func validate(sourceDescription: String) throws {
        guard !id.trimmed.isEmpty else {
            throw BeardError.parse("suggestion category id is empty in \(sourceDescription)")
        }
        guard !name.trimmed.isEmpty else {
            throw BeardError.parse("suggestion category \(id) name is empty in \(sourceDescription)")
        }
        guard !suggestion.trimmed.isEmpty else {
            throw BeardError.parse("suggestion category \(id) suggestion is empty in \(sourceDescription)")
        }
    }
}

enum SuggestionRuleLoader {
    static func load(explicitPath: String? = nil, environment: [String: String] = ProcessInfo.processInfo.environment) throws -> SuggestionRules {
        let defaults = try SuggestionRules.embeddedDefaults()

        if let explicitPath, !explicitPath.trimmed.isEmpty {
            return try defaults.mergingOverlay(loadFile(path: explicitPath, sourceKind: "explicit rules"))
        }

        if let environmentPath = environment["BEARD_RULES_PATH"], !environmentPath.trimmed.isEmpty {
            return try defaults.mergingOverlay(loadFile(path: environmentPath, sourceKind: "BEARD_RULES_PATH"))
        }

        let userConfigPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/beard/rules.json")
            .path

        if FileManager.default.fileExists(atPath: userConfigPath) {
            do {
                return try defaults.mergingOverlay(loadFile(path: userConfigPath, sourceKind: "user rules"))
            } catch {
                FileHandle.standardError.writeString("beard: warning: ignoring invalid rules at \(userConfigPath): \(error.localizedDescription)\n")
            }
        }

        return defaults
    }

    private static func loadFile(path: String, sourceKind: String) throws -> SuggestionRulesOverlay {
        let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        do {
            return try SuggestionRulesOverlay.decode(Data(contentsOf: url), sourceDescription: "\(sourceKind) \(url.path)")
        } catch let error as BeardError {
            throw error
        } catch {
            throw BeardError.runtime("could not read \(sourceKind) at \(url.path): \(error.localizedDescription)")
        }
    }
}

extension AppImpact {
    func categorized(by rule: SuggestionCategoryRule?) -> AppImpact {
        AppImpact(
            name: name,
            category: rule?.id,
            categoryName: rule?.name,
            relativePower: relativePower,
            cpuPercent: cpuPercent,
            processCount: processCount,
            pids: pids,
            processNames: processNames
        )
    }
}
