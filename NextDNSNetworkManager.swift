import Foundation

enum NextDNSError: Error {
    case invalidURL
    case unauthorized
    case networkError(Error)
    case invalidResponse
    case badStatusCode(Int)
}

class NextDNSNetworkManager {
    private let session: URLSession
    private let profileID: String
    private let apiKey: String
    private let baseURL = "https://api.nextdns.io/profiles"

    init(session: URLSession = .shared, profileID: String, apiKey: String) {
        self.session = session
        self.profileID = profileID
        self.apiKey = apiKey
    }

    private func makeRequest(endpoint: String, method: String, bodyId: String? = nil) async throws {
        guard let url = URL(string: "\(baseURL)/\(profileID)\(endpoint)") else {
            throw NextDNSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let bodyId = bodyId {
            let bodyDict = ["id": bodyId]
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)
        }

        let (_, response) : (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw NextDNSError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextDNSError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw NextDNSError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NextDNSError.badStatusCode(httpResponse.statusCode)
        }
    }

    // 1. Social Media Prefetch
    func toggleService(serviceId: String, enabled: Bool) async throws {
        if enabled {
            try await makeRequest(endpoint: "/parentalcontrol/services", method: "POST", bodyId: serviceId)
        } else {
            try await makeRequest(endpoint: "/parentalcontrol/services/\(serviceId)", method: "DELETE")
        }
    }

    // 2. Analytics & Crash Reports
    func toggleNativeTracking(nativeId: String, enabled: Bool) async throws {
        if enabled {
            try await makeRequest(endpoint: "/privacy/natives", method: "POST", bodyId: nativeId)
        } else {
            try await makeRequest(endpoint: "/privacy/natives/\(nativeId)", method: "DELETE")
        }
    }

    // 3. Advertising Networks
    func toggleBlocklist(blocklistId: String, enabled: Bool) async throws {
        if enabled {
            try await makeRequest(endpoint: "/privacy/blocklists", method: "POST", bodyId: blocklistId)
        } else {
            try await makeRequest(endpoint: "/privacy/blocklists/\(blocklistId)", method: "DELETE")
        }
    }
}
