import SwiftUI
import Combine

// MARK: - Finance Data Models

struct FinTransaction: Identifiable, Codable {
    var id       = UUID()
    var title    = ""
    var amount   : Double = 0
    var type     : FinTxType = .expense
    var catName  = ""          // matches FinBudgetCategory.name
    var date     = Date()
    var note     = ""
    var isRecurring = false
}

enum FinTxType: String, Codable, CaseIterable {
    case income     = "Доход"
    case expense    = "Расход"
    case investment = "Инвестиция"
    case transfer   = "Перевод"

    var icon   : String { switch self { case .income: "arrow.down.circle.fill"; case .expense: "arrow.up.circle.fill"; case .investment: "chart.line.uptrend.xyaxis"; case .transfer: "arrow.left.arrow.right.circle.fill" } }
    var color  : Color  { switch self { case .income: .green; case .expense: Color(red:1,green:0.3,blue:0.3); case .investment: Color(red:0.6,green:0.4,blue:1); case .transfer: .orange } }
    var sign   : String { self == .income ? "+" : "-" }
}

struct FinBudgetCategory: Identifiable, Codable {
    var id          = UUID()
    var name        = ""
    var icon        = "circle.fill"
    var colorHex    = "007AFF"   // hex string for simplicity
    var budget      : Double = 0
    var isMandatory = true
    var txType      : FinTxType = .expense

    // helper
    var uiColor: Color {
        switch colorHex {
        case "FF4040": return Color(red:1,green:0.25,blue:0.25)
        case "FF9500": return Color(red:1,green:0.58,blue:0)
        case "FFCC00": return Color(red:1,green:0.8,blue:0)
        case "34C759": return Color(red:0.2,green:0.78,blue:0.35)
        case "5AC8FA": return Color(red:0.35,green:0.78,blue:0.98)
        case "007AFF": return Color(red:0,green:0.48,blue:1)
        case "5856D6": return Color(red:0.35,green:0.34,blue:0.84)
        case "AF52DE": return Color(red:0.69,green:0.32,blue:0.87)
        case "FF2D55": return Color(red:1,green:0.18,blue:0.33)
        case "A2845E": return Color(red:0.64,green:0.52,blue:0.37)
        default:       return Color(red:0,green:0.48,blue:1)
        }
    }
}

struct FinGoal: Identifiable, Codable {
    var id            = UUID()
    var title         = ""
    var icon          = "target"
    var targetAmount  : Double = 0
    var currentAmount : Double = 0
    var deadline      : Date? = nil
    var colorHex      = "007AFF"

    var progress: Double { targetAmount > 0 ? min(currentAmount / targetAmount, 1) : 0 }
    var uiColor : Color  { FinBudgetCategory(colorHex: colorHex).uiColor }
}

// MARK: - FinanceVM

final class FinanceVM: ObservableObject {

    @Published var transactions : [FinTransaction]    { didSet { save() } }
    @Published var categories   : [FinBudgetCategory] { didSet { save() } }
    @Published var goals        : [FinGoal]           { didSet { save() } }
    @Published var selectedDate = Date()

    init() {
        transactions = (try? JSONDecoder().decode([FinTransaction].self,    from: UserDefaults.standard.data(forKey: "fin_tx")   ?? Data())) ?? []
        goals        = (try? JSONDecoder().decode([FinGoal].self,           from: UserDefaults.standard.data(forKey: "fin_goals") ?? Data())) ?? []
        categories   = (try? JSONDecoder().decode([FinBudgetCategory].self, from: UserDefaults.standard.data(forKey: "fin_cats") ?? Data())) ?? FinanceVM.defaultCategories()
    }

    // MARK: Persistence
    private func save() {
        if let d = try? JSONEncoder().encode(transactions)  { UserDefaults.standard.set(d, forKey: "fin_tx") }
        if let d = try? JSONEncoder().encode(goals)         { UserDefaults.standard.set(d, forKey: "fin_goals") }
        if let d = try? JSONEncoder().encode(categories)    { UserDefaults.standard.set(d, forKey: "fin_cats") }
    }

    // MARK: Helpers
    private var cal: Calendar { Calendar.current }

    var displayMonth: String {
        let df = DateFormatter(); df.locale = Locale(identifier: "ru_RU"); df.dateFormat = "LLLL yyyy"
        return df.string(from: selectedDate).capitalized
    }

