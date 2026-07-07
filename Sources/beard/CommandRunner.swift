import Foundation

protocol CommandRunning {
    func run(_ executablePath: String, arguments: [String]) throws -> String
}

struct ProcessCommandRunner: CommandRunning {
    func run(_ executablePath: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
        } catch {
            throw BeardError.runtime("failed to start \(executablePath): \(error.localizedDescription)")
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: outputData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            throw BeardError.runtime("\(executablePath) exited with status \(process.terminationStatus)\(detail.isEmpty ? "" : ": \(detail)")")
        }

        return output
    }
}

extension FileHandle {
    func writeString(_ value: String) {
        if let data = value.data(using: .utf8) {
            write(data)
        }
    }
}
