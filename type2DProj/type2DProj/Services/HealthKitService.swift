//
//  HealthKitService.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import Foundation
import HealthKit
import Combine

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()

    @Published var glucoseSamples: [GlucoseSample] = []

    private init() {}

    func requestAuthorization() {
            guard HKHealthStore.isHealthDataAvailable() else { return }
            let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
            healthStore.requestAuthorization(toShare: [], read: [glucoseType]) { success, error in
                if success { self.startGlucoseQuery() }
            }
        }

    private func startGlucoseQuery() {
        let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .hour, value: -8, to: Date()), end: Date(), options: .strictEndDate)
        _ = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKAnchoredObjectQuery(
            type: glucoseType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: { [weak self] (_, samplesOrNil, _, _, error) in
                guard let samples = samplesOrNil as? [HKQuantitySample], error == nil else {
                    print("Glucose fetch error: \(String(describing: error))")
                    return
                }
                DispatchQueue.main.async {
                    let mmolPerLUnit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
                    self?.glucoseSamples = samples.map { sample in
                        GlucoseSample(time: sample.startDate,
                                      value: sample.quantity.doubleValue(for: mmolPerLUnit))
                    }
                }
            }
        )

        healthStore.execute(query)
    }
}