    func prevMonth() { selectedDate = cal.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate }
    func nextMonth() { selectedDate = cal.date(byAdding: .month, value:  1, to: selectedDate) ?? selectedDate }
    var isCurrentMonth: Bool { cal.isDate(selectedDate, equalTo: Date(), toGranularity: .month) }

    // Transactions for selected month
    var monthTx: [FinTransaction] {
        transactions.filter { cal.isDate($0.date, equalTo: selectedDate, toGranularity: .month) }
    }

    var monthIncome    : Double { monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    var monthExpense   : Double { monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    var monthInvest    : Double { monthTx.filter { $0.type == .investment }.reduce(0) { $0 + $1.amount } }
    var monthBalance   : Double { monthIncome - monthExpense - monthInvest }
    var savingsRate    : Double { monthIncome > 0 ? (monthIncome - monthExpense) / monthIncome : 0 }

    // 50/30/20
    var mandatoryExp   : Double {
        let mandatoryNames = categories.filter { $0.isMandatory && $0.txType == .expense }.map { $0.name }
        return monthTx.filter { $0.type == .expense && mandatoryNames.contains($0.catName) }.reduce(0) { $0 + $1.amount }
    }
    var optionalExp    : Double { max(0, monthExpense - mandatoryExp) }
    var investSavings  : Double { monthInvest + max(0, monthBalance) }

    func mandatoryRatio() -> Double { monthIncome > 0 ? min(mandatoryExp / monthIncome, 1) : 0 }
    func optionalRatio() -> Double  { monthIncome > 0 ? min(optionalExp  / monthIncome, 1) : 0 }
    func investRatio()   -> Double  { monthIncome > 0 ? min(investSavings / monthIncome, 1) : 0 }

    // Spent per category this month
    func spent(for cat: FinBudgetCategory) -> Double {
        monthTx.filter { $0.catName == cat.name && $0.type == cat.txType }.reduce(0) { $0 + $1.amount }
    }

    // 6-month chart
    struct MonthBar: Identifiable {
        var id    = UUID()
        var label : String
        var income: Double
        var expense: Double
    }
    var chartBars: [MonthBar] {
        var bars: [MonthBar] = []
        let df = DateFormatter(); df.locale = Locale(identifier: "ru_RU"); df.dateFormat = "LLL"
        for i in stride(from: -5, through: 0, by: 1) {
            guard let d = cal.date(byAdding: .month, value: i, to: Date()) else { continue }
            let tx = transactions.filter { cal.isDate($0.date, equalTo: d, toGranularity: .month) }
            bars.append(MonthBar(
                label  : df.string(from: d).prefix(3).capitalized,
                income : tx.filter { $0.type == .income }.reduce(0)  { $0 + $1.amount },
                expense: tx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            ))
        }
        return bars
    }

    // CRUD
    func add(_ tx: FinTransaction)   { transactions.append(tx) }
    func delete(_ tx: FinTransaction){ transactions.removeAll { $0.id == tx.id } }
    func addGoal(_ g: FinGoal)       { goals.append(g) }
    func deleteGoal(_ g: FinGoal)    { goals.removeAll { $0.id == g.id } }

    // Default categories from Excel analysis
    static func defaultCategories() -> [FinBudgetCategory] {
        let mandatory: [(String, String, String)] = [
            ("Еда / Продукты",      "cart.fill",               "FF9500"),
            ("ЖКХ",                 "bolt.fill",               "FFCC00"),
            ("Телефон",             "phone.fill",              "5AC8FA"),
            ("Транспорт",           "tram.fill",               "007AFF"),
            ("Здоровье",            "cross.fill",              "FF4040"),
            ("Одежда",              "tshirt.fill",             "AF52DE"),
            ("Вещи для дома",       "house.fill",              "A2845E"),
            ("Налоги",              "doc.text.fill",           "FF2D55"),
            ("Подписки",            "repeat",                  "5856D6"),
        ]
        let optional: [(String, String, String)] = [
            ("Развлечения",         "gamecontroller.fill",     "5856D6"),
            ("Кафе / Рестораны",    "fork.knife",              "FF9500"),
            ("Подарки",             "gift.fill",               "FF4040"),
            ("Праздники",           "party.popper.fill",       "FFCC00"),
            ("Путешествия",         "airplane",                "5AC8FA"),
            ("Спорт",               "figure.run",              "34C759"),
            ("Вредные привычки",    "flame.fill",              "FF2D55"),
            ("Долги / Кредиты",     "creditcard.fill",         "A2845E"),
            ("Внеплановые",         "exclamationmark.triangle.fill", "FF4040"),
        ]
        var result: [FinBudgetCategory] = []
        for (name, icon, hex) in mandatory {
            result.append(FinBudgetCategory(name: name, icon: icon, colorHex: hex, isMandatory: true, txType: .expense))
        }
        for (name, icon, hex) in optional {
            result.append(FinBudgetCategory(name: name, icon: icon, colorHex: hex, isMandatory: false, txType: .expense))
        }
        return result
    }
}

// MARK: - Main Finance View

struct FinanceView: View {
    @StateObject private var vm = FinanceVM()
    @State private var showAddTx     = false
    @State private var showAddGoal   = false
    @State private var showBudgetEdit: FinBudgetCategory? = nil
    @State private var showChart     = false
    @State private var showAllTx     = false

    private let blue = Color(red: 0, green: 0.48, blue: 1)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // ── Header ──
                    headerView

                    // ── Balance Card ──
                    balanceCard

                    // ── 50/30/20 Rule ──
                    budgetRuleCard

                    // ── 6-Month Chart ──
                    chartCard

                    // ── Budget Categories ──
                    budgetSection

                    // ── Goals ──
                    goalsSection

                    // ── Transactions ──
                    transactionsSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 25)
            }

