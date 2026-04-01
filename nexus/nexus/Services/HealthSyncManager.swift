import Foundation
import HealthKit
import Combine

// MARK: - Health Sync Manager
// Синхронизирует данные HealthKit → Firestore каждый час

@MainActor
final class HealthSyncManager: ObservableObject {
    static let shared = HealthSyncManager()

    @Published var lastSyncTime: Date?
    @Published var isSyncing = false

    private let healthStore = HKHealthStore()
    private let firebase = FirebaseService.shared
    private let authManager = AuthenticationManager.shared
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 3600 // 1 час

    private init() {}

    // MARK: - HealthKit Types

    private var readTypes: Set<HKObjectType> {
        [
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
    }

    // MARK: - Start / Stop

    func startPeriodicSync() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        requestPermissions { [weak self] success in
            guard success else { return }
            Task { @MainActor in
                self?.performSync()
                self?.startTimer()
            }
        }
    }

    func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    private func startTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performSync()
            }
        }
    }

    // MARK: - Permissions

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, _ in
            completion(success)
        }
    }

    // MARK: - Sync

    func performSync() {
        guard !isSyncing else { return }
        guard let userId = authManager.currentUserId else { return }

        isSyncing = true

        Task {
            do {
                let entry = try await fetchTodayHealthData()

                // Сохраняем в Firestore
                try await firebase.healthRepo.saveEntry(entry, userId: userId)

                // Также сохраняем недельные данные
                let weekEntries = try await fetchWeeklyHealthData()
                try await firebase.healthRepo.saveBatch(weekEntries, userId: userId)

                self.lastSyncTime = Date()
            } catch {
                print("[HealthSync] Error: \(error.localizedDescription)")
            }
            self.isSyncing = false
        }
    }

    // MARK: - Fetch Today's Data

    private func fetchTodayHealthData() async throws -> HealthEntry {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Date()

        async let steps = fetchSum(.stepCount, unit: .count(), start: start, end: end)
        async let calories = fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        async let water = fetchSum(.dietaryWater, unit: .literUnit(with: .milli), start: start, end: end)
        async let _ = fetchSum(.appleExerciseTime, unit: .minute(), start: start, end: end)
        async let heartRate = fetchHeartRateStats(start: start, end: end)
        async let weight = fetchLatest(.bodyMass, unit: .gramUnit(with: .kilo))
        async let bpSys = fetchLatest(.bloodPressureSystolic, unit: .millimeterOfMercury())
        async let bpDia = fetchLatest(.bloodPressureDiastolic, unit: .millimeterOfMercury())
        async let oxygen = fetchLatest(.oxygenSaturation, unit: .percent())

        let hr = try await heartRate

        let entry = HealthEntry(
            date: start,
            steps: Int(try await steps),
            caloriesBurned: try await calories,
            sleepHours: 0, // будет заполнен ниже
            heartRateAvg: hr.avg,
            heartRateMin: hr.min,
            heartRateMax: hr.max,
            waterMl: try await water,
            source: "Apple Health"
        )
        entry.weight = try await weight
        entry.bloodPressureSystolic = intOrNil(try await bpSys)
        entry.bloodPressureDiastolic = intOrNil(try await bpDia)
        entry.oxygenSaturation = try await oxygen

        return entry
    }

    // MARK: - Fetch Weekly Data

    private func fetchWeeklyHealthData() async throws -> [HealthEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var entries: [HealthEntry] = []

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) ?? day

            let steps = (try? await fetchSum(.stepCount, unit: .count(), start: day, end: dayEnd)) ?? 0
            let calories = (try? await fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: day, end: dayEnd)) ?? 0

            let entry = HealthEntry(
                date: day,
                steps: Int(steps),
                caloriesBurned: calories,
                source: "Apple Health"
            )
            entries.append(entry)
        }

        return entries
    }

    // MARK: - HealthKit Query Helpers

    private func fetchSum(_ type: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let quantityType = HKQuantityType(type)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error { continuation.resume(throwing: error); return }
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchHeartRateStats(start: Date, end: Date) async throws -> (avg: Int, min: Int, max: Int) {
        try await withCheckedThrowingContinuation { continuation in
            let type = HKQuantityType(.heartRate)
            let unit = HKUnit.count().unitDivided(by: .minute())
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: [.discreteAverage, .discreteMin, .discreteMax]) { _, stats, error in
                if let error { continuation.resume(throwing: error); return }
                let avg = Int(stats?.averageQuantity()?.doubleValue(for: unit) ?? 0)
                let min = Int(stats?.minimumQuantity()?.doubleValue(for: unit) ?? 0)
                let max = Int(stats?.maximumQuantity()?.doubleValue(for: unit) ?? 0)
                continuation.resume(returning: (avg, min, max))
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatest(_ type: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        try await withCheckedThrowingContinuation { continuation in
            let quantityType = HKQuantityType(type)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func intOrNil(_ value: Double?) -> Int? {
        guard let value else { return nil }
        return Int(value)
    }
}
