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

final class NextDNSNetworkManagerTests: XCTestCase {
    var networkManager: NextDNSNetworkManager!
    var session: URLSession!
    
    let profileID = "testProfileID"
    let apiKey = "testApiKey"

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        networkManager = NextDNSNetworkManager(session: session, profileID: profileID, apiKey: apiKey)
    }

    override func tearDownWithError() throws {
        networkManager = nil
        session = nil
        MockURLProtocol.requestHandler = nil
    }

    // MARK: - API Key Validation Tests
    func testAPIKeyHeaderIsPresent() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Api-Key"), self.apiKey)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        _ = try await networkManager.toggleService(serviceId: "instagram", enabled: true)
    }
    
    // MARK: - Unauthorized Test
    func testUnauthorizedError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        do {
            _ = try await networkManager.toggleService(serviceId: "instagram", enabled: true)
            XCTFail("Expected unauthorized error to be thrown")
        } catch NextDNSError.unauthorized {
            // Success
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    // MARK: - Social Media Prefetch (Parental Controls)
    func testEnableSocialMediaBlock() async throws {
        let serviceId = "instagram"
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/parentalcontrol/services")
            XCTAssertEqual(request.httpMethod, "POST")
            
            // Validate body
            if let data = request.httpBody ?? request.httpBodyStream?.readData(),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                XCTAssertEqual(json["id"], serviceId)
            } else {
                XCTFail("Expected HTTP body")
            }
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        try await networkManager.toggleService(serviceId: serviceId, enabled: true)
    }
    
    func testDisableSocialMediaBlock() async throws {
        let serviceId = "instagram"
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/parentalcontrol/services/\(serviceId)")
            XCTAssertEqual(request.httpMethod, "DELETE")
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        try await networkManager.toggleService(serviceId: serviceId, enabled: false)
    }

    // MARK: - Analytics & Crash Reports (Native Tracking Protection)
    func testEnableNativeTrackingBlock() async throws {
        let nativeId = "apple"
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/privacy/natives")
            XCTAssertEqual(request.httpMethod, "POST")
            
            if let data = request.httpBody ?? request.httpBodyStream?.readData(),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                XCTAssertEqual(json["id"], nativeId)
            } else {
                XCTFail("Expected HTTP body")
            }
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        try await networkManager.toggleNativeTracking(nativeId: nativeId, enabled: true)
    }
    
    func testDisableNativeTrackingBlock() async throws {
        let nativeId = "apple"
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/privacy/natives/\(nativeId)")
            XCTAssertEqual(request.httpMethod, "DELETE")
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        try await networkManager.toggleNativeTracking(nativeId: nativeId, enabled: false)
    }

    // MARK: - Advertising Networks (Blocklists)
    func testEnableAdGuardBlocklist() async throws {
        let blocklistId = "adguard"
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/privacy/blocklists")
            XCTAssertEqual(request.httpMethod, "POST")
            
            if let data = request.httpBody ?? request.httpBodyStream?.readData(),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                XCTAssertEqual(json["id"], blocklistId)
            } else {
                XCTFail("Expected HTTP body")
            }
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        try await networkManager.toggleBlocklist(blocklistId: blocklistId, enabled: true)
    }
    
    func testDisableAdGuardBlocklist() async throws {
        let blocklistId = "adguard"
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/privacy/blocklists/\(blocklistId)")
            XCTAssertEqual(request.httpMethod, "DELETE")
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        try await networkManager.toggleBlocklist(blocklistId: blocklistId, enabled: false)
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