            // FAB
            Button { showAddTx = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(blue, in: Circle())
                    .shadow(color: blue.opacity(0.5), radius: 12, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showAddTx)   { AddTransactionSheet(vm: vm) }
        .sheet(isPresented: $showAddGoal) { AddGoalSheet(vm: vm) }
        .sheet(item: $showBudgetEdit)     { cat in BudgetEditSheet(vm: vm, category: cat) }
    }

    // MARK: Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Финансы")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(vm.displayMonth)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                HStack(spacing: 10) {
                    Button { vm.prevMonth() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button { if !vm.isCurrentMonth { vm.nextMonth() } } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(vm.isCurrentMonth ? .white.opacity(0.2) : .white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: Balance Card
    private var balanceCard: some View {
        GlassSection {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Баланс месяца")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(fmt(vm.monthBalance))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(vm.monthBalance >= 0 ? .white : Color(red:1,green:0.3,blue:0.3))
                    if vm.monthIncome > 0 {
                        Text("Норма сбережений: \(Int(vm.savingsRate * 100))%")
                            .font(.system(size: 12))
                            .foregroundStyle(vm.savingsRate >= 0.2 ? Color.green : Color(red:1,green:0.6,blue:0))
                    }
                }

                HStack(spacing: 0) {
                    balancePill("Доходы", value: vm.monthIncome, icon: "arrow.down.circle.fill", color: .green)
                    Rectangle().fill(.white.opacity(0.1)).frame(width: 0.5, height: 36)
                    balancePill("Расходы", value: vm.monthExpense, icon: "arrow.up.circle.fill", color: Color(red:1,green:0.3,blue:0.3))
                    Rectangle().fill(.white.opacity(0.1)).frame(width: 0.5, height: 36)
                    balancePill("Инвест.", value: vm.monthInvest, icon: "chart.line.uptrend.xyaxis", color: Color(red:0.6,green:0.4,blue:1))
                }
            }
        }
    }

