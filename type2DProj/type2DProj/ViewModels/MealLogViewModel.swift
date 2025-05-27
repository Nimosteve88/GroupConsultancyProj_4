//
//  MealLogViewModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import Foundation
import FirebaseFirestore
import Combine

/// ViewModel to sync Meal logs with Firestore under users/{uid}/meals
final class MealLogViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
        // Start listening once we have a userId
        session.$userId
            .compactMap { $0 }
            .sink { [weak self] uid in self?.startListener(uid: uid) }
            .store(in: &cancellables)
    }

    private func startListener(uid: String) {
        // Remove previous listener if any
        listener?.remove()
        listener = db.collection("users").document(uid)
            .collection("meals")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self?.meals = docs.compactMap { doc in
                    let data = doc.data()
                    return Meal(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        name: data["name"] as? String ?? "",
                        carbs: data["carbs"] as? Double ?? 0,
                        protein: data["protein"] as? Double ?? 0,
                        fat: data["fat"] as? Double ?? 0,
                        fiber: data["fiber"] as? Double ?? 0,
                        calories: (data["fat"] as? Double ?? 0) * 9 +
                                (data["carbs"] as? Double ?? 0) * 4 +
                                (data["protein"] as? Double ?? 0) * 4,
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        imageName: data["imageName"] as? String
                    )
                }
            }
    }

    /// Add a new meal document (uses meal.id.uuidString as docID)
    func add(_ meal: Meal) {
        guard let uid = session.userId else { return }
        let docRef = db.collection("users").document(uid)
                        .collection("meals").document(meal.id.uuidString)
        docRef.setData([
            "name": meal.name,
            "carbs": meal.carbs,
            "protein": meal.protein,
            "fat": meal.fat,
            "fiber": meal.fiber,
            "calories": meal.calories,
            "date": Timestamp(date: meal.date),
            "imageName": meal.imageName as Any
        ], merge: true)
    }

    /// Remove a meal document
    func remove(_ meal: Meal) {
        guard let uid = session.userId else { return }
        db.collection("users").document(uid)
            .collection("meals")
            .document(meal.id.uuidString)
            .delete()
    }

    /// Update an existing meal
    func update(_ meal: Meal) {
        add(meal)  // merge update
    }
}

