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
        // Basic validation
        guard !age.isEmpty, Int(age) != nil,
              agreeTerms,
              Auth.auth().currentUser != nil else {
            return false
        }
        return true
    }

    private let db = Firestore.firestore()

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
        db.collection("users").document(uid).collection("profileinfo").document("info").setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
            
            
        }
    }

        func loadExistingProfile(uid: String) {
        let docRef = db.collection("users")
            .document(uid)
            .collection("profileinfo")
            .document("info")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            DispatchQueue.main.async {
                if let ageVal = data["age"] as? Int {
                    self.age = String(ageVal)
                }
                if let sexVal = data["sex"] as? String, let s = Sex(rawValue: sexVal) {
                    self.sex = s
                }
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
}

