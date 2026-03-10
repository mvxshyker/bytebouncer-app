import SwiftUI

@main
struct ByteBouncerApp: App {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("profileID") private var profileID: String = ""
    @AppStorage("apiKey") private var apiKey: String = ""

    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete {
                let networkManager = NextDNSNetworkManager(profileID: profileID, apiKey: apiKey)
                let viewModel = DashboardViewModel(networkManager: networkManager)
                DashboardView(viewModel: viewModel)
            } else {
                OnboardingView()
            }
        }
    }
}
