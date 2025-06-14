//
//  GluNetViewModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 14/06/2025.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class GluNetViewModel: ObservableObject {
  @Published var prediction: Float? = nil
  @Published var isLoading = false
  @Published var errorMessage: String? = nil

  private let db = Firestore.firestore()
  private let model = GluNetModel()
  private var listener: ListenerRegistration? = nil

  func start(uid: String) {
    print("[GluNetViewModel] start prediction for uid=\(uid)")
    prediction = nil
    errorMessage = nil
    isLoading = true

    // Fetch latest 16 glucose
    let glucoseRef = db.collection("users").document(uid)
      .collection("glucoseReadings")
      .order(by: "timestamp", descending: true)
      .limit(to: 16)
    // Fetch latest 16 meals for carbs
    let mealRef = db.collection("users").document(uid)
      .collection("meals")
      .order(by: "date", descending: true)
      .limit(to: 16)

    // Listen once for glucose then get meals
    glucoseRef.getDocuments { [weak self] snap, error in
      guard let self = self else { return }
      if let err = error {
        print("[GluNetViewModel] Glucose fetch error: \(err)")
        self.errorMessage = "Error loading data"
        self.isLoading = false
        return
      }
      let glucoseDocs = snap?.documents ?? []
      print("[GluNetViewModel] fetched \(glucoseDocs.count) glucose docs")
      if glucoseDocs.count < 16 {
        self.errorMessage = "Need 16 CGM readings to predict. Keep logging!"
        self.isLoading = false
        print("[GluNetViewModel] insufficient glucose, aborting")
        return
      }

      // Fetch meals for carbs
      mealRef.getDocuments { mealSnap, mealErr in
        if let mealErr = mealErr {
          print("[GluNetViewModel] Meal fetch error: \(mealErr)")
        }
        let mealDocs = mealSnap?.documents ?? []
        let carbValues = mealDocs.compactMap { doc -> Float? in
          guard let carbs = doc.data()["carbs"] as? Double else { return nil }
          return Float(carbs)
        }.reversed()
        print("[GluNetViewModel] fetched \(carbValues.count) meal carbs")
        // Pad or trim to 16
        var carbs16 = Array(carbValues)
        if carbs16.count < 16 {
            carbs16 += [Float](repeating: (carbValues.last ?? 0), count: 16 - carbs16.count)
        } else {
          carbs16 = Array(carbs16.prefix(16))
        }

        // Placeholder insulin: average human basal ~1.0 U/hr
        let insulin16 = [Float](repeating: 1.0, count: 16)

        // Prepare data arrays
        let readings = glucoseDocs.compactMap { doc -> (Float, Date)? in
          guard let ts = doc.data()["timestamp"] as? Timestamp,
                let v  = doc.data()["value"] as? Double else { return nil }
          return (Float(v), ts.dateValue())
        }.reversed()

        let glucose16 = readings.map { $0.0 }
        let times16 = readings.map { $0.1 }

        // Debug logs
        print("[GluNetViewModel] glucose16 = \(glucose16)\ncarbs16 = \(carbs16)\ninsulin16 = \(insulin16)\ntimes16 = \(times16)")
          
        // Run prediction off main
        Task.detached {
          print("[GluNetViewModel] running model...")
          let pred = self.model?.predict(
            glucose: glucose16,
            carbs: carbs16,
            insulin: insulin16,
            times: times16
          )
          await MainActor.run {
            self.prediction = pred
            self.isLoading = false
            print("[GluNetViewModel] prediction updated=\(String(describing: pred))")
          }
        }
      }
    }
  }

  func stop() {
    listener?.remove()
    print("[GluNetViewModel] stopped listening")
  }
}
