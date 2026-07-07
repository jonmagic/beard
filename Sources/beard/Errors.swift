import Foundation

enum BeardError: LocalizedError, Equatable {
    case usage(String)
    case parse(String)
    case runtime(String)

    var errorDescription: String? {
        switch self {
        case .usage(let message), .parse(let message), .runtime(let message):
            return message
        }
    }
}