    @ViewBuilder
    private func balancePill(_ label: String, value: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
                Text(label).font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
            }
            Text(fmt(value))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 50/30/20 Card
    private var budgetRuleCard: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Правило 50 / 30 / 20")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("от дохода")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.35))
                }

                ruleBar(label: "Обязательные", pct: vm.mandatoryRatio(), target: 0.5,
                        amount: vm.mandatoryExp, color: Color(red:1,green:0.58,blue:0), ideal: "≤50%")
                ruleBar(label: "Желания", pct: vm.optionalRatio(), target: 0.3,
                        amount: vm.optionalExp, color: Color(red:0.35,green:0.34,blue:0.84), ideal: "≤30%")
                ruleBar(label: "Сбережения", pct: vm.investRatio(), target: 0.2,
                        amount: vm.investSavings, color: Color(red:0.2,green:0.78,blue:0.35), ideal: "≥20%")
            }
        }
    }

    @ViewBuilder
    private func ruleBar(label: String, pct: Double, target: Double, amount: Double, color: Color, ideal: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.system(size: 13)).foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(fmt(amount)).font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                Text("·").foregroundStyle(.white.opacity(0.3))
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(ideal)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(width: 36, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.08)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [color.opacity(0.9), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * pct, height: 6)
                    // target line
                    Rectangle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 1.5, height: 10)
                        .offset(x: geo.size.width * target - 0.75, y: -2)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: Chart Card
    private var chartCard: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 14) {
                Text("Доходы / Расходы за 6 месяцев")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                let bars   = vm.chartBars
                let maxVal = bars.map { max($0.income, $0.expense) }.max() ?? 1

                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(bars) { bar in
                            VStack(spacing: 4) {
                                HStack(alignment: .bottom, spacing: 2) {
                                    // Income bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red:0.2,green:0.78,blue:0.35).opacity(0.85))
                                        .frame(width: (geo.size.width / CGFloat(bars.count) - 16) / 2,
                                               height: maxVal > 0 ? CGFloat(bar.income / maxVal) * 100 : 2)
                                    // Expense bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red:1,green:0.3,blue:0.3).opacity(0.85))
                                        .frame(width: (geo.size.width / CGFloat(bars.count) - 16) / 2,
                                               height: maxVal > 0 ? CGFloat(bar.expense / maxVal) * 100 : 2)
                                }
                                Text(bar.label)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
                .frame(height: 120)

                HStack(spacing: 16) {
                    legendDot(color: Color(red:0.2,green:0.78,blue:0.35), label: "Доходы")
                    legendDot(color: Color(red:1,green:0.3,blue:0.3),     label: "Расходы")
                }
            }
        }
    }

    @ViewBuilder
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
        }
    }

    // MARK: Budget Categories
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Бюджет")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.leading, 2)

            // Mandatory
            VStack(alignment: .leading, spacing: 8) {
                Text("ОБЯЗАТЕЛЬНЫЕ")
                    .font(.system(size: 11, weight: .semibold)).kerning(0.5).textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.35)).padding(.leading, 4)

                VStack(spacing: 0) {
                    ForEach(vm.categories.filter { $0.isMandatory }.indices, id: \.self) { idx in
                        let cat = vm.categories.filter { $0.isMandatory }[idx]
                        BudgetCategoryRow(vm: vm, cat: cat, onEdit: { showBudgetEdit = cat })
                        if idx < vm.categories.filter({ $0.isMandatory }).count - 1 {
                            Divider().background(.white.opacity(0.06)).padding(.leading, 56)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
            }

            // Optional
            VStack(alignment: .leading, spacing: 8) {
                Text("ЖЕЛАНИЯ")
                    .font(.system(size: 11, weight: .semibold)).kerning(0.5).textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.35)).padding(.leading, 4)

                VStack(spacing: 0) {
                    ForEach(vm.categories.filter { !$0.isMandatory }.indices, id: \.self) { idx in
                        let cat = vm.categories.filter { !$0.isMandatory }[idx]
                        BudgetCategoryRow(vm: vm, cat: cat, onEdit: { showBudgetEdit = cat })
                        if idx < vm.categories.filter({ !$0.isMandatory }).count - 1 {
                            Divider().background(.white.opacity(0.06)).padding(.leading, 56)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
            }
        }
    }

    // MARK: Goals
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Цели")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button { showAddGoal = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red:0,green:0.48,blue:1))
                }
            }
            .padding(.leading, 2)

            if vm.goals.isEmpty {
                emptyState(icon: "target", text: "Добавьте цель — квартира, путешествие, фонд")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.goals) { goal in
                            GoalCard(goal: goal, onDelete: { vm.deleteGoal(goal) })
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    // MARK: Transactions
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Операции")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if vm.monthTx.count > 6 {
                    Button { showAllTx.toggle() } label: {
                        Text(showAllTx ? "Скрыть" : "Все (\(vm.monthTx.count))")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .padding(.leading, 2)

            let visible = showAllTx ? vm.monthTx : Array(vm.monthTx.prefix(6))

            if visible.isEmpty {
                emptyState(icon: "tray", text: "Нет операций за этот месяц")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { idx, tx in
                        FinTxRow(tx: tx, onDelete: { vm.delete(tx) })
                        if idx < visible.count - 1 {
                            Divider().background(.white.opacity(0.06)).padding(.leading, 56)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
            }
        }
    }

    @ViewBuilder
    private func emptyState(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.2))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.06), lineWidth: 0.5))
    }

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.groupingSeparator = " "
        f.locale = Locale(identifier: "ru_RU")
        return (f.string(from: NSNumber(value: v)) ?? "0") + " ₽"
    }
}

