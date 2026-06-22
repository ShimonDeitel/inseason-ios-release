import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits = [
        ("calendar.badge.clock", "Look-ahead view of what comes into season next week and next month"),
        ("fork.knife", "Tap any item for matched seasonal cooking ideas"),
        ("heart.fill", "Personal picks list with reminders when a favourite hits peak")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        // Icon + title
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.qmAccent.opacity(0.1))
                                    .frame(width: 88, height: 88)
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(Color.qmAccent)
                                    .font(.system(size: 40))
                            }
                            Text("Inseason Pro")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("$0.99 / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        // Benefits
                        VStack(spacing: 0) {
                            ForEach(Array(benefits.enumerated()), id: \.offset) { idx, benefit in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: benefit.0)
                                        .foregroundStyle(Color.qmAccent)
                                        .font(.body)
                                        .frame(width: 24)
                                    Text(benefit.1)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                if idx < benefits.count - 1 {
                                    Divider()
                                        .background(Color.qmHair)
                                }
                            }
                        }
                        .qmCard()

                        // Unlock button
                        Button {
                            Haptics.tap()
                            Task { await store.purchase() }
                        } label: {
                            HStack {
                                if store.purchaseInFlight {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Unlock for \(store.displayPrice)/month")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)

                        // Restore
                        Button {
                            Haptics.tap()
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchase")
                                .font(.subheadline)
                                .foregroundStyle(Color.qmAccent)
                        }

                        // Disclosure
                        VStack(spacing: 8) {
                            Text("Inseason Pro is an auto-renewable subscription at \(store.displayPrice) per month. Your subscription will automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your Apple ID Account Settings at any time.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption2)
                                    .foregroundStyle(Color.qmAccent)
                                Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/inseason-site/privacy.html")!)
                                    .font(.caption2)
                                    .foregroundStyle(Color.qmAccent)
                            }
                        }
                        .padding(.horizontal, 8)

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
}
