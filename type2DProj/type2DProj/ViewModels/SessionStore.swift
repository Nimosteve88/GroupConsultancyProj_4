//
//  SessionStore.swift
//  type2DProj
//
//  Created by Nimo, Steve on 22/05/2025.
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class SessionStore: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userEmail: String = ""
    @Published var authError: String?
    @Published var needsProfileSetup = false
    @Published var userId: String? = nil  // Exposed for views to get UID

    let authService = AuthService.shared
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    init() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loggedIn in
                guard let self = self else { return }
                self.isLoggedIn = loggedIn
                // Capture UID on auth state change
                self.userId = self.authService.user?.uid
                if loggedIn {
                    self.checkProfileInfo()
                } else {
                    self.needsProfileSetup = false
                }
            }
            .store(in: &cancellables)

        authService.$user
            .compactMap { $0?.email }
            .receive(on: DispatchQueue.main)
            .assign(to: \.userEmail, on: self)
            .store(in: &cancellables)

        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.authError, on: self)
            .store(in: &cancellables)
    }

    private func checkProfileInfo() {
        guard let uid = authService.user?.uid else { return }
        let docRef = db.collection("users").document(uid)
            .collection("profileinfo").document("info")
        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let data = snapshot?.data(), !data.isEmpty {
                    self.needsProfileSetup = false
                } else {
                    self.needsProfileSetup = true
                }
            }
        }
    }

    // Expose auth actions
    func signIn(email: String, password: String) {
        authService.signIn(email: email, password: password) { _ in }
    }
    func signUp(email: String, password: String) {
        authService.signUp(email: email, password: password) { _ in }
    }
    func signOut() {
        authService.signOut()
    }
    func resetPassword(email: String) {
        authService.resetPassword(email: email) { _ in }
    }
}
