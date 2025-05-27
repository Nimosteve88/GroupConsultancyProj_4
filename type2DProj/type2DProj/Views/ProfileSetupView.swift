//
//  ProfileSetupView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 24/05/2025.
//

import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ProfileSetupViewModel()
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Age", text: $viewModel.age)
                        .keyboardType(.numberPad)
                    Picker("Sex", selection: $viewModel.sex) {
                        ForEach(ProfileSetupViewModel.Sex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                }
                
                Section(header: Text("Clinical Background")) {
                    Toggle("Insulin Injection", isOn: $viewModel.insulin)
                    Toggle("History of Diabetes", isOn: $viewModel.history)
                    Toggle("Kidney Disease", isOn: $viewModel.kidneyDisease)
                }
                
                Section(header: Text("Type of Diabetes")) {
                    Picker("Type", selection: $viewModel.diabetesType) {
                        ForEach(ProfileSetupViewModel.DiabetesType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Meal Preference")) {
                    Picker("Preference", selection: $viewModel.mealPreference) {
                        ForEach(ProfileSetupViewModel.MealPreference.allCases, id: \.self) { pref in
                            Text(pref.rawValue).tag(pref)
                        }
                    }
                }
                
                Section(header: Text("Consents")) {
                    Toggle("Consent to Data Use for Research", isOn: $viewModel.consentDataUse)
                    Toggle("Agree to Terms & Conditions", isOn: $viewModel.agreeTerms)
                    Toggle("Receive Health Advice", isOn: $viewModel.receiveAdvice)
                }
                
                Button(action: saveProfile) {
                    Text("Save Profile")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.isFormValid)
            }
            .navigationTitle("Profile Setup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let uid = session.userId else { return }
                        viewModel.saveProfile(uid: uid) { result in
                            switch result {
                            case .success:
                                session.needsProfileSetup = false
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .alert(errorMessage, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                if let uid = session.authService.user?.uid {
                    viewModel.loadExistingProfile(uid: uid)
                }
            }
        }
    }

    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        viewModel.saveProfile(uid: uid) { result in
            switch result {
            case .success:
                session.needsProfileSetup = false
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(SessionStore())
        .environmentObject(ProfileSetupViewModel())
    
}
