//
//  ChatViewModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 05/06/2025.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draftText: String = ""
    @Published var isSending: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private let uid: String

    init(uid: String) {
        self.uid = uid
        loadExistingHistory()
    }

    deinit {
        // If you add any listeners later, cancel them here.
    }

    // MARK: – Public Methods

    func sendMessage() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMsg = ChatMessage(text: text, sender: .user)
        appendLocallyAndFirestore(message: userMsg)

        draftText = ""

        Task {
            await queryAI(with: text, parentMessage: userMsg)
        }
    }

    /// Clears local messages and deletes the user’s entire Firestore chat‐history collection.
    func startNewChat() {
        // 1) Clear local copy immediately for UI responsiveness
        messages = []

        // 2) Delete all documents in users/{uid}/chathistory
        let chatColl = db
            .collection("users")
            .document(uid)
            .collection("chathistory")

        chatColl.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            if let err = error {
                print("Error fetching docs for deletion: \(err.localizedDescription)")
                return
            }

            snapshot?.documents.forEach { doc in
                chatColl.document(doc.documentID).delete { deleteError in
                    if let deleteError = deleteError {
                        print("Failed to delete \(doc.documentID): \(deleteError.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: – Private Helpers

    private func appendLocallyAndFirestore(message: ChatMessage) {
        messages.append(message)

        let chatRef = db
            .collection("users")
            .document(uid)
            .collection("chathistory")
            .document(message.id)

        chatRef.setData(message.firestoreData) { error in
            if let err = error {
                print("📕 Firestore write error: \(err.localizedDescription)")
            }
        }
    }

    private func loadExistingHistory() {
        let chatColl = db
            .collection("users")
            .document(uid)
            .collection("chathistory")
            .order(by: "timestamp", descending: false)

        chatColl.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            if let docs = snapshot?.documents {
                self.messages = docs.map { doc in
                    ChatMessage(id: doc.documentID, data: doc.data())
                }
            }
        }
    }

    private func queryAI(with userText: String, parentMessage: ChatMessage) async {
        isSending = true
        defer {
            Task { @MainActor in
                self.isSending = false
            }
        }

        guard let url = URL(string: "https://cgm-backend-depr.onrender.com/chat-contextual") else {
            print("Invalid Chat backend URL.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: String] = ["message": userText]
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            print("Encoding error: \(error)")
            return
        }

        do {
            let (data, resp) = try await URLSession.shared.data(for: request)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                print("Chat API returned HTTP error.")
                return
            }

            struct ReplyEnvelope: Codable {
                let reply: String
            }
            let envelope = try JSONDecoder().decode(ReplyEnvelope.self, from: data)
            let aiText = envelope.reply

            let aiMsg = ChatMessage(text: aiText, sender: .ai)
            appendLocallyAndFirestore(message: aiMsg)
        }
        catch {
            print("Network/decoding error: \(error)")
            let errorMsg = ChatMessage(text: "Error: \(error.localizedDescription)", sender: .ai)
            appendLocallyAndFirestore(message: errorMsg)
        }
    }
}

