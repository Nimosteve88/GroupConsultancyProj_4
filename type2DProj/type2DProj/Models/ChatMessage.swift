//
//  ChatMessage.swift
//  type2DProj
//
//  Created by Nimo, Steve on 05/06/2025.
//

import Foundation
import FirebaseFirestore

enum ChatSender: String, Codable {
    case user
    case ai
}

/// A single chat message in our UI and in Firestore.
struct ChatMessage: Identifiable, Codable {
    let id: String               // Firestore document ID or UUID if you want local
    let text: String             // The message text
    let timestamp: Date          // When it was sent/received
    let sender: ChatSender       // user vs. ai

    // Provide a Firestore dictionary to write:
    var firestoreData: [String: Any] {
        return [
            "text": text,
            "timestamp": Timestamp(date: timestamp),
            "sender": sender.rawValue
        ]
    }

    /// Firestore-friendly initializer:
    init(id: String, data: [String: Any]) {
        self.id = id
        self.text = data["text"] as? String ?? ""
        if let ts = data["timestamp"] as? Timestamp {
            self.timestamp = ts.dateValue()
        } else {
            self.timestamp = Date()
        }
        if let raw = data["sender"] as? String, let s = ChatSender(rawValue: raw) {
            self.sender = s
        } else {
            self.sender = .ai
        }
    }

    /// Create a new user‐sent message
    init(text: String, sender: ChatSender) {
        self.id = UUID().uuidString
        self.text = text
        self.timestamp = Date()
        self.sender = sender
    }
}
