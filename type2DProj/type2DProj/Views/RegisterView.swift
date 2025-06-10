//
//  RegisterView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 22/05/2025.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var session: SessionStore
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if password != confirmPassword {
                    Text("Passwords do not match.")
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                if let error = session.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: register) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Register")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accent)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword || isLoading)
                .onChange(of: session.isLoggedIn) { loggedIn in
                    if loggedIn {
                        isLoading = false
                    }
                }
                .onChange(of: session.errorMessage) { error in
                    if error != nil {
                        isLoading = false
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Register")
        }
    }

    private func register() {
        isLoading = true
        session.signUp(email: email, password: password) { result in
            isLoading = false
            switch result {
                    case .success:
                    // nothing extra to do here; auth listener handles state
                    break
                    case .failure(let error):
                        print("Login failed: \(error.localizedDescription)")
                        }
                    }
    }
}


#Preview {
    RegisterView()
        .environmentObject(SessionStore())
}
