//
//  ProfileSetupViewModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 24/05/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

final class ProfileSetupViewModel: ObservableObject {
    @Published var age = ""
    @Published var sex: Sex = .preferNot
    @Published var insulin = false
    @Published var history = false
    @Published var kidneyDisease = false
    @Published var diabetesType: DiabetesType = .notSure
    @Published var mealPreference: MealPreference = .balanced
    @Published var consentDataUse = false
    @Published var agreeTerms = false
    @Published var receiveAdvice = true
    // Removed @ObservedObject wrapper
    var cgmService = CGMService(session: SessionStore())
    
    enum Sex: String, CaseIterable {
        case male = "Male", female = "Female", other = "Other", preferNot = "Prefer not to say"
    }
    enum DiabetesType: String, CaseIterable {
        case typeI = "Type I", typeII = "Type II", prediabetes = "Prediabetes", notSure = "Not sure"
    }
    enum MealPreference: String, CaseIterable {
        case highCarb = "High Carb", lowCarb = "Low Carb", balanced = "Balanced", other = "Other"
    }
    
    var isFormValid: Bool {
        !age.isEmpty && Int(age) != nil && agreeTerms && Auth.auth().currentUser != nil
    }
    
    private let db = Firestore.firestore()
    fileprivate var sessionStore: SessionStore?
    
    func saveProfile(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "age": Int(age) ?? 0,
            "sex": sex.rawValue,
            "clinical": [
                "insulin": insulin,
                "diabetesHistory": history,
                "kidneyDisease": kidneyDisease
            ],
            "diabetesType": diabetesType.rawValue,
            "mealPreference": mealPreference.rawValue,
            "consentDataUse": consentDataUse,
            "agreeTerms": agreeTerms,
            "receiveAdvice": receiveAdvice,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        db.collection("users").document(uid)
          .collection("profileinfo").document("info")
          .setData(data, merge: true) { error in
            if let e = error { completion(.failure(e)) } else { completion(.success(())) }
        }
    }
    
    func loadExistingProfile(uid: String) {
        let docRef = db.collection("users").document(uid)
            .collection("profileinfo").document("info")
        docRef.getDocument { [weak self] snap, _ in
            guard let data = snap?.data(), let self = self else { return }
            DispatchQueue.main.async {
                if let ageVal = data["age"] as? Int { self.age = String(ageVal) }
                if let sexVal = data["sex"] as? String, let s = Sex(rawValue: sexVal) { self.sex = s }
                if let clinical = data["clinical"] as? [String:Any] {
                    self.insulin = clinical["insulin"] as? Bool ?? false
                    self.history = clinical["diabetesHistory"] as? Bool ?? false
                    self.kidneyDisease = clinical["kidneyDisease"] as? Bool ?? false
                }
                if let typeVal = data["diabetesType"] as? String, let t = DiabetesType(rawValue: typeVal) {
                    self.diabetesType = t
                }
                if let prefVal = data["mealPreference"] as? String, let p = MealPreference(rawValue: prefVal) {
                    self.mealPreference = p
                }
                self.consentDataUse = data["consentDataUse"] as? Bool ?? false
                self.agreeTerms = data["agreeTerms"] as? Bool ?? false
                self.receiveAdvice = data["receiveAdvice"] as? Bool ?? true
            }
        }
    }
    
    // MARK: - CGM Pairing Logic
    
    /// Returns stored SN and UUID if paired
    var currentCGMConfig: (sn: String, peripheralID: UUID)? {
        guard let uid = sessionStore?.userId else { return nil }
        do {
            let snap = try Firestore.firestore()
                .collection("users").document(uid)
                .collection("cgmConfig").document("info")
                .getDocumentSync()
            guard let data = snap.data(),
                  let sn = data["sn"] as? String,
                  let raw = data["peripheralID"] as? String,
                  let uuid = UUID(uuidString: raw)
            else { return nil }
            return (sn, uuid)
        } catch {
            return nil
        }
    }
    
    /// Disconnects and removes stored config
    func disconnectCGM(session: SessionStore) {
        // Wrap disconnect call in a Task to satisfy main actor isolation
        Task {
            await cgmService.disconnect()
        }
        guard let uid = session.userId else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("cgmConfig").document("info")
            .delete { err in
                if let err = err { print("Delete CGM config error: \(err)") }
            }
    }
}
