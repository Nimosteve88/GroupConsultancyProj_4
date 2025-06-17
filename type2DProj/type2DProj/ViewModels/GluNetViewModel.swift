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

    // Fetch latest 16 glucose readings (in mg/dL)
    let glucoseRef = db.collection("users").document(uid)
      .collection("glucoseReadings")
      .order(by: "timestamp", descending: true)
      .limit(to: 16)

    // Listen once for glucose (we won't use meals for this scenario)
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

      // Prepare data arrays - fasting scenario
      let readings = glucoseDocs.compactMap { doc -> (Float, Date)? in
        guard let ts = doc.data()["timestamp"] as? Timestamp,
              let v  = doc.data()["value"] as? Double else { return nil }
        return (Float(v), ts.dateValue())
      }.reversed()

      let glucose16 = readings.map { $0.0 }  // mg/dL values
      let times16 = readings.map { $0.1 }    // Timestamps
      
      // Fasting scenario: zero carbs and zero insulin
      let carb16 = [Float](repeating: 0.0, count: 16)    // grams
      let insulin16 = [Float](repeating: 0.0, count: 16) // arbitrary units

      // Debug logs
      print("""
      [GluNetViewModel] Running fasting scenario:
      - glucose16 (mg/dL): \(glucose16.prefix(5))...
      - carb16 (grams): \(carb16.prefix(5))...
      - insulin16 (units): \(insulin16.prefix(5))...
      - times16: \(times16.prefix(5).map { $0.description })...
      """)
        
        print("[GluNetViewModel] Fasting Scenario Detailed Data:")
        for i in 0..<16 {
            let row = "Row \(i + 1): Glucose: \(glucose16[i]), Carbs: \(carb16[i]), Insulin: \(insulin16[i]), Time: \(times16[i].description)"
            print(row)
        }

      // Run prediction off main
      Task.detached {
        print("[GluNetViewModel] running model...")
        let pred = self.model?.predict(
          glucose: glucose16,
          carbs: carb16,
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

  func stop() {
    listener?.remove()
    print("[GluNetViewModel] stopped listening")
  }
}
