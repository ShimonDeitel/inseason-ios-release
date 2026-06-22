import SwiftUI

struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var selectedItem: ProduceItem? = nil
    @State private var showPaywall = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs
            let fruits = appModel.weeklyProduce.filter { $0.produceType == "fruit" }
            let vegs = appModel.weeklyProduce.filter { $0.produceType == "vegetable" }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(appModel.weeklyProduce, id: \.id) { item in
                    ProduceCard(item: item, isPicked: appModel.isPicked(item.id))
                        .onTapGesture {
                            Haptics.tap()
                            if store.isPro {
                                selectedItem = item
                            } else {
                                showPaywall = true
                            }
                        }
                        .onLongPressGesture {
                            Haptics.success()
                            appModel.togglePick(produceId: item.id)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if !appModel.weeklyProduce.isEmpty {
                Text("\(fruits.count) fruit\(fruits.count == 1 ? "" : "s") · \(vegs.count) vegetable\(vegs.count == 1 ? "" : "s") in season")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }
        }
        .sheet(item: $selectedItem) { item in
            ProduceDetailView(item: item)
                .environmentObject(appModel)
                .environmentObject(store)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }
}

// MARK: - ProduceCard

struct ProduceCard: View {
    let item: ProduceItem
    let isPicked: Bool

    private var typeColor: Color {
        item.produceType == "fruit" ? Color.qmAccent.opacity(0.12) : Color.qmCorrect.opacity(0.1)
    }

    private var typeIcon: String {
        item.produceType == "fruit" ? "apple.logo" : "leaf"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: typeIcon)
                    .foregroundStyle(item.produceType == "fruit" ? Color.qmAccent : Color.qmCorrect)
                    .font(.callout)
                Spacer()
                if isPicked {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color.qmWrong)
                        .font(.caption)
                }
            }
            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(monthRange(item.peakMonths))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(typeColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isPicked ? Color.qmWrong.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }

    private func monthRange(_ months: [Int]) -> String {
        guard !months.isEmpty else { return "" }
        let names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let sorted = months.sorted()
        if sorted.count == 1 { return names[sorted[0] - 1] }
        return "\(names[sorted.first! - 1]) – \(names[sorted.last! - 1])"
    }
}

// MARK: - ProduceDetailView (Pro)

struct ProduceDetailView: View {
    let item: ProduceItem
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: item.produceType == "fruit" ? "apple.logo" : "leaf")
                                .foregroundStyle(Color.qmAccent)
                                .font(.title3)
                            Text(item.produceType.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text(item.name)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                        if !item.notes.isEmpty {
                            Text(item.notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Peak season
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Peak Months")
                            .font(.headline)
                            .padding(.horizontal)
                        peakMonthsBar
                            .padding(.horizontal)
                    }

                    // Pick button
                    Button {
                        Haptics.success()
                        appModel.togglePick(produceId: item.id)
                    } label: {
                        HStack {
                            Image(systemName: appModel.isPicked(item.id) ? "heart.fill" : "heart")
                            Text(appModel.isPicked(item.id) ? "Remove from Picks" : "Add to My Picks")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .prominentButton()
                    .padding(.horizontal)

                    // Cooking ideas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cooking Ideas")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(cookingIdeas(for: item), id: \.title) { idea in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(idea.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(idea.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .qmCard()
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }

    private var peakMonthsBar: some View {
        let names = ["J","F","M","A","M","J","J","A","S","O","N","D"]
        let currentMonth = Calendar.current.component(.month, from: Date())
        return HStack(spacing: 4) {
            ForEach(Array(names.enumerated()), id: \.offset) { idx, letter in
                let month = idx + 1
                let isPeak = item.peakMonths.contains(month)
                let isCurrent = month == currentMonth
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isPeak ? Color.qmAccent : Color.qmField)
                        .frame(height: 24)
                        .overlay(
                            isCurrent
                                ? RoundedRectangle(cornerRadius: 3).strokeBorder(Color.qmAccent, lineWidth: 2)
                                : nil
                        )
                    Text(letter)
                        .font(.system(size: 9, weight: isCurrent ? .bold : .regular))
                        .foregroundStyle(isCurrent ? Color.qmAccent : Color.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
