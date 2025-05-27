//
//  ProfileView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 22/05/2025.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    //@StateObject private var viewModel = ProfileSetupViewModel()
    @EnvironmentObject var viewModel: ProfileSetupViewModel
    @State private var showEdit = false
    @State private var showSettings = false
    
    var body: some View {
            NavigationView {
                List {
                    Section(header: Text("Account")) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(session.userEmail)
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }

                    Section(header: Text("Profile Info")) {
                        HStack { Text("Age"); Spacer(); Text(viewModel.age) }
                        HStack { Text("Sex"); Spacer(); Text(viewModel.sex.rawValue) }
                        HStack { Text("Insulin Injection"); Spacer(); Text(viewModel.insulin ? "Yes" : "No") }
                        HStack { Text("History of Diabetes"); Spacer(); Text(viewModel.history ? "Yes" : "No") }
                        HStack { Text("Kidney Disease"); Spacer(); Text(viewModel.kidneyDisease ? "Yes" : "No") }
                        HStack { Text("Diabetes Type"); Spacer(); Text(viewModel.diabetesType.rawValue) }
                        HStack { Text("Meal Preference"); Spacer(); Text(viewModel.mealPreference.rawValue) }
                        HStack { Text("Data Use Consent"); Spacer(); Text(viewModel.consentDataUse ? "Yes" : "No") }
                        HStack { Text("Receive Advice"); Spacer(); Text(viewModel.receiveAdvice ? "Yes" : "No") }
                    }

                    Section(header: Text("Options")) {
                        Button(action: { showSettings = true }) {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        NavigationLink(destination: EmptyView()) {
                            Label("Help & Support", systemImage: "questionmark.circle.fill")
                        }
                    }

                    Section {
                        Button(action: {
                            session.signOut()
                        }) {
                            Label("Sign Out", systemImage: "arrow.backward.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            showEdit = true
                        }
                    }
                }
                .sheet(isPresented: $showEdit) {
                    ProfileSetupView()
                        .environmentObject(session)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(session)
                }
                .onAppear {
                    if let uid = session.userId {
                        viewModel.loadExistingProfile(uid: uid)
                    }
                }
            }
        }
}

#Preview {
    ProfileView()
        .environmentObject(SessionStore())
        .environmentObject(ProfileSetupViewModel())
}
