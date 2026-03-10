import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var isSocialMediaBlocked: Bool
    @Published var isAnalyticsBlocked: Bool
    @Published var isAdvertisingBlocked: Bool
    @Published var errorMessage: String?
    
    private let networkManager: NextDNSNetworkManager
    private let defaults: UserDefaults
    
    init(networkManager: NextDNSNetworkManager, defaults: UserDefaults = .standard) {
        self.networkManager = networkManager
        self.defaults = defaults
        
        self.isSocialMediaBlocked = defaults.bool(forKey: "isSocialMediaBlocked")
        self.isAnalyticsBlocked = defaults.bool(forKey: "isAnalyticsBlocked")
        self.isAdvertisingBlocked = defaults.bool(forKey: "isAdvertisingBlocked")
    }
    
    func toggleSocialMedia(blocked: Bool) async {
        do {
            let services = ["instagram", "tiktok", "youtube", "facebook"]
            for service in services {
                try await networkManager.toggleService(serviceId: service, enabled: blocked)
            }
            
            self.isSocialMediaBlocked = blocked
            self.defaults.set(blocked, forKey: "isSocialMediaBlocked")
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSocialMediaBlocked = !blocked // revert state on failure
        }
    }
    
    func toggleAnalytics(blocked: Bool) async {
        do {
            try await networkManager.toggleNativeTracking(nativeId: "apple", enabled: blocked)
            
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
            try await networkManager.toggleBlocklist(blocklistId: "adguard", enabled: blocked)
            
            self.isAdvertisingBlocked = blocked
            self.defaults.set(blocked, forKey: "isAdvertisingBlocked")
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAdvertisingBlocked = !blocked
        }
    }
}
