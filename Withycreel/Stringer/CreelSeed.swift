import Foundation

/// Role: Stringer. Simulator demo stringer. Device never writes this. Key: wyc.demo.v1.
enum CreelSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func document(now: Date = Date(), calendar: Calendar = .current) throws -> CreelDocument {
        let today = CensusDay.from(now, calendar: calendar)
        let yesterday = today.adding(days: -1, calendar: calendar)
        var next = CreelDocument.empty.completingOnboarding()
        next.yard = .metric
        next.openClip = OpenClip(
            speciesID: CensusStock.perchID,
            lengthCentimetres: 31,
            weightKilograms: 0.55
        )

        let yesterdayKeeps: [(UUID, Double, Double, String)] = [
            (CensusStock.breamID, 34, 1.1, "B2222222-0000-4000-8000-000000000001"),
            (CensusStock.tenchID, 36, 1.4, "B2222222-0000-4000-8000-000000000002"),
        ]
        for row in yesterdayKeeps {
            let filing = try next.keep(
                OpenClip(speciesID: row.0, lengthCentimetres: row.1, weightKilograms: row.2),
                on: yesterday,
                fishID: fixed(row.3),
                markID: fixed("C3333333-0000-4000-8000-\(row.3.suffix(12))")
            )
            next = filing.0
        }

        let todayKeeps: [(UUID, Double, Double, String)] = [
            (CensusStock.perchID, 29, 0.48, "B2222222-0000-4000-8000-000000000003"),
            (CensusStock.perchID, 32, 0.61, "B2222222-0000-4000-8000-000000000004"),
            (CensusStock.pikeID, 62, 2.4, "B2222222-0000-4000-8000-000000000005"),
            (CensusStock.breamID, 38, 1.35, "B2222222-0000-4000-8000-000000000006"),
        ]
        for row in todayKeeps {
            let filing = try next.keep(
                OpenClip(speciesID: row.0, lengthCentimetres: row.1, weightKilograms: row.2),
                on: today,
                fishID: fixed(row.3),
                markID: fixed("C3333333-0000-4000-8000-\(row.3.suffix(12))")
            )
            next = filing.0
            guard filing.1 == nil else { throw CreelFault.invalidLimit }
        }

        let released = try next.release(
            OpenClip(speciesID: CensusStock.tenchID, lengthCentimetres: 27, weightKilograms: 0.7),
            on: today,
            fishID: fixed("B2222222-0000-4000-8000-000000000007")
        )
        next = released.0
        next.openClip = OpenClip(
            speciesID: CensusStock.perchID,
            lengthCentimetres: 30,
            weightKilograms: 0.5
        )
        return next
    }
}
