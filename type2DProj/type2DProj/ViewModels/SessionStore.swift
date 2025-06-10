//
//  SessionStore.swift
//  type2DProj
//
//  Created by Nimo, Steve on 22/05/2025.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userId: String? = nil
    @Published var userEmail: String? = nil
    @Published var needsProfileSetup: Bool = false
    @Published var needsCGMPairing: Bool = false
    @Published var errorMessage: String? = nil

    private var authHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isLoggedIn = (user != nil)
            self.userId = user?.uid
            self.userEmail = user?.email
            if let uid = user?.uid {
                self.checkProfileSetup(uid: uid)
            } else {
                self.needsProfileSetup = false
                self.needsCGMPairing = false
            }
        }
    }

    private func checkProfileSetup(uid: String) {
        let profileRef = db.collection("users").document(uid)
            .collection("profileinfo").document("info")
        profileRef.getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            let exists = (snap?.exists == true)
            DispatchQueue.main.async {
                self.needsProfileSetup = !exists
                if exists {
                    let cfgRef = self.db.collection("users").document(uid)
                        .collection("cgmConfig").document("info")
                    cfgRef.getDocument { cfgSnap, _ in
                        let hasCGM = (cfgSnap?.exists == true)
                        DispatchQueue.main.async {
                            self.needsCGMPairing = !hasCGM
                        }
                    }
                } else {
                    self.needsCGMPairing = false
                }
            }
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let user = result?.user {
                completion(.success(user))
            } else if let error = error {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let user = result?.user {
                completion(.success(user))
            } else if let error = error {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            }
            completion(error)
        }
    }
}
