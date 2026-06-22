import SwiftUI
import SwiftData

// MARK: - SwiftData Models

@Model
final class ProduceItem {
    var id: UUID
    var name: String
    var produceType: String   // "fruit" or "vegetable"
    var peakMonths: [Int]     // 1=Jan … 12=Dec
    var notes: String

    init(id: UUID = UUID(), name: String, produceType: String, peakMonths: [Int], notes: String = "") {
        self.id = id
        self.name = name
        self.produceType = produceType
        self.peakMonths = peakMonths
        self.notes = notes
    }
}

@Model
final class SeasonWeek {
    var id: UUID
    var weekOfYear: Int
    var featuredProduceIds: [UUID]

    init(id: UUID = UUID(), weekOfYear: Int, featuredProduceIds: [UUID] = []) {
        self.id = id
        self.weekOfYear = weekOfYear
        self.featuredProduceIds = featuredProduceIds
    }
}

@Model
final class ProducePick {
    var id: UUID
    var produceItemId: UUID
    var markedDate: Date

    init(id: UUID = UUID(), produceItemId: UUID, markedDate: Date = Date()) {
        self.id = id
        self.produceItemId = produceItemId
        self.markedDate = markedDate
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var allProduce: [ProduceItem] = []
    @Published private(set) var weeklyProduce: [ProduceItem] = []
    @Published private(set) var nextWeekProduce: [ProduceItem] = []
    @Published private(set) var nextMonthProduce: [ProduceItem] = []
    @Published private(set) var picks: [ProducePick] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([ProduceItem.self, SeasonWeek.self, ProducePick.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) { return c }
        // fallback
        let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
        return (try? ModelContainer(for: schema, configurations: fallback))!
    }

    func reload() {
        let ctx = container.mainContext
        // Seed produce data if empty
        let count = (try? ctx.fetchCount(FetchDescriptor<ProduceItem>())) ?? 0
        if count == 0 { seedProduce(ctx: ctx) }

        allProduce = (try? ctx.fetch(FetchDescriptor<ProduceItem>(sortBy: [SortDescriptor(\.name)]))) ?? []

        let cal = Calendar.current
        let now = Date()
        let currentWeek = cal.component(.weekOfYear, from: now)
        let currentMonth = cal.component(.month, from: now)
        let nextWeek = currentWeek < 52 ? currentWeek + 1 : 1
        let nextMonth = currentMonth < 12 ? currentMonth + 1 : 1

        weeklyProduce = allProduce.filter { $0.peakMonths.contains(currentMonth) }
        nextWeekProduce = allProduce.filter { $0.peakMonths.contains(nextMonth) && !$0.peakMonths.contains(currentMonth) }
        nextMonthProduce = allProduce.filter { $0.peakMonths.contains(nextMonth) }
        picks = (try? ctx.fetch(FetchDescriptor<ProducePick>(sortBy: [SortDescriptor(\.markedDate, order: .reverse)]))) ?? []
        _ = nextWeek // used above for context
    }

    func refresh() { reload() }

    func togglePick(produceId: UUID) {
        let ctx = container.mainContext
        if let existing = picks.first(where: { $0.produceItemId == produceId }) {
            ctx.delete(existing)
        } else {
            let pick = ProducePick(produceItemId: produceId)
            ctx.insert(pick)
        }
        try? ctx.save()
        reload()
    }

    func isPicked(_ produceId: UUID) -> Bool {
        picks.contains(where: { $0.produceItemId == produceId })
    }

    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: ProduceItem.self)
        try? ctx.delete(model: SeasonWeek.self)
        try? ctx.delete(model: ProducePick.self)
        try? ctx.save()
        reload()
    }

    // MARK: - Seed

    private func seedProduce(ctx: ModelContext) {
        let items: [(String, String, [Int], String)] = [
            // Fruits
            ("Apple", "fruit", [9,10,11], "Crisp and sweet; best from autumn orchards."),
            ("Apricot", "fruit", [6,7], "Soft golden stone fruit; peak in early summer."),
            ("Avocado", "fruit", [3,4,5,6], "Creamy and rich; peaks spring through early summer."),
            ("Blackberry", "fruit", [7,8,9], "Tart summer berry; wonderful in crumbles."),
            ("Blueberry", "fruit", [6,7,8], "Sweet and antioxidant-rich; perfect mid-summer."),
            ("Cherry", "fruit", [5,6,7], "Sweet or sour; a fleeting early-summer treat."),
            ("Clementine", "fruit", [11,12,1,2], "Easy-peel citrus; peak through winter."),
            ("Fig", "fruit", [8,9,10], "Honey-sweet; best fresh in late summer and fall."),
            ("Grapefruit", "fruit", [1,2,3,11,12], "Bright and tangy; winter citrus at its best."),
            ("Grape", "fruit", [8,9,10], "Clusters of sweetness; harvest season favourite."),
            ("Kiwi", "fruit", [10,11,12,1], "Tropical flavour; peaks in autumn-winter."),
            ("Lemon", "fruit", [1,2,3,4,11,12], "Zesty year-round; freshest in cooler months."),
            ("Lime", "fruit", [5,6,7,8], "Bright and tart; peak through summer months."),
            ("Mango", "fruit", [5,6,7,8], "Luscious tropical stone fruit; peak early summer."),
            ("Melon", "fruit", [7,8,9], "Sweet and juicy; best on hot summer days."),
            ("Nectarine", "fruit", [6,7,8], "Smooth-skinned peach cousin; summer perfection."),
            ("Orange", "fruit", [11,12,1,2,3], "Classic winter citrus; vitamin-C powerhouse."),
            ("Peach", "fruit", [6,7,8], "Fragrant and juicy; enjoy at peak summer ripeness."),
            ("Pear", "fruit", [9,10,11], "Delicate and sweet; autumn's gentle fruit."),
            ("Persimmon", "fruit", [10,11,12], "Honey-toned autumn fruit; enjoy when fully ripe."),
            ("Pineapple", "fruit", [3,4,5,6], "Tropical and tangy; freshest in spring."),
            ("Plum", "fruit", [7,8,9], "Deep purple and juicy; late-summer stone fruit."),
            ("Pomegranate", "fruit", [10,11,12], "Ruby seeds; a festive autumn-winter treat."),
            ("Raspberry", "fruit", [6,7,8], "Fragile and intensely flavoured; mid-summer gem."),
            ("Strawberry", "fruit", [4,5,6], "Peak sweetness in late spring and early summer."),
            ("Watermelon", "fruit", [6,7,8], "Refreshing and cooling; the icon of summer."),
            // Vegetables
            ("Artichoke", "vegetable", [3,4,5], "Nutty and tender; a spring delicacy."),
            ("Asparagus", "vegetable", [3,4,5], "Slender and grassy; a brief spring luxury."),
            ("Beetroot", "vegetable", [7,8,9,10], "Earthy and sweet; roast or pickle through summer-fall."),
            ("Broccoli", "vegetable", [10,11,12,1,2,3], "Hearty and nutritious; peaks in cooler months."),
            ("Brussels Sprout", "vegetable", [10,11,12,1], "Sweet after frost; a winter-table staple."),
            ("Butternut Squash", "vegetable", [9,10,11], "Rich and creamy; autumn's versatile veggie."),
            ("Cabbage", "vegetable", [10,11,12,1,2,3], "Crisp and sturdy; peaks in cool weather."),
            ("Carrot", "vegetable", [9,10,11,12], "Sweet and crunchy; roots peak in autumn."),
            ("Cauliflower", "vegetable", [10,11,12,1,2,3], "Mild and versatile; best in the cool season."),
            ("Celery", "vegetable", [9,10,11], "Crisp aromatics; peak in autumn harvest."),
            ("Courgette", "vegetable", [6,7,8,9], "Tender summer squash; prolific through warm months."),
            ("Cucumber", "vegetable", [6,7,8], "Cool and crisp; perfect for hot summer salads."),
            ("Fennel", "vegetable", [10,11,12,1,2], "Anise-scented; peak through autumn-winter."),
            ("Garlic", "vegetable", [6,7,8], "Freshly cured bulbs; best at harvest time."),
            ("Kale", "vegetable", [10,11,12,1,2,3], "Nutrient-dense leafy green; sweetened by frost."),
            ("Leek", "vegetable", [10,11,12,1,2,3], "Mild onion cousin; peak in autumn and winter."),
            ("Lettuce", "vegetable", [4,5,6,9,10], "Tender leaves; best in mild spring and autumn."),
            ("Mushroom", "vegetable", [9,10,11,3,4], "Earthy fungi; foraged in cool damp seasons."),
            ("Onion", "vegetable", [8,9,10], "Pungent base; cured and freshest post-harvest."),
            ("Parsnip", "vegetable", [10,11,12,1,2], "Sweet and starchy; improved by a touch of frost."),
            ("Pea", "vegetable", [4,5,6], "Tiny spring jewels; eat as soon as possible."),
            ("Pepper", "vegetable", [7,8,9], "Sweet or spicy; at its colourful peak in summer."),
            ("Potato", "vegetable", [7,8,9,10], "New potatoes in summer; maincrop in autumn."),
            ("Pumpkin", "vegetable", [9,10,11], "Sweet and dense; peak with the autumn harvest."),
            ("Radish", "vegetable", [3,4,5,9,10], "Peppery and crunchy; thrives in cooler months."),
            ("Spinach", "vegetable", [3,4,5,9,10], "Tender leaves; best in spring and early autumn."),
            ("Sweet Corn", "vegetable", [7,8,9], "Sugar peaks just after harvest; a summer staple."),
            ("Sweet Potato", "vegetable", [10,11,12], "Rich and caramelising; peak autumn harvest."),
            ("Tomato", "vegetable", [7,8,9], "Vine-ripened warmth; incomparable in summer."),
            ("Turnip", "vegetable", [9,10,11,12], "Earthy and peppery; best harvested in autumn.")
        ]
        for (name, type, months, notes) in items {
            ctx.insert(ProduceItem(name: name, produceType: type, peakMonths: months, notes: notes))
        }
        try? ctx.save()
    }
}

