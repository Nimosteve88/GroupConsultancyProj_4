//
//  AuthService.swift
//  type2DProj
//
//  Created by Nimo, Steve on 22/05/2025.
//

import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestore

final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            self?.user = firebaseUser
            self?.isAuthenticated = (firebaseUser != nil)
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                let err = NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown signup error"])
                self?.errorMessage = err.localizedDescription
                completion(.failure(err))
                return
            }
            self?.errorMessage = nil
            completion(.success(user))
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                let err = NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown login error"])
                self?.errorMessage = err.localizedDescription
                completion(.failure(err))
                return
            }
            self?.errorMessage = nil
            completion(.success(user))
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
            } else {
                self?.errorMessage = nil
                completion(.success(()))
            }
        }
    }
}
