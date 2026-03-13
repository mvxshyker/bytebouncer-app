import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var isSocialMediaBlocked: Bool
    @Published var isAnalyticsBlocked: Bool
    @Published var isAdvertisingBlocked: Bool
    @Published var errorMessage: String?

    // Analytics
    @Published var totalBlocked: Int = 0
    @Published var topDomains: [BlockedDomain] = []
    @Published var isLoadingAnalytics: Bool = false

    private let apiClient: APIClient
    private let deviceID: String
    private let defaults: UserDefaults

    init(apiClient: APIClient, deviceID: String, defaults: UserDefaults = .standard) {
        self.apiClient = apiClient
        self.deviceID = deviceID
        self.defaults = defaults

        self.isSocialMediaBlocked = defaults.bool(forKey: "isSocialMediaBlocked")
        self.isAnalyticsBlocked = defaults.bool(forKey: "isAnalyticsBlocked")
        self.isAdvertisingBlocked = defaults.bool(forKey: "isAdvertisingBlocked")
    }

    // MARK: - Analytics

    func fetchAnalytics() async {
        isLoadingAnalytics = true
        do {
            let response = try await apiClient.fetchAnalytics(deviceID: deviceID)
            self.totalBlocked = response.totalBlocked
            self.topDomains = response.topDomains
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingAnalytics = false
    }

    // MARK: - Toggles

    func toggleSocialMedia(blocked: Bool) async {
        do {
            _ = try await apiClient.toggleServices(deviceID: deviceID, enabled: blocked)
            self.isSocialMediaBlocked = blocked
            self.defaults.set(blocked, forKey: "isSocialMediaBlocked")
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSocialMediaBlocked = !blocked
        }
    }

    func toggleAnalytics(blocked: Bool) async {
        do {
            _ = try await apiClient.toggleNatives(deviceID: deviceID, enabled: blocked)
            self.isAnalyticsBlocked = blocked
            self.defaults.set(blocked, forKey: "isAnalyticsBlocked")
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAnalyticsBlocked = !blocked
        }
    }

    func toggleAdvertising(blocked: Bool) async {
        do {
            _ = try await apiClient.toggleBlocklists(deviceID: deviceID, enabled: blocked)
            self.isAdvertisingBlocked = blocked
            self.defaults.set(blocked, forKey: "isAdvertisingBlocked")
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAdvertisingBlocked = !blocked
        }
    }
}
