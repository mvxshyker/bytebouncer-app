import XCTest
@testable import ByteBouncer

// A mock URLProtocol to intercept network requests
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    var session: URLSession!

    let baseURL = "https://api.test.com"
    let appToken = "test-token"
    let deviceID = "test-device-id"

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        apiClient = APIClient(session: session, baseURL: baseURL, appToken: appToken)
    }

    override func tearDownWithError() throws {
        apiClient = nil
        session = nil
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - Auth Header Tests

    func testAppTokenHeaderIsPresent() async throws {
        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Token"), self.appToken)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        _ = try await apiClient.toggleServices(deviceID: deviceID, enabled: true)
    }

    func testUnauthorizedError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        do {
            _ = try await apiClient.toggleServices(deviceID: deviceID, enabled: true)
            XCTFail("Expected unauthorized error to be thrown")
        } catch APIError.unauthorized {
            // Success
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    // MARK: - Onboard

    func testOnboard() async throws {
        let expected = OnboardResponse(dohURL: "https://dns.nextdns.io/abc123")
        let responseBody = try JSONEncoder().encode(expected)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/onboard")
            XCTAssertEqual(request.httpMethod, "POST")

            if let data = request.httpBody ?? request.httpBodyStream?.readData(),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                XCTAssertEqual(json["device_id"], self.deviceID)
            } else {
                XCTFail("Expected HTTP body with device_id")
            }

            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        let result = try await apiClient.onboard(deviceID: deviceID)
        XCTAssertEqual(result.dohURL, "https://dns.nextdns.io/abc123")
    }

    // MARK: - Analytics

    func testFetchAnalytics() async throws {
        let expected = AnalyticsResponse(
            totalBlocked: 1500,
            topDomains: [BlockedDomain(name: "ads.example.com", queries: 340)]
        )
        let responseBody = try JSONEncoder().encode(expected)

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("/api/analytics") ?? false)
            XCTAssertTrue(request.url?.absoluteString.contains("device_id=\(self.deviceID)") ?? false)
            XCTAssertEqual(request.httpMethod, "GET")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        let result = try await apiClient.fetchAnalytics(deviceID: deviceID)
        XCTAssertEqual(result.totalBlocked, 1500)
        XCTAssertEqual(result.topDomains.count, 1)
        XCTAssertEqual(result.topDomains.first?.name, "ads.example.com")
    }

    // MARK: - Settings Toggles

    func testToggleServices() async throws {
        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/settings/services")
            XCTAssertEqual(request.httpMethod, "PATCH")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        let result = try await apiClient.toggleServices(deviceID: deviceID, enabled: true)
        XCTAssertTrue(result.ok)
    }

    func testToggleNatives() async throws {
        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/settings/natives")
            XCTAssertEqual(request.httpMethod, "PATCH")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        let result = try await apiClient.toggleNatives(deviceID: deviceID, enabled: true)
        XCTAssertTrue(result.ok)
    }

    func testToggleBlocklists() async throws {
        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/settings/blocklists")
            XCTAssertEqual(request.httpMethod, "PATCH")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        let result = try await apiClient.toggleBlocklists(deviceID: deviceID, enabled: false)
        XCTAssertTrue(result.ok)
    }

    func testBadStatusCodeError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        do {
            _ = try await apiClient.toggleServices(deviceID: deviceID, enabled: true)
            XCTFail("Expected bad status code error")
        } catch APIError.badStatusCode(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// Helper extension to read data from InputStream for HTTPBodyStream
extension InputStream {
    func readData() -> Data {
        var data = Data()
        self.open()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while self.hasBytesAvailable {
            let read = self.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        buffer.deallocate()
        self.close()
        return data
    }
}
