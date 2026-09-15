import Foundation

/// Role: Stringer. Contact is a Settings link. This product has no remote catalog.
enum CreelHarbor {
    static let site = URL(string: "https://withycreel-bag.pro") ?? URL(fileURLWithPath: "/")
    static let contact = URL(string: "https://withycreel-bag.pro/contact-us") ?? URL(fileURLWithPath: "/")
    static let userAgent = "Withycreel/1.0 (iOS; +https://withycreel-bag.pro)"
}

/// Role: Stringer. Typed transport failures. No Open Food Facts catalog is wired.
enum CreelWire: Error, Equatable, Sendable {
    case absent
    case bent
    case snapped
    case waved
    case stray
}

/// Role: Stringer. One HTTP exchange. Tests inject a script.
protocol CreelCarrying: Sendable {
    func carry(_ request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Stringer. 15 s timeout and the app User-Agent on every request.
struct CreelSession: CreelCarrying, Sendable {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = CreelHeaders.timeout
        configuration.timeoutIntervalForResource = CreelHeaders.timeout
        configuration.httpAdditionalHeaders = ["User-Agent": CreelHeaders.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func carry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

enum CreelHeaders {
    static let userAgent = CreelHarbor.userAgent
    static let timeout: TimeInterval = 15
    static let holdNanoseconds: UInt64 = 300_000_000
}

/// Role: Stringer. JSON number or numeric string. Missing stays nil.
struct CreelLooseFigure: Sendable, Equatable {
    var value: Double?
}

extension CreelLooseFigure: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Stringer. status 0 means absent. No required remote catalog.
enum CreelCatalog {
    static func accept(status: Int) throws {
        if status == 0 { throw CreelWire.absent }
    }
}

/// Role: Stringer. Owns the session. Decode DTO then map — never into domain types.
actor CreelClient {
    static let userAgent = CreelHeaders.userAgent

    private let carrier: any CreelCarrying
    private let holdNanoseconds: UInt64
    private var lookupToken: UUID?

    init(carrier: any CreelCarrying, holdNanoseconds: UInt64 = CreelHeaders.holdNanoseconds) {
        self.carrier = carrier
        self.holdNanoseconds = holdNanoseconds
    }

    init() {
        self.carrier = CreelSession()
        self.holdNanoseconds = CreelHeaders.holdNanoseconds
    }

    func pull<DTO: Decodable & Sendable>(_ type: DTO.Type, at url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await cargo(request(at: url), attempt: 0)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw CreelWire.waved
        } catch {
            throw CreelWire.bent
        }
    }

    func lookup<DTO: Decodable & Sendable>(_ type: DTO.Type, query: String, at url: URL) async throws -> DTO {
        let token = UUID()
        lookupToken = token
        if holdNanoseconds > 0 {
            try await Task.sleep(nanoseconds: holdNanoseconds)
        }
        try Task.checkCancellation()
        guard lookupToken == token else { throw CreelWire.waved }
        _ = query
        return try await pull(type, at: url)
    }

    private func request(at url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: CreelHeaders.timeout)
        request.setValue(CreelHeaders.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func cargo(_ request: URLRequest, attempt: Int) async throws -> Data {
        do {
            return try await fire(request)
        } catch let wire as CreelWire {
            throw wire
        } catch is CancellationError {
            throw CreelWire.waved
        } catch {
            if creelWaved(error) { throw CreelWire.waved }
            guard attempt == 0, creelTransient(error) else { throw CreelWire.snapped }
            return try await cargo(request, attempt: 1)
        }
    }

    private func fire(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.carry(request)
        guard let http = response as? HTTPURLResponse else {
            throw CreelWire.stray
        }
        if http.statusCode == 404 {
            throw CreelWire.absent
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw CreelWire.snapped
        }
        return data
    }
}

func creelTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

func creelWaved(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
