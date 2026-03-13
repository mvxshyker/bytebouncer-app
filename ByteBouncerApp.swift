import SwiftUI

@main
struct ByteBouncerApp: App {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false

    // TODO: Replace with your actual backend URL and app token
    private let baseURL = "https://api.yourdomain.com"
    private let appToken = "YOUR_APP_TOKEN_HERE"

    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete, let deviceID = KeychainHelper.read(key: "device_id") {
                let apiClient = APIClient(baseURL: baseURL, appToken: appToken)
                let viewModel = DashboardViewModel(apiClient: apiClient, deviceID: deviceID)
                DashboardView(viewModel: viewModel)
            } else {
                let apiClient = APIClient(baseURL: baseURL, appToken: appToken)
                OnboardingView(apiClient: apiClient)
            }
        }
    }
}
