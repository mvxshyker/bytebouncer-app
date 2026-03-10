import SwiftUI

struct OnboardingView: View {
    @AppStorage("profileID") private var profileID: String = ""
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    
    @State private var inputProfileID: String = ""
    @State private var inputAPIKey: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 32) {
                    Image(systemName: "shield.righthalf.filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.lime400)
                        .padding(.top, 60)
                    
                    VStack(spacing: 8) {
                        Text("NextDNS Configuration")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your NextDNS Profile ID and API Key to control your privacy directly from ByteBouncer.")
                            .font(.system(size: 14))
                            .foregroundColor(.zinc500)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    VStack(spacing: 20) {
                        // Profile ID Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROFILE ID")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.zinc500)
                                .tracking(1)
                                .padding(.leading, 4)
                            
                            TextField("", text: $inputProfileID)
                                .padding()
                                .background(Color.zinc900.opacity(0.6))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.zinc800.opacity(0.8), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // API Key Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API KEY")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.zinc500)
                                .tracking(1)
                                .padding(.leading, 4)
                            
                            SecureField("", text: $inputAPIKey)
                                .padding()
                                .background(Color.zinc900.opacity(0.6))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.zinc800.opacity(0.8), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: saveCredentials) {
                        Text("Save & Continue")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(isFormValid ? .black : .zinc500)
                            .background(isFormValid ? Color.lime400 : Color.zinc800)
                            .cornerRadius(16)
                            .shadow(color: isFormValid ? Color.lime500.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                inputProfileID = profileID
                inputAPIKey = apiKey
            }
        }
    }
    
    private var isFormValid: Bool {
        !inputProfileID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !inputAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveCredentials() {
        profileID = inputProfileID.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = inputAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        isOnboardingComplete = true
    }
}

#Preview {
    OnboardingView()
}
