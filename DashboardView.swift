import SwiftUI
import Combine

struct MassiveToggle: View {
    @Binding var isActive: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isActive.toggle()
            }
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(isActive ? Color.zinc800 : Color.red950.opacity(0.4))
                    .frame(width: 192, height: 80)
                    .shadow(color: .black.opacity(0.6), radius: 5, x: 0, y: 4)
                    .shadow(color: isActive ? Color.lime500.opacity(0.1) : Color.red500.opacity(0.2), radius: 10, x: 0, y: 0)

                // Labels
                HStack {
                    Text("ACTIVE")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .tracking(2)
                        .foregroundColor(isActive ? .lime400 : .zinc600.opacity(0))
                    Spacer()
                    Text("PAUSED")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .tracking(2)
                        .foregroundColor(isActive ? .zinc600.opacity(0) : .red500)
                }
                .padding(.horizontal, 24)
                .frame(width: 192)

                // Knob
                HStack {
                    if isActive { Spacer(minLength: 0) }

                    Circle()
                        .fill(isActive ? Color.white : Color.red300)
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.zinc200, lineWidth: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.zinc200, lineWidth: 1)
                                .frame(width: 40, height: 40)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        )

                    if !isActive { Spacer(minLength: 0) }
                }
                .padding(.horizontal, 8)
                .frame(width: 192)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterRow: View {
    let title: String
    let description: String
    @Binding var checked: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.zinc200)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.zinc500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()

            Toggle("", isOn: Binding(
                get: { self.checked },
                set: { newValue in
                    self.checked = newValue
                    self.onChange(newValue)
                }
            ))
            .labelsHidden()
            .tint(.lime500)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.zinc900.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.zinc800.opacity(0.8), lineWidth: 1)
        )
    }
}

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var isFirewallActive: Bool = true
    @State private var packetsScanned: Int = 0
    @State private var packetsGuarded: Int = 0

    @State private var isInternalUpdate: Bool = false

    let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 0) {
                    // Top control bar
                    HStack {
                        Spacer()
                        Button(action: logout) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(.zinc500)
                                .padding()
                        }
                    }

                    // Header Image
                    Image(systemName: "shield.check.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(isFirewallActive ? .lime400 : .zinc600)
                        .padding(.bottom, 32)

                    // Metrics from analytics API
                    HStack(spacing: 12) {
                        VStack {
                            Text("PACKETS SENT")
                                .font(.system(size: 10, weight: .semibold, design: .default))
                                .foregroundColor(.zinc500)
                                .tracking(1)
                                .padding(.bottom, 2)
                            Text("\(packetsScanned)")
                                .font(.system(size: 20, weight: .regular, design: .monospaced))
                                .foregroundColor(.zinc300)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.zinc900.opacity(0.5))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )

                        VStack {
                            Text("TOTAL BLOCKED")
                                .font(.system(size: 10, weight: .semibold, design: .default))
                                .foregroundColor(Color.lime500.opacity(0.8))
                                .tracking(1)
                                .padding(.bottom, 2)
                            Text("\(viewModel.totalBlocked)")
                                .font(.system(size: 20, weight: .regular, design: .monospaced))
                                .foregroundColor(isFirewallActive ? .lime400 : .zinc600)
                                .shadow(color: isFirewallActive ? Color.lime500.opacity(0.5) : .clear, radius: 4, x: 0, y: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.lime500.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Top Blocked Domains
                    if !viewModel.topDomains.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOP BLOCKED DOMAINS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.zinc500)
                                .tracking(1)
                                .padding(.leading, 8)

                            ForEach(viewModel.topDomains) { domain in
                                HStack {
                                    Text(domain.name)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.zinc300)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(domain.queries)")
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.lime400)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.zinc900.opacity(0.4))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }

                    // Toggle
                    MassiveToggle(isActive: Binding(
                        get: { isFirewallActive },
                        set: { newValue in
                            isInternalUpdate = true
                            isFirewallActive = newValue

                            Task {
                                await viewModel.toggleSocialMedia(blocked: newValue)
                                await viewModel.toggleAnalytics(blocked: newValue)
                                await viewModel.toggleAdvertising(blocked: newValue)
                                isInternalUpdate = false
                            }
                        }
                    ))
                    .padding(.bottom, 24)

                    HStack(spacing: 8) {
                        Image(systemName: isFirewallActive ? "shield.checkerboard.fill" : "exclamationmark.triangle")
                            .font(.system(size: 14))
                        Text(isFirewallActive ? "Firewall is actively guarding" : "Firewall is currently paused")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(isFirewallActive ? .lime400 : .red500)
                    .padding(.bottom, 32)

                    // Filters List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TRAFFIC FILTERS")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.zinc500)
                            .tracking(1)
                            .padding(.leading, 8)

                        FilterRow(
                            title: "Social Media Prefetch",
                            description: "Blocks auto-playing videos & preloading",
                            checked: Binding(
                                get: { viewModel.isSocialMediaBlocked },
                                set: { newValue in
                                    if !isInternalUpdate {
                                        Task { await viewModel.toggleSocialMedia(blocked: newValue) }
                                    }
                                }
                            ),
                            onChange: { _ in }
                        )

                        FilterRow(
                            title: "Analytics & Crash Reports",
                            description: "Stops background telemetry to servers",
                            checked: Binding(
                                get: { viewModel.isAnalyticsBlocked },
                                set: { newValue in
                                    if !isInternalUpdate {
                                        Task { await viewModel.toggleAnalytics(blocked: newValue) }
                                    }
                                }
                            ),
                            onChange: { _ in }
                        )

                        FilterRow(
                            title: "Advertising Networks",
                            description: "Blocks ad tracking domains and scripts",
                            checked: Binding(
                                get: { viewModel.isAdvertisingBlocked },
                                set: { newValue in
                                    if !isInternalUpdate {
                                        Task { await viewModel.toggleAdvertising(blocked: newValue) }
                                    }
                                }
                            ),
                            onChange: { _ in }
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .onReceive(timer) { _ in
            packetsScanned += Int.random(in: 4...21)
            if isFirewallActive {
                packetsGuarded += Int.random(in: 0...5)
            }
        }
        .onChange(of: viewModel.isSocialMediaBlocked) { _ in checkFirewallState() }
        .onChange(of: viewModel.isAnalyticsBlocked) { _ in checkFirewallState() }
        .onChange(of: viewModel.isAdvertisingBlocked) { _ in checkFirewallState() }
        .onAppear {
            self.isFirewallActive = viewModel.isSocialMediaBlocked || viewModel.isAnalyticsBlocked || viewModel.isAdvertisingBlocked
            Task { await viewModel.fetchAnalytics() }
        }
    }

    private func checkFirewallState() {
        if isInternalUpdate { return }
        let anyActive = viewModel.isSocialMediaBlocked || viewModel.isAnalyticsBlocked || viewModel.isAdvertisingBlocked
        if anyActive && !isFirewallActive {
            isFirewallActive = true
        } else if !anyActive && isFirewallActive {
            isFirewallActive = false
        }
    }

    private func logout() {
        KeychainHelper.delete(key: "device_id")
        UserDefaults.standard.set(false, forKey: "isOnboardingComplete")
        UserDefaults.standard.set("", forKey: "dohURL")
        UserDefaults.standard.set(false, forKey: "isSocialMediaBlocked")
        UserDefaults.standard.set(false, forKey: "isAnalyticsBlocked")
        UserDefaults.standard.set(false, forKey: "isAdvertisingBlocked")
    }
}
