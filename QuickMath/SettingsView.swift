import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
        nonmutating set { themeRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                Form {
                    // Pro status
                    Section("Inseason Pro") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Pro Active")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Link("Manage", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.qmAccent)
                            }
                        } else {
                            Button {
                                Haptics.tap()
                                showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "leaf.fill")
                                        .foregroundStyle(Color.qmAccent)
                                    Text("Unlock Inseason Pro")
                                        .foregroundStyle(Color.qmAccent)
                                }
                            }
                        }

                        Button {
                            Haptics.tap()
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchase")
                                .foregroundStyle(Color.qmAccent)
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Legal
                    Section("Legal") {
                        Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/inseason-site/privacy.html")!)
                            .foregroundStyle(Color.qmAccent)
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundStyle(Color.qmAccent)
                    }

                    // Data
                    Section("Data") {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete All Data")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog("Delete all data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all your saved picks. This action cannot be undone.")
            }
        }
    }
}
