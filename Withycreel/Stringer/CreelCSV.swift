import Foundation

/// Role: Stringer. Local CSV from the same creel document. No remote catalog.
enum CreelCSV {
    static func sheet(from document: CreelDocument) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        formatter.usesGroupingSeparator = false

        var lines = ["day,species,role,length_cm,weight_kg"]
        let names = Dictionary(document.limits.map { ($0.id, $0.name) }, uniquingKeysWith: { _, last in last })
        let days = document.creels.keys.sorted()
        for day in days {
            for fish in document.fish(on: day) {
                let role: String
                if fish.hangsOver {
                    role = "over"
                } else if fish.isKept {
                    role = "kept"
                } else {
                    role = "released"
                }
                let species = escaped(names[fish.speciesID] ?? "")
                let length = formatter.string(from: NSNumber(value: fish.lengthCentimetres)) ?? "0"
                let weight = formatter.string(from: NSNumber(value: fish.weightKilograms)) ?? "0"
                lines.append("\(day.rawValue),\(species),\(role),\(length),\(weight)")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func writeAtomically(_ sheet: String, to url: URL, fileManager: FileManager) throws {
        let parent = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        let data = Data(sheet.utf8)
        try data.write(to: url, options: .atomic)
    }

    private static func escaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