// MARK: - BudgetCategoryRow

private struct BudgetCategoryRow: View {
    @ObservedObject var vm: FinanceVM
    let cat: FinBudgetCategory
    let onEdit: () -> Void

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        f.groupingSeparator = " "; f.locale = Locale(identifier: "ru_RU")
        return (f.string(from: NSNumber(value: v)) ?? "0") + " ₽"
    }

    var body: some View {
        let spent   = vm.spent(for: cat)
        let budget  = cat.budget
        let pct     = budget > 0 ? min(spent / budget, 1) : 0
        let over    = budget > 0 && spent > budget

        Button { onEdit() } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cat.uiColor.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: cat.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(cat.uiColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cat.name)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                        Text(budget > 0 ? "\(fmt(spent)) / \(fmt(budget))" : "Бюджет не задан")
                            .font(.system(size: 11))
                            .foregroundStyle(over ? Color(red:1,green:0.3,blue:0.3) : .white.opacity(0.4))
                    }
                    Spacer()
                    if over {
                        Text("−\(fmt(spent - budget))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red:1,green:0.3,blue:0.3))
                    } else if budget > 0 {
                        Text("\(fmt(budget - spent))")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                if budget > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.white.opacity(0.06)).frame(height: 3)
                            Rectangle()
                                .fill(over ? Color(red:1,green:0.3,blue:0.3) : cat.uiColor)
                                .frame(width: geo.size.width * pct, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.leading, 64)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GoalCard

private struct GoalCard: View {
    let goal: FinGoal
    let onDelete: () -> Void

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        f.groupingSeparator = " "; f.locale = Locale(identifier: "ru_RU")
        return (f.string(from: NSNumber(value: v)) ?? "0") + " ₽"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(goal.uiColor.opacity(0.2)).frame(width: 36, height: 36)
                    Image(systemName: goal.icon).font(.system(size: 15)).foregroundStyle(goal.uiColor)
                }
                Spacer()
                Menu {
                    Button(role: .destructive) { onDelete() } label: { Label("Удалить", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis").foregroundStyle(.white.opacity(0.3)).font(.system(size: 14))
                }
            }
            Text(goal.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text("\(fmt(goal.currentAmount)) / \(fmt(goal.targetAmount))")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.08)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(goal.uiColor)
                        .frame(width: geo.size.width * goal.progress, height: 6)
                }
            }
            .frame(height: 6)
            Text("\(Int(goal.progress * 100))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(goal.uiColor)
            if let dl = goal.deadline {
                Text(dl.formatted(.dateTime.day().month(.abbreviated).year()))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(14)
        .frame(width: 160)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
        .edgeSheen(cornerRadius: 18)
    }
}

// MARK: - FinTxRow

private struct FinTxRow: View {
    let tx: FinTransaction
    let onDelete: () -> Void

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        f.groupingSeparator = " "; f.locale = Locale(identifier: "ru_RU")
        return (f.string(from: NSNumber(value: v)) ?? "0") + " ₽"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tx.type.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: tx.type.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(tx.type.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title.isEmpty ? tx.catName : tx.title)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                Text(tx.catName.isEmpty ? tx.type.rawValue : tx.catName)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(tx.type.sign + fmt(tx.amount))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tx.type == .income ? .green : tx.type.color)
                Text(tx.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: { Label("Удалить", systemImage: "trash") }
        }
    }
}

// MARK: - AddTransactionSheet

struct AddTransactionSheet: View {
    @ObservedObject var vm: FinanceVM
    @Environment(\.dismiss) private var dismiss

    @State private var title      = ""
    @State private var amountStr  = ""
    @State private var txType     : FinTxType = .expense
    @State private var catName    = ""
    @State private var date       = Date()
    @State private var note       = ""
    @State private var isRecurring = false

    private let blue = Color(red: 0, green: 0.48, blue: 1)

