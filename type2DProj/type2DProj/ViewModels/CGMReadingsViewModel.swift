//
//  CGMReadingsViewModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 09/06/2025.
//

import Foundation
import FirebaseFirestore
import Combine

struct FirestoreGlucoseReading: Identifiable {
    let id: String
    let value: Double
    let timestamp: Date
}

final class CGMReadingsViewModel: ObservableObject {
    @Published var readings: [FirestoreGlucoseReading] = []
    @Published var currentCGMConfig: (sn: String, peripheralID: UUID)? = nil

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func startListening(uid: String) {
        let cfgRef = db.collection("users").document(uid)
            .collection("cgmConfig").document("info")
        cfgRef.getDocument { snap, _ in
            guard let data = snap?.data(),
                  let sn = data["sn"] as? String,
                  let rawID = data["peripheralID"] as? String,
                  let uuid = UUID(uuidString: rawID)
            else { return }
            DispatchQueue.main.async {
                self.currentCGMConfig = (sn, uuid)
            }
        }

        let readingsRef = db.collection("users").document(uid)
            .collection("glucoseReadings")
            .order(by: "timestamp", descending: false)
        listener = readingsRef.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            let arr = docs.compactMap { doc -> FirestoreGlucoseReading? in
                let data = doc.data()
                guard let ts = data["timestamp"] as? Timestamp,
                      let val = data["value"] as? Double
                else { return nil }
                return FirestoreGlucoseReading(
                    id: doc.documentID,
                    value: val,
                    timestamp: ts.dateValue()
                )
            }
            DispatchQueue.main.async {
                self.readings = arr
            }
        }
    }

    func stopListening() {
        listener?.remove()
    }
}
