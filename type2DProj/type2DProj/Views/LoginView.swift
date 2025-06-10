//
//  LoginView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 22/05/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome Back")
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

                if let error = session.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                        isLoading = true
                        session.signIn(email: email, password: password) { result in
                        isLoading = false
                        switch result {
                                case .success:
                                // nothing extra to do here; auth listener handles state
                                break
                                case .failure(let error):
                                    print("Login failed: \(error.localizedDescription)")
                                    }
                                }
                    })  {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accent)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                HStack {
                    Text("Don't have an account?")
                    NavigationLink("Register", destination: RegisterView().environmentObject(session))
                }
                .font(.footnote)

                Spacer()
            }
            .padding()
            .navigationTitle("Login")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}
