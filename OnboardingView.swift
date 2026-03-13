import SwiftUI

struct OnboardingView: View {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("dohURL") private var dohURL: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "shield.righthalf.filled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.lime400)

                VStack(spacing: 8) {
                    Text("ByteBouncer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("DNS-powered privacy protection.\nOne tap to get started.")
                        .font(.system(size: 14))
                        .foregroundColor(.zinc500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                Button(action: onboard) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Activate Protection")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.black)
                    .background(Color.lime400)
                    .cornerRadius(16)
                    .shadow(color: Color.lime500.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func onboard() {
        isLoading = true
        errorMessage = nil

        // Generate or retrieve existing device ID
        let deviceID: String
        if let existing = KeychainHelper.read(key: "device_id") {
            deviceID = existing
        } else {
            deviceID = UUID().uuidString
            KeychainHelper.save(key: "device_id", value: deviceID)
        }

        Task {
            do {
                let response = try await apiClient.onboard(deviceID: deviceID)
                dohURL = response.dohURL
                isOnboardingComplete = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