    // Income categories
    private let incomeCats = ["Зарплата","Аванс","Фриланс","Кешбек","Проценты / Инвест.","Возврат долга","Прочий доход"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Amount input
                    VStack(spacing: 8) {
                        Text("Сумма")
                            .font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                        HStack(alignment: .bottom, spacing: 4) {
                            TextField("0", text: $amountStr)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .frame(maxWidth: 200)
                            Text("₽")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.bottom, 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                    // Type picker
                    HStack(spacing: 8) {
                        ForEach(FinTxType.allCases, id: \.self) { t in
                            Button { txType = t } label: {
                                Text(t.rawValue)
                                    .font(.system(size: 13, weight: txType == t ? .semibold : .regular))
                                    .foregroundStyle(txType == t ? .white : .white.opacity(0.4))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(txType == t ? t.color.opacity(0.25) : .clear, in: Capsule())
                                    .overlay(Capsule().strokeBorder(txType == t ? t.color.opacity(0.5) : .white.opacity(0.1), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Fields
                    addSection {
                        addRow(label: "Название") {
                            TextField("Опционально", text: $title)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white)
                                .font(.system(size: 15))
                        }
                        addDivider
                        addRow(label: "Категория") {
                            let cats = txType == .income ? incomeCats : vm.categories.filter { $0.txType == txType || txType == .expense }.map { $0.name }
                            Menu {
                                ForEach(cats, id: \.self) { c in Button(c) { catName = c } }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(catName.isEmpty ? "Выбрать" : catName)
                                        .font(.system(size: 14))
                                        .foregroundStyle(catName.isEmpty ? .white.opacity(0.3) : .white.opacity(0.7))
                                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(.white.opacity(0.3))
                                }
                            }
                        }
                        addDivider
                        addRow(label: "Дата") {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                                .tint(blue)
                                .colorScheme(.dark)
                        }
                        addDivider
                        addRow(label: "Регулярный") {
                            Toggle("", isOn: $isRecurring).tint(blue).labelsHidden()
                        }
                    }

                    addSection {
                        addRow(label: "Заметка") {
                            TextField("Необязательно", text: $note)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white)
                                .font(.system(size: 15))
                        }
                    }

                    Button {
                        guard let amount = Double(amountStr.replacingOccurrences(of: ",", with: ".")) else { return }
                        var tx = FinTransaction()
                        tx.title       = title
                        tx.amount      = amount
                        tx.type        = txType
                        tx.catName     = catName
                        tx.date        = date
                        tx.note        = note
                        tx.isRecurring = isRecurring
                        vm.add(tx)
                        dismiss()
                    } label: {
                        Text("Добавить")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(blue, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(amountStr.isEmpty)
                    .opacity(amountStr.isEmpty ? 0.4 : 1)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("Новая операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    func addSection(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) { content() }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
    }

    @ViewBuilder
    func addRow(label: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Text(label).font(.system(size: 15)).foregroundStyle(.white)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }

    var addDivider: some View {
        Divider().background(.white.opacity(0.06)).padding(.leading, 16)
    }
}

// MARK: - AddGoalSheet

struct AddGoalSheet: View {
    @ObservedObject var vm: FinanceVM
    @Environment(\.dismiss) private var dismiss

    @State private var title         = ""
    @State private var targetStr     = ""
    @State private var currentStr    = ""
    @State private var hasDeadline   = false
    @State private var deadline      = Date()
    @State private var selectedIcon  = "target"
    @State private var selectedColor = "007AFF"

    private let blue  = Color(red: 0, green: 0.48, blue: 1)
    private let icons = ["target","house.fill","car.fill","airplane","graduationcap.fill","heart.fill","star.fill","gift.fill","dollarsign.circle.fill","briefcase.fill","fork.knife","gamecontroller.fill"]
    private let colors: [(String, Color)] = [
        ("007AFF", Color(red:0,green:0.48,blue:1)), ("34C759", Color(red:0.2,green:0.78,blue:0.35)),
        ("FF4040", Color(red:1,green:0.25,blue:0.25)), ("FF9500", Color(red:1,green:0.58,blue:0)),
        ("5856D6", Color(red:0.35,green:0.34,blue:0.84)), ("AF52DE", Color(red:0.69,green:0.32,blue:0.87)),
        ("FF2D55", Color(red:1,green:0.18,blue:0.33)), ("FFCC00", Color(red:1,green:0.8,blue:0))
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Icon + Color picker
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(colors.first(where: { $0.0 == selectedColor })?.1.opacity(0.2) ?? blue.opacity(0.2)).frame(width: 72, height: 72)
                            Image(systemName: selectedIcon).font(.system(size: 28)).foregroundStyle(colors.first(where: { $0.0 == selectedColor })?.1 ?? blue)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(icons, id: \.self) { ic in
                                    Button { selectedIcon = ic } label: {
                                        Image(systemName: ic).font(.system(size: 17))
                                            .foregroundStyle(selectedIcon == ic ? .white : .white.opacity(0.35))
                                            .frame(width: 42, height: 42)
                                            .background(selectedIcon == ic ? blue.opacity(0.3) : .white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        HStack(spacing: 10) {
                            ForEach(colors, id: \.0) { hex, col in
                                Button { selectedColor = hex } label: {
                                    Circle().fill(col)
                                        .frame(width: 30, height: 30)
                                        .overlay(Circle().strokeBorder(.white, lineWidth: selectedColor == hex ? 2 : 0))
                                        .scaleEffect(selectedColor == hex ? 1.15 : 1)
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(duration: 0.2), value: selectedColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Fields
                    addSect {
                        addR(label: "Название") { TextField("Квартира, машина…", text: $title).multilineTextAlignment(.trailing).foregroundStyle(.white) }
                        div
                        addR(label: "Цель") { TextField("0", text: $targetStr).multilineTextAlignment(.trailing).foregroundStyle(.white).keyboardType(.decimalPad) }
                        div
                        addR(label: "Уже накоплено") { TextField("0", text: $currentStr).multilineTextAlignment(.trailing).foregroundStyle(.white).keyboardType(.decimalPad) }
                        div
                        addR(label: "Дедлайн") { Toggle("", isOn: $hasDeadline).tint(blue).labelsHidden() }
                        if hasDeadline {
                            div
                            addR(label: "Дата") {
                                DatePicker("", selection: $deadline, displayedComponents: .date)
                                    .labelsHidden().tint(blue).colorScheme(.dark)
                            }
                        }
                    }

                    Button {
                        var g = FinGoal()
                        g.title         = title
                        g.targetAmount  = Double(targetStr.replacingOccurrences(of: ",", with: ".")) ?? 0
                        g.currentAmount = Double(currentStr.replacingOccurrences(of: ",", with: ".")) ?? 0
                        g.icon          = selectedIcon
                        g.colorHex      = selectedColor
                        g.deadline      = hasDeadline ? deadline : nil
                        vm.addGoal(g)
                        dismiss()
                    } label: {
                        Text("Добавить цель")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(blue, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(title.isEmpty || targetStr.isEmpty)
                    .opacity(title.isEmpty || targetStr.isEmpty ? 0.4 : 1)
                }
                .padding(.horizontal, 20).padding(.top, 8)
            }
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.1), in: Circle())
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder func addSect(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) { content() }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
    }
    @ViewBuilder func addR(label: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack { Text(label).font(.system(size: 15)).foregroundStyle(.white); Spacer(); trailing() }
            .padding(.horizontal, 16).padding(.vertical, 13)
    }
    var div: some View { Divider().background(.white.opacity(0.06)).padding(.leading, 16) }
}

// MARK: - BudgetEditSheet

struct BudgetEditSheet: View {
    @ObservedObject var vm: FinanceVM
    let category: FinBudgetCategory
    @Environment(\.dismiss) private var dismiss
    @State private var budgetStr = ""

    private let blue = Color(red: 0, green: 0.48, blue: 1)

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(category.uiColor.opacity(0.18)).frame(width: 64, height: 64)
                    Image(systemName: category.icon).font(.system(size: 26)).foregroundStyle(category.uiColor)
                }
                .padding(.top, 20)

                Text(category.name)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)

                VStack(spacing: 4) {
                    Text("Месячный бюджет").font(.system(size: 13)).foregroundStyle(.white.opacity(0.45))
                    HStack(alignment: .bottom, spacing: 4) {
                        TextField("0", text: $budgetStr)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 180)
                        Text("₽").font(.system(size: 26)).foregroundStyle(.white.opacity(0.4)).padding(.bottom, 5)
                    }
                }

                Button {
                    let val = Double(budgetStr.replacingOccurrences(of: ",", with: ".")) ?? 0
                    if let idx = vm.categories.firstIndex(where: { $0.id == category.id }) {
                        vm.categories[idx].budget = val
                    }
                    dismiss()
                } label: {
                    Text("Сохранить")
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(blue, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationTitle("Бюджет категории")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.1), in: Circle())
                    }.buttonStyle(.plain)
                }
            }
        }
        .onAppear { budgetStr = category.budget > 0 ? String(Int(category.budget)) : "" }
    }
}
