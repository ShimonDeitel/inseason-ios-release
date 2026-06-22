import SwiftUI

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showInsights = false
    @State private var showPaywall = false

    private var currentWeekLabel: String {
        let cal = Calendar.current
        let week = cal.component(.weekOfYear, from: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: Date())
        return "Week \(week) · \(month)"
    }

    var body: some View {
        ZStack {
            QMBackground()
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header stats
                        HStack(spacing: 12) {
                            MetricTile(value: "\(appModel.weeklyProduce.count)", label: "In Season")
                            MetricTile(value: "\(appModel.picks.count)", label: "My Picks")
                            MetricTile(value: appModel.weeklyProduce.filter { $0.produceType == "fruit" }.count.description, label: "Fruits")
                        }
                        .padding(.horizontal)

                        // This week's produce
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Peak This Week")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)

                            if appModel.weeklyProduce.isEmpty {
                                Text("No produce data yet.")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            } else {
                                GridView()
                            }
                        }

                        // Pro features tile
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                Haptics.tap()
                                if store.isPro {
                                    showInsights = true
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "leaf.fill")
                                                .foregroundStyle(Color.qmAccent)
                                                .font(.body)
                                            Text("Inseason Pro")
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            if store.isPro {
                                                Text("ACTIVE")
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.qmAccent, in: Capsule())
                                            }
                                        }
                                        Text(store.isPro ? "Look-ahead, cooking ideas & picks" : "Unlock look-ahead, cooking ideas & more")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: store.isPro ? "chevron.right" : "lock.fill")
                                        .foregroundStyle(Color.qmAccent)
                                        .font(.body)
                                }
                                .padding()
                            }
                        }
                        .qmCard()
                        .padding(.horizontal)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 16)
                }
                .navigationTitle(currentWeekLabel)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Haptics.tap()
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(Color.qmAccent)
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(store)
                        .environmentObject(appModel)
                }
                .sheet(isPresented: $showInsights) {
                    InsightsView()
                        .environmentObject(appModel)
                        .environmentObject(store)
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                        .environmentObject(store)
                }
                .onAppear {
                    if forceScreen == "insights" { showInsights = true }
                    if forceScreen == "paywall" { showPaywall = true }
                }
            }
        }
    }
}
