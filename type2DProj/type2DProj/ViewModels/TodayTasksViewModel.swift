//
//  TodayTasksViewModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 27/05/2025.
//

import Foundation
import FirebaseFirestore
import Combine

/// A simple task model for today’s to-dos
struct TodayTasksViewModelTask: Identifiable {
    var id: String  // Firestore document ID
    var time: Date
    var title: String
    var done: Bool = false
}

/// ViewModel to sync TodayTask list with Firestore under users/{uid}/todaytasks
final class TodayTasksViewModel: ObservableObject {
    @Published var tasks: [TodayTasksViewModelTask] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
        session.$userId
            .compactMap { $0 }
            .sink { [weak self] uid in self?.startListener(uid: uid) }
            .store(in: &cancellables)
    }

    private func startListener(uid: String) {
        listener?.remove()
        listener = db.collection("users").document(uid)
            .collection("todaytasks")
            .order(by: "time")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self?.tasks = docs.map { doc in
                    let data = doc.data()
                    let timestamp = data["time"] as? Timestamp
                    return TodayTasksViewModelTask(
                        id: doc.documentID,
                        time: timestamp?.dateValue() ?? Date(),
                        title: data["title"] as? String ?? "",
                        done: data["done"] as? Bool ?? false
                    )
                }
            }
    }

    /// Add a new task
    func add(_ task: TodayTasksViewModelTask) {
        guard let uid = session.userId else { return }
        let docRef = db.collection("users").document(uid)
            .collection("todaytasks").document()
        docRef.setData([
            "time": Timestamp(date: task.time),
            "title": task.title,
            "done": task.done
        ])
    }

    /// Update a task’s `done` state or content
    func update(_ task: TodayTasksViewModelTask) {
        guard let uid = session.userId else { return }
        db.collection("users").document(uid)
            .collection("todaytasks")
            .document(task.id)
            .updateData([
                "time": Timestamp(date: task.time),
                "title": task.title,
                "done": task.done
            ])
    }

    /// Remove a task
    func remove(_ task: TodayTasksViewModelTask) {
        guard let uid = session.userId else { return }
        db.collection("users").document(uid)
            .collection("todaytasks")
            .document(task.id)
            .delete()
    }
}
