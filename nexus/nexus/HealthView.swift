import SwiftUI
import HealthKit
import Combine

struct HealthView: View {
    @StateObject private var vm = HealthViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                metricsGrid
                heartRateCard
                sleepCard

                // Новые карточки
                if vm.weight != nil || vm.bloodPressureSystolic != nil || vm.oxygenSaturation != nil {
                    additionalMetricsSection
                }

                weeklyStepsCard
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .onAppear { vm.startListening() }
        .onDisappear { vm.stopListening() }
    }

    // MARK: - Sections

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Здоровье")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            HStack(spacing: 8) {
                if vm.isSyncing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
                Button {
                    vm.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
    }

    var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HealthMetricCard(
                icon: "figure.walk",
                iconColor: Color(red: 0.3, green: 0.7, blue: 1.0),
                title: "Шаги",
                value: vm.steps.formatted(),
                subtitle: "Цель: 10 000",
                progress: min(Double(vm.steps) / 10000, 1.0)
            )
            HealthMetricCard(
                icon: "flame.fill",
                iconColor: .orange,
                title: "Калории",
                value: "\(Int(vm.calories))",
                subtitle: "ккал сожжено",
                progress: min(vm.calories / 600, 1.0)
            )
            HealthMetricCard(
                icon: "drop.fill",
                iconColor: Color(red: 0.2, green: 0.6, blue: 1.0),
                title: "Вода",
                value: "\(Int(vm.waterMl)) мл",
                subtitle: "Цель: 2 000 мл",
                progress: min(vm.waterMl / 2000, 1.0)
            )
            HealthMetricCard(
                icon: "bolt.fill",
                iconColor: .yellow,
                title: "Активность",
                value: "\(vm.activeMinutes) мин",
                subtitle: "Цель: 30 мин",
                progress: min(Double(vm.activeMinutes) / 30, 1.0)
            )
        }
    }

    var heartRateCard: some View {
        GlassSection {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Пульс", systemImage: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.pink.opacity(0.8))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(vm.heartRateAvg)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("уд/мин")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Text("Мин \(vm.heartRateMin) · Макс \(vm.heartRateMax)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 50))
                    .foregroundStyle(.pink.opacity(0.4))
            }
        }
    }

    var sleepCard: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 12) {
                Label("Сон", systemImage: "moon.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 1.0))

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", vm.sleepHours))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("ч")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text(vm.sleepHours >= 7 ? "Отлично" : vm.sleepHours >= 6 ? "Норма" : "Мало")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(vm.sleepHours >= 7 ? .green : vm.sleepHours >= 6 ? .yellow : .red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (vm.sleepHours >= 7 ? Color.green : vm.sleepHours >= 6 ? Color.yellow : Color.red).opacity(0.15),
                            in: Capsule()
                        )
                }

                HStack(spacing: 3) {
                    ForEach(0..<8) { i in
                        let h = [0.3, 0.6, 0.9, 0.7, 0.5, 0.8, 0.6, 0.4][i]
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.5, green: 0.4, blue: 1.0).opacity(h))
                            .frame(maxWidth: .infinity)
                            .frame(height: 28 * h)
                    }
                }
                .frame(height: 28)
            }
        }
    }

    // MARK: - Additional Metrics (Blood Pressure, Oxygen, Weight)

    var additionalMetricsSection: some View {
        VStack(spacing: 12) {
            if let weight = vm.weight {
                GlassSection {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Вес", systemImage: "scalemass.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.cyan.opacity(0.8))
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", weight))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("кг")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        Spacer()
                    }
                }
            }

            HStack(spacing: 12) {
                if let sys = vm.bloodPressureSystolic, let dia = vm.bloodPressureDiastolic {
                    GlassSection {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Давление", systemImage: "heart.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.7))
                            Text("\(sys)/\(dia)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("мм рт.ст.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }

                if let oxygen = vm.oxygenSaturation {
                    GlassSection {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Кислород", systemImage: "lungs.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.blue.opacity(0.7))
                            Text("\(Int(oxygen * 100))%")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("SpO2")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
            }
        }
    }

    var weeklyStepsCard: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 12) {
                Text("Шаги за неделю")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(vm.weeklySteps.enumerated()), id: \.0) { idx, steps in
                        let maxSteps = vm.weeklySteps.max() ?? 1
                        let height = max(6, CGFloat(steps) / CGFloat(maxSteps) * 80)
                        let isToday = idx == vm.weeklySteps.count - 1

                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isToday
                                    ? LinearGradient(colors: [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.9)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)

                            Text(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"][idx])
                                .font(.system(size: 10))
                                .foregroundStyle(isToday ? .white : .white.opacity(0.3))
                        }
                    }
                }
                .frame(height: 100)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class HealthViewModel: ObservableObject {
    @Published var steps: Int = 0
    @Published var calories: Double = 0
    @Published var sleepHours: Double = 0
    @Published var heartRateAvg: Int = 0
    @Published var heartRateMin: Int = 0
    @Published var heartRateMax: Int = 0
    @Published var waterMl: Double = 0
    @Published var activeMinutes: Int = 0
    @Published var weeklySteps: [Int] = Array(repeating: 0, count: 7)
    @Published var weight: Double?
    @Published var bloodPressureSystolic: Int?
    @Published var bloodPressureDiastolic: Int?
    @Published var oxygenSaturation: Double?
    @Published var isLoading = false
    @Published var isSyncing = false

    private let healthStore = HKHealthStore()
    private let firebase = FirebaseService.shared
    private let authManager = AuthenticationManager.shared
    private let syncManager = HealthSyncManager.shared
    private var listenerTask: Task<Void, Never>?

    // MARK: - Start / Stop Listening

    func startListening() {
        fetchFromHealthKit()
        startFirebaseListener()
        syncManager.startPeriodicSync()
    }

    func stopListening() {
        listenerTask?.cancel()
        listenerTask = nil
    }

    func refresh() {
        fetchFromHealthKit()
        syncManager.performSync()
    }

    // MARK: - Firebase Real-time Listener

    private func startFirebaseListener() {
        guard let userId = authManager.currentUserId else { return }

        listenerTask = Task {
            for await entries in firebase.healthRepo.listenToEntries(userId: userId, days: 7) {
                guard !Task.isCancelled else { break }
                if let today = entries.first {
                    updateFromEntry(today)
                }
                updateWeeklySteps(from: entries)
            }
        }
    }

    private func updateFromEntry(_ entry: HealthEntry) {
        if entry.steps > 0 { steps = entry.steps }
        if entry.caloriesBurned > 0 { calories = entry.caloriesBurned }
        if entry.sleepHours > 0 { sleepHours = entry.sleepHours }
        if entry.heartRateAvg > 0 { heartRateAvg = entry.heartRateAvg }
        if entry.heartRateMin > 0 { heartRateMin = entry.heartRateMin }
        if entry.heartRateMax > 0 { heartRateMax = entry.heartRateMax }
        if entry.waterMl > 0 { waterMl = entry.waterMl }
        weight = entry.weight
        bloodPressureSystolic = entry.bloodPressureSystolic
        bloodPressureDiastolic = entry.bloodPressureDiastolic
        oxygenSaturation = entry.oxygenSaturation
    }

    private func updateWeeklySteps(from entries: [HealthEntry]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var stepsArray = Array(repeating: 0, count: 7)

        for entry in entries {
            let dayDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: entry.date), to: today).day ?? 0
            let index = 6 - dayDiff
            if index >= 0 && index < 7 {
                stepsArray[index] = entry.steps
            }
        }
        weeklySteps = stepsArray
    }

    // MARK: - HealthKit Direct Fetch (for immediate display)

    private func fetchFromHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            loadMockData()
            return
        }
        requestPermissions()
    }

    private func requestPermissions() {
        let types: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKQuantityType(.dietaryWater),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.bodyMass),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.oxygenSaturation),
            HKCategoryType(.sleepAnalysis)
        ]

        healthStore.requestAuthorization(toShare: [], read: types) { [weak self] success, _ in
            if success {
                DispatchQueue.main.async {
                    self?.fetchSteps()
                    self?.fetchCalories()
                    self?.fetchHeartRate()
                    self?.fetchSleep()
                    self?.fetchWeeklySteps()
                }
            } else {
                DispatchQueue.main.async { self?.loadMockData() }
            }
        }
    }

    private func fetchSteps() {
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, _ in
            DispatchQueue.main.async {
                self?.steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
        }
        healthStore.execute(query)
    }

    private func fetchCalories() {
        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, _ in
            DispatchQueue.main.async {
                self?.calories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }
        healthStore.execute(query)
    }

    private func fetchHeartRate() {
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: [.discreteAverage, .discreteMin, .discreteMax]) { [weak self] _, stats, _ in
            let unit = HKUnit.count().unitDivided(by: .minute())
            DispatchQueue.main.async {
                self?.heartRateAvg = Int(stats?.averageQuantity()?.doubleValue(for: unit) ?? 0)
                self?.heartRateMin = Int(stats?.minimumQuantity()?.doubleValue(for: unit) ?? 0)
                self?.heartRateMax = Int(stats?.maximumQuantity()?.doubleValue(for: unit) ?? 0)
            }
        }
        healthStore.execute(query)
    }

    private func fetchSleep() {
        loadMockSleep()
    }

    private func fetchWeeklySteps() {
        let type = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: end))!

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end),
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: interval
        )

        query.initialResultsHandler = { [weak self] _, results, _ in
            var steps = Array(repeating: 0, count: 7)
            results?.enumerateStatistics(from: start, to: end) { stats, _ in
                let idx = calendar.dateComponents([.day], from: start, to: stats.startDate).day ?? 0
                if idx < 7 {
                    steps[idx] = Int(stats.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                }
            }
            DispatchQueue.main.async { self?.weeklySteps = steps }
        }
        healthStore.execute(query)
    }

    private func loadMockData() {
        steps = 8420
        calories = 324
        sleepHours = 7.2
        heartRateAvg = 68
        heartRateMin = 54
        heartRateMax = 112
        waterMl = 1400
        activeMinutes = 42
        weeklySteps = [6200, 8100, 5400, 9300, 7800, 8420, 3100]
        weight = 72.5
        bloodPressureSystolic = 120
        bloodPressureDiastolic = 80
        oxygenSaturation = 0.98
    }

    private func loadMockSleep() {
        sleepHours = 7.2
    }
}

// MARK: - Supporting Views

struct HealthMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.1))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(iconColor.opacity(0.8))
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
        .edgeSheen(cornerRadius: 18)
    }
}

struct GlassSection<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
            .edgeSheen(cornerRadius: 20)
    }
}
