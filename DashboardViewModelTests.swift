import XCTest
@testable import ByteBouncer

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var viewModel: DashboardViewModel!
    var session: URLSession!
    var apiClient: APIClient!
    var userDefaults: UserDefaults!

    let baseURL = "https://api.test.com"
    let appToken = "test-token"
    let deviceID = "test-device-id"

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)

        apiClient = APIClient(session: session, baseURL: baseURL, appToken: appToken)

        userDefaults = UserDefaults(suiteName: "TestDefaults")
        userDefaults?.removePersistentDomain(forName: "TestDefaults")

        viewModel = DashboardViewModel(apiClient: apiClient, deviceID: deviceID, defaults: userDefaults!)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        apiClient = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        userDefaults?.removePersistentDomain(forName: "TestDefaults")
        userDefaults = nil
    }

    // MARK: - Toggle Tests

    func testToggleSocialMediaBlocked_EnablesService() async throws {
        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/settings/services")
            XCTAssertEqual(request.httpMethod, "PATCH")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        await viewModel.toggleSocialMedia(blocked: true)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isSocialMediaBlocked)
        XCTAssertTrue(userDefaults.bool(forKey: "isSocialMediaBlocked"))
    }

    func testToggleSocialMediaBlocked_DisablesService() async throws {
        userDefaults.set(true, forKey: "isSocialMediaBlocked")
        viewModel = DashboardViewModel(apiClient: apiClient, deviceID: deviceID, defaults: userDefaults!)
        XCTAssertTrue(viewModel.isSocialMediaBlocked)

        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/settings/services")
            XCTAssertEqual(request.httpMethod, "PATCH")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        await viewModel.toggleSocialMedia(blocked: false)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isSocialMediaBlocked)
        XCTAssertFalse(userDefaults.bool(forKey: "isSocialMediaBlocked"))
    }

    func testToggleAnalyticsBlocked_EnablesService() async throws {
        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/settings/natives")
            XCTAssertEqual(request.httpMethod, "PATCH")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        await viewModel.toggleAnalytics(blocked: true)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isAnalyticsBlocked)
        XCTAssertTrue(userDefaults.bool(forKey: "isAnalyticsBlocked"))
    }

    func testToggleAdvertisingBlocked_EnablesService() async throws {
        let responseBody = try JSONEncoder().encode(SettingsResponse(ok: true))
        let expectation = XCTestExpectation(description: "Network request made")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "\(self.baseURL)/api/settings/blocklists")
            XCTAssertEqual(request.httpMethod, "PATCH")
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        await viewModel.toggleAdvertising(blocked: true)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isAdvertisingBlocked)
        XCTAssertTrue(userDefaults.bool(forKey: "isAdvertisingBlocked"))
    }

    func testStateRevertsOnNetworkFailure() async throws {
        XCTAssertFalse(viewModel.isSocialMediaBlocked)

        let expectation = XCTestExpectation(description: "Network request made but failed")
        MockURLProtocol.requestHandler = { request in
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        await viewModel.toggleSocialMedia(blocked: true)
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertFalse(viewModel.isSocialMediaBlocked)
        XCTAssertFalse(userDefaults.bool(forKey: "isSocialMediaBlocked"))
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Analytics Tests

    func testFetchAnalytics() async throws {
        let analyticsData = AnalyticsResponse(
            totalBlocked: 1500,
            topDomains: [BlockedDomain(name: "ads.example.com", queries: 340)]
        )
        let responseBody = try JSONEncoder().encode(analyticsData)

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("/api/analytics") ?? false)
            XCTAssertEqual(request.httpMethod, "GET")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        await viewModel.fetchAnalytics()

        XCTAssertEqual(viewModel.totalBlocked, 1500)
        XCTAssertEqual(viewModel.topDomains.count, 1)
        XCTAssertEqual(viewModel.topDomains.first?.name, "ads.example.com")
        XCTAssertFalse(viewModel.isLoadingAnalytics)
    }

    func testFetchAnalyticsHandlesEmptyData() async throws {
        let analyticsData = AnalyticsResponse(totalBlocked: 0, topDomains: [])
        let responseBody = try JSONEncoder().encode(analyticsData)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseBody)
        }

        await viewModel.fetchAnalytics()

        XCTAssertEqual(viewModel.totalBlocked, 0)
        XCTAssertTrue(viewModel.topDomains.isEmpty)
    }
}