// MARK: - Cooking Ideas helper

struct CookingIdea {
    let title: String
    let description: String
}

func cookingIdeas(for item: ProduceItem) -> [CookingIdea] {
    switch item.name.lowercased() {
    case "tomato":
        return [CookingIdea(title: "Fresh Caprese", description: "Slice with fresh mozzarella, basil, and olive oil."),
                CookingIdea(title: "Slow-Roasted", description: "Halve and roast at low heat until jammy and sweet."),
                CookingIdea(title: "Gazpacho", description: "Blend raw with cucumber and peppers for chilled soup.")]
    case "strawberry":
        return [CookingIdea(title: "Macerated with Sugar", description: "Toss with a pinch of sugar and lemon zest; serve over yoghurt."),
                CookingIdea(title: "Summer Tart", description: "Fill a blind-baked shell with crème patissière and fresh berries."),
                CookingIdea(title: "Strawberry Jam", description: "Cook down with sugar and lemon juice for a bright spread.")]
    case "asparagus":
        return [CookingIdea(title: "Chargrilled", description: "Toss in oil and grill until lightly charred; finish with lemon."),
                CookingIdea(title: "Pasta Primavera", description: "Toss blanched spears with pasta, butter, and Parmesan."),
                CookingIdea(title: "Soft-Boiled Egg Soldiers", description: "Serve spears alongside a runny egg for dipping.")]
    case "apple":
        return [CookingIdea(title: "Classic Crumble", description: "Peel and chunk with cinnamon; top with oat crumble and bake."),
                CookingIdea(title: "Waldorf Salad", description: "Dice with celery, walnuts, and a light mayo dressing."),
                CookingIdea(title: "Spiced Sauce", description: "Simmer peeled apples with spices for a warming side.")]
    case "peach":
        return [CookingIdea(title: "Grilled Peach Salad", description: "Halve, grill until caramelised, serve with rocket and goat cheese."),
                CookingIdea(title: "Bellini", description: "Blend fresh peach purée with chilled Prosecco."),
                CookingIdea(title: "Peach Galette", description: "Slice onto rough puff pastry with almond cream; fold and bake.")]
    case "courgette":
        return [CookingIdea(title: "Courgette Fritters", description: "Grate, squeeze dry, season, and pan-fry in patties."),
                CookingIdea(title: "Stuffed Courgette", description: "Hollow out and fill with herbed rice and cheese; bake."),
                CookingIdea(title: "Raw Ribbon Salad", description: "Use a peeler for thin ribbons; dress with lemon and mint.")]
    case "butternut squash":
        return [CookingIdea(title: "Roasted Soup", description: "Roast halves until tender; blend with stock and spices."),
                CookingIdea(title: "Risotto", description: "Stir diced squash into a saffron-scented risotto base."),
                CookingIdea(title: "Sheet Pan Roast", description: "Cube with sage and red onion; roast until caramelised.")]
    default:
        // Generic ideas based on type
        if item.produceType == "fruit" {
            return [CookingIdea(title: "Fresh & Simple", description: "Enjoy at room temperature to appreciate its peak flavour."),
                    CookingIdea(title: "Fruit Compote", description: "Simmer with a little sugar and citrus for a versatile sauce."),
                    CookingIdea(title: "Seasonal Smoothie", description: "Blend with yoghurt and honey for a nutritious drink.")]
        } else {
            return [CookingIdea(title: "Simple Roast", description: "Toss with olive oil and sea salt; roast at high heat."),
                    CookingIdea(title: "Seasonal Soup", description: "Simmer with aromatics and blend for a warming bowl."),
                    CookingIdea(title: "Sautéed Side", description: "Cook in butter with garlic over medium-high heat.")]
        }
    }
}
