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
  private let apiService = GluNetAPIService() // New API service
  private var listener: ListenerRegistration? = nil

  func start(uid: String) {
    print("[GluNetViewModel] start prediction for uid=\(uid)")
    prediction = nil
    errorMessage = nil
    isLoading = true

    let glucoseRef = db.collection("users").document(uid)
      .collection("glucoseReadings")
      .order(by: "timestamp", descending: true)
      .limit(to: 16)

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
        return
      }

      let readings = glucoseDocs.compactMap { doc -> (Float, Date)? in
        guard let ts = doc.data()["timestamp"] as? Timestamp,
              let v = doc.data()["value"] as? Double else { return nil }
        return (Float(v), ts.dateValue())
      }.reversed()

      let glucose16 = readings.map { $0.0 }
      let times16 = readings.map { $0.1 }
      
      // Prepare API input
      Task {
        do {
          let prediction = try await self.apiService.predict(
            glucose: glucose16,
            carbs: [Float](repeating: 0.0, count: 16),
            insulin: [Float](repeating: 0.0, count: 16),
            times: times16
          )
          self.prediction = prediction
          print("[GluNetViewModel] API prediction success: \(prediction)")
        } catch {
          print("[GluNetViewModel] API prediction error: \(error)")
          self.errorMessage = "Prediction service unavailable"
        }
        self.isLoading = false
      }
    }
  }

  func stop() {
    listener?.remove()
  }
}
