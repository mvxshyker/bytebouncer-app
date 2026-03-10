import XCTest
@testable import ByteBouncer

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var viewModel: DashboardViewModel!
    var session: URLSession!
    var networkManager: NextDNSNetworkManager!
    var userDefaults: UserDefaults!
    
    let profileID = "testProfileID"
    let apiKey = "testApiKey"
    
    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        
        networkManager = NextDNSNetworkManager(session: session, profileID: profileID, apiKey: apiKey)
        
        userDefaults = UserDefaults(suiteName: "TestDefaults")
        userDefaults?.removePersistentDomain(forName: "TestDefaults")
        
        viewModel = DashboardViewModel(networkManager: networkManager, defaults: userDefaults!)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        networkManager = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        userDefaults?.removePersistentDomain(forName: "TestDefaults")
        userDefaults = nil
    }
    
    func testToggleSocialMediaBlocked_EnablesService() async throws {
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/parentalcontrol/services")
            XCTAssertEqual(request.httpMethod, "POST")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        await viewModel.toggleSocialMedia(blocked: true)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isSocialMediaBlocked)
        XCTAssertTrue(userDefaults.bool(forKey: "isSocialMediaBlocked"))
    }
    
    func testToggleSocialMediaBlocked_DisablesService() async throws {
        userDefaults.set(true, forKey: "isSocialMediaBlocked")
        viewModel = DashboardViewModel(networkManager: networkManager, defaults: userDefaults!)
        XCTAssertTrue(viewModel.isSocialMediaBlocked)
        
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/parentalcontrol/services/instagram")
            XCTAssertEqual(request.httpMethod, "DELETE")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        await viewModel.toggleSocialMedia(blocked: false)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isSocialMediaBlocked)
        XCTAssertFalse(userDefaults.bool(forKey: "isSocialMediaBlocked"))
    }
    
    func testToggleAnalyticsBlocked_EnablesService() async throws {
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/privacy/natives")
            XCTAssertEqual(request.httpMethod, "POST")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        await viewModel.toggleAnalytics(blocked: true)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isAnalyticsBlocked)
        XCTAssertTrue(userDefaults.bool(forKey: "isAnalyticsBlocked"))
    }
    
    func testToggleAdvertisingBlocked_EnablesService() async throws {
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.nextdns.io/profiles/\(self.profileID)/privacy/blocklists")
            XCTAssertEqual(request.httpMethod, "POST")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        await viewModel.toggleAdvertising(blocked: true)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isAdvertisingBlocked)
        XCTAssertTrue(userDefaults.bool(forKey: "isAdvertisingBlocked"))
    }
    
    func testStateFixingOnNetworkFailure() async throws {
        XCTAssertFalse(viewModel.isSocialMediaBlocked)
        
        let expectation = XCTestExpectation(description: "Network request made but failed")
        MockURLProtocol.requestHandler = { request in
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        await viewModel.toggleSocialMedia(blocked: true)
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Assert state remains false because network failed
        XCTAssertFalse(viewModel.isSocialMediaBlocked)
        XCTAssertFalse(userDefaults.bool(forKey: "isSocialMediaBlocked"))
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
