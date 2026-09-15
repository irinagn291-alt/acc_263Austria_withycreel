import XCTest
@testable import Withycreel

private struct ProbeDTO: Decodable, Sendable {
    var status: Int?
    var span: CreelLooseFigure?
}

private actor ScriptedCarrier: CreelCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func carry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class CreelClientTests: XCTestCase {
    private let url = URL(string: "https://withycreel-bag.pro/probe") ?? URL(fileURLWithPath: "/")

    func test_setsUserAgentOnEveryRequest() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"span\":1}".utf8), http(200))),
        ])
        let client = CreelClient(carrier: carrier, holdNanoseconds: 0)
        _ = try await client.pull(ProbeDTO.self, at: url)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), CreelClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(CreelClient.userAgent, "Withycreel/1.0 (iOS; +https://withycreel-bag.pro)")
        XCTAssertEqual(CreelHarbor.contact.absoluteString, "https://withycreel-bag.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"span\":\"4.5\"}".utf8), http(200))),
        ])
        let client = CreelClient(carrier: carrier, holdNanoseconds: 0)
        let dto = try await client.pull(ProbeDTO.self, at: url)
        XCTAssertEqual(dto.span?.value, 4.5)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), http(404))),
            .success((Data("{\"span\":1}".utf8), http(200))),
        ])
        let client = CreelClient(carrier: carrier, holdNanoseconds: 0)
        do {
            _ = try await client.pull(ProbeDTO.self, at: url)
            XCTFail("expected absent")
        } catch {
            XCTAssertEqual(error as? CreelWire, .absent)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsBent() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = CreelClient(carrier: carrier, holdNanoseconds: 0)
        do {
            _ = try await client.pull(ProbeDTO.self, at: url)
            XCTFail("expected bent")
        } catch {
            XCTAssertEqual(error as? CreelWire, .bent)
        }
    }

    func test_looseFigureAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"span\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"span\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"span\":null}".utf8))
        XCTAssertEqual(number.span?.value, 12.5)
        XCTAssertEqual(string.span?.value, 12.5)
        XCTAssertNil(missing.span?.value)
    }

    func test_statusZeroIsAbsent() throws {
        XCTAssertThrowsError(try CreelCatalog.accept(status: 0)) { error in
            XCTAssertEqual(error as? CreelWire, .absent)
        }
        XCTAssertNoThrow(try CreelCatalog.accept(status: 1))
    }

    func test_lookupCancelsPriorQuery() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"span\":2}".utf8), http(200))),
        ])
        let client = CreelClient(carrier: carrier, holdNanoseconds: 80_000_000)
        let endpoint = url
        async let first: ProbeDTO = client.lookup(ProbeDTO.self, query: "one", at: endpoint)
        try await Task.sleep(nanoseconds: 10_000_000)
        async let second: ProbeDTO = client.lookup(ProbeDTO.self, query: "two", at: endpoint)
        var firstFailed = false
        do {
            _ = try await first
            XCTFail("expected waved")
        } catch {
            XCTAssertEqual(error as? CreelWire, .waved)
            firstFailed = true
        }
        let dto = try await second
        XCTAssertTrue(firstFailed)
        XCTAssertEqual(dto.span?.value, 2)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)
            ?? HTTPURLResponse()
    }
}
