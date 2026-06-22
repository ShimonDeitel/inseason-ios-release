import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Look-ahead: next week
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(icon: "calendar.badge.clock", title: "Coming Next Week")
                        if appModel.nextWeekProduce.isEmpty {
                            emptyNote("Nothing new coming in next week – it's all in season now.")
                        } else {
                            ForEach(appModel.nextWeekProduce, id: \.id) { item in
                                ProduceRowView(item: item, isPicked: appModel.isPicked(item.id))
                                    .onLongPressGesture {
                                        Haptics.success()
                                        appModel.togglePick(produceId: item.id)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Look-ahead: next month
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(icon: "calendar", title: "In Season Next Month")
                        if appModel.nextMonthProduce.isEmpty {
                            emptyNote("Nothing new next month – enjoy what's here now.")
                        } else {
                            ForEach(appModel.nextMonthProduce, id: \.id) { item in
                                ProduceRowView(item: item, isPicked: appModel.isPicked(item.id))
                                    .onLongPressGesture {
                                        Haptics.success()
                                        appModel.togglePick(produceId: item.id)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // My picks
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(icon: "heart.fill", title: "My Picks")
                        if appModel.picks.isEmpty {
                            emptyNote("Long-press any produce to add it to your picks list.")
                        } else {
                            ForEach(appModel.picks, id: \.id) { pick in
                                if let item = appModel.allProduce.first(where: { $0.id == pick.produceItemId }) {
                                    ProduceRowView(item: item, isPicked: true)
                                        .onLongPressGesture {
                                            Haptics.warning()
                                            appModel.togglePick(produceId: item.id)
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Stats overview
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(icon: "chart.bar.fill", title: "Season Snapshot")
                        HStack(spacing: 12) {
                            MetricTile(value: "\(appModel.allProduce.filter { $0.produceType == "fruit" }.count)", label: "Total Fruits")
                            MetricTile(value: "\(appModel.allProduce.filter { $0.produceType == "vegetable" }.count)", label: "Vegetables")
                        }
                        HStack(spacing: 12) {
                            MetricTile(value: "\(appModel.weeklyProduce.count)", label: "Peak Now")
                            MetricTile(value: "\(appModel.picks.count)", label: "Picks Saved")
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Inseason Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.qmAccent)
                .font(.subheadline)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - ProduceRowView

struct ProduceRowView: View {
    let item: ProduceItem
    let isPicked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.produceType == "fruit" ? "apple.logo" : "leaf")
                .foregroundStyle(item.produceType == "fruit" ? Color.qmAccent : Color.qmCorrect)
                .font(.body)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(item.notes.isEmpty ? item.produceType.capitalized : item.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isPicked {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.qmWrong)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
