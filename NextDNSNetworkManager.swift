import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case networkError(Error)
    case invalidResponse
    case badStatusCode(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Unauthorized — check app token"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid server response"
        case .badStatusCode(let code): return "Server error (\(code))"
        case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        }
    }
}

// MARK: - Response Models

struct OnboardResponse: Codable {
    let dohURL: String

    enum CodingKeys: String, CodingKey {
        case dohURL = "doh_url"
    }
}

struct AnalyticsResponse: Codable {
    let totalBlocked: Int
    let topDomains: [BlockedDomain]

    enum CodingKeys: String, CodingKey {
        case totalBlocked = "total_blocked"
        case topDomains = "top_domains"
    }
}

struct BlockedDomain: Codable, Identifiable {
    let name: String
    let queries: Int

    var id: String { name }
}

struct SettingsResponse: Codable {
    let ok: Bool
}

// MARK: - API Client

class APIClient {
    private let session: URLSession
    private let baseURL: String
    private let appToken: String

    init(session: URLSession = .shared, baseURL: String, appToken: String) {
        self.session = session
        self.baseURL = baseURL
        self.appToken = appToken
    }

    // MARK: - Generic Request

    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var components = URLComponents(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(appToken, forHTTPHeaderField: "X-App-Token")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Onboard

    func onboard(deviceID: String) async throws -> OnboardResponse {
        try await makeRequest(
            endpoint: "/api/onboard",
            method: "POST",
            body: ["device_id": deviceID]
        )
    }

    // MARK: - Analytics

    func fetchAnalytics(deviceID: String) async throws -> AnalyticsResponse {
        try await makeRequest(
            endpoint: "/api/analytics",
            method: "GET",
            queryItems: [URLQueryItem(name: "device_id", value: deviceID)]
        )
    }

    // MARK: - Settings Toggles

    func toggleServices(deviceID: String, enabled: Bool) async throws -> SettingsResponse {
        try await makeRequest(
            endpoint: "/api/settings/services",
            method: "PATCH",
            body: ["device_id": deviceID, "enabled": enabled]
        )
    }

    func toggleNatives(deviceID: String, enabled: Bool) async throws -> SettingsResponse {
        try await makeRequest(
            endpoint: "/api/settings/natives",
            method: "PATCH",
            body: ["device_id": deviceID, "enabled": enabled]
        )
    }

    func toggleBlocklists(deviceID: String, enabled: Bool) async throws -> SettingsResponse {
        try await makeRequest(
            endpoint: "/api/settings/blocklists",
            method: "PATCH",
            body: ["device_id": deviceID, "enabled": enabled]
        )
    }
}
