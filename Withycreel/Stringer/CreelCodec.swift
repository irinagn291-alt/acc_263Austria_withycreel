import Foundation

/// Role: Stringer. Preference keys. Snapshot is JSON Data under wyc.stringer.v1. Demo is Simulator-only.
enum CreelKey {
    static let snapshot = "wyc.stringer.v1"
    static let backup = "wyc.stringer.v1.backup"
    static let demo = "wyc.demo.v1"
}

/// Role: Stringer. Codable root. schemaVersion from 1. Remaining is never a stored field.
struct CreelLedger: Equatable, Sendable {
    var schemaVersion: Int
    var document: CreelDocument
}

/// Role: Stringer. schemaVersion switch and creel ↔ JSON mapping. UserDefaults never sees remaining.
enum CreelCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ ledger: CreelLedger) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(RootDocument.from(ledger))
    }

    static func decode(_ data: Data) throws -> CreelLedger {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(RootDocument.self, from: data).asLedger()
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func committed(from document: CreelDocument) -> CreelLedger {
        var next = document
        next.schemaVersion = currentSchema
        return CreelLedger(schemaVersion: currentSchema, document: next)
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootDocument: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var yard: String
    var openSpeciesID: UUID
    var openLengthCentimetres: Double
    var openWeightKilograms: Double
    var limits: [LimitDocument]
    var days: [DayDocument]

    static func from(_ ledger: CreelLedger) -> RootDocument {
        let document = ledger.document
        return RootDocument(
            schemaVersion: CreelCodec.currentSchema,
            onboardingComplete: document.onboardingComplete,
            yard: document.yard.rawValue,
            openSpeciesID: document.openClip.speciesID,
            openLengthCentimetres: document.openClip.lengthCentimetres,
            openWeightKilograms: document.openClip.weightKilograms,
            limits: document.limits.map(LimitDocument.init(limit:)),
            days: document.creels.keys.sorted().map { day in
                DayDocument.from(day: day, fish: document.creels[day] ?? [])
            }
        )
    }

    func asLedger() throws -> CreelLedger {
        guard let yard = CreelYard(rawValue: yard) else { throw CreelCodec.Failure.corrupt }
        guard openLengthCentimetres.isFinite, openLengthCentimetres > 0 else {
            throw CreelCodec.Failure.corrupt
        }
        guard openWeightKilograms.isFinite, openWeightKilograms > 0 else {
            throw CreelCodec.Failure.corrupt
        }
        let mappedLimits = try limits.map { try $0.asLimit() }
        var creels: [CensusDay: [Fish]] = [:]
        for day in days {
            let folded = try day.asFish()
            creels[CensusDay(rawValue: day.day)] = folded
        }
        return CreelLedger(
            schemaVersion: schemaVersion,
            document: CreelDocument(
                schemaVersion: schemaVersion,
                onboardingComplete: onboardingComplete,
                yard: yard,
                openClip: OpenClip(
                    speciesID: openSpeciesID,
                    lengthCentimetres: openLengthCentimetres,
                    weightKilograms: openWeightKilograms
                ),
                limits: mappedLimits,
                creels: creels
            )
        )
    }
}

private struct LimitDocument: Codable {
    var id: UUID
    var name: String
    var dailyBag: Int
    var seasonBag: Int

    init(limit: SpeciesLimit) {
        id = limit.id
        name = limit.name
        dailyBag = limit.dailyBag
        seasonBag = limit.seasonBag
    }

    func asLimit() throws -> SpeciesLimit {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, dailyBag >= 0, seasonBag >= 0 else {
            throw CreelCodec.Failure.corrupt
        }
        return SpeciesLimit(id: id, name: trimmed, dailyBag: dailyBag, seasonBag: seasonBag)
    }
}

private struct DayDocument: Codable {
    var day: Int
    var fish: [FishDocument]
    var keepMarks: [KeepMarkDocument]
    var overs: [OverDocument]

    static func from(day: CensusDay, fish: [Fish]) -> DayDocument {
        DayDocument(
            day: day.rawValue,
            fish: fish.map(FishDocument.init(fish:)),
            keepMarks: fish.compactMap(\.keepMark).map(KeepMarkDocument.init(mark:)),
            overs: fish.compactMap(\.overhang).map(OverDocument.init(over:))
        )
    }

    func asFish() throws -> [Fish] {
        let marks = Dictionary(keepMarks.map { ($0.fishID, $0) }, uniquingKeysWith: { _, last in last })
        let hangs = Dictionary(overs.map { ($0.fishID, $0) }, uniquingKeysWith: { _, last in last })
        return try fish.map { row in
            try row.asFish(
                day: CensusDay(rawValue: day),
                mark: marks[row.id],
                over: hangs[row.id]
            )
        }
    }
}

private struct FishDocument: Codable {
    var id: UUID
    var speciesID: UUID
    var lengthCentimetres: Double
    var weightKilograms: Double

    init(fish: Fish) {
        id = fish.id
        speciesID = fish.speciesID
        lengthCentimetres = fish.lengthCentimetres
        weightKilograms = fish.weightKilograms
    }

    func asFish(day: CensusDay, mark: KeepMarkDocument?, over: OverDocument?) throws -> Fish {
        guard lengthCentimetres.isFinite, lengthCentimetres > 0 else {
            throw CreelCodec.Failure.corrupt
        }
        guard weightKilograms.isFinite, weightKilograms > 0 else {
            throw CreelCodec.Failure.corrupt
        }
        let keepMark = mark.map {
            KeepMark(id: $0.id, fishID: $0.fishID, speciesID: $0.speciesID, day: CensusDay(rawValue: $0.day))
        }
        let overhang = over.map {
            Over(
                fishID: $0.fishID,
                speciesID: $0.speciesID,
                day: CensusDay(rawValue: $0.day),
                seasonYear: $0.seasonYear
            )
        }
        if over != nil, keepMark == nil {
            throw CreelCodec.Failure.corrupt
        }
        return Fish(
            id: id,
            speciesID: speciesID,
            day: day,
            lengthCentimetres: lengthCentimetres,
            weightKilograms: weightKilograms,
            keepMark: keepMark,
            overhang: overhang
        )
    }
}

private struct KeepMarkDocument: Codable {
    var id: UUID
    var fishID: UUID
    var speciesID: UUID
    var day: Int

    init(mark: KeepMark) {
        id = mark.id
        fishID = mark.fishID
        speciesID = mark.speciesID
        day = mark.day.rawValue
    }
}

private struct OverDocument: Codable {
    var fishID: UUID
    var speciesID: UUID
    var day: Int
    var seasonYear: Int

    init(over: Over) {
        fishID = over.fishID
        speciesID = over.speciesID
        day = over.day.rawValue
        seasonYear = over.seasonYear
    }
}
