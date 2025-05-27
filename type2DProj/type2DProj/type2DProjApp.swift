//
//  type2DProjApp.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI
import Firebase

@main
struct type2DProjApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var healthKitService = HealthKitService.shared
    @StateObject private var mealLogVM = MealLogViewModel()
    @StateObject private var profileVM = ProfileSetupViewModel()
    @StateObject private var adviceEngine = AdviceEngine.shared

    init() {
        FirebaseApp.configure()
        healthKitService.requestAuthorization()
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
    
//12344444
    

    var body: some Scene {
            WindowGroup {
                if !session.isLoggedIn {
                    // Not signed in: Login/Register flow
                    LoginView()
                        .environmentObject(session)
                } else if session.needsProfileSetup {
                    // Signed in but no profile data: onboarding
                    ProfileSetupView()
                        .environmentObject(session)
                } else {
                    // Fully onboarded: main app
                    ContentView()
                        .environmentObject(session)
                        .environmentObject(healthKitService)
                        .environmentObject(mealLogVM)
                        .environmentObject(adviceEngine)
                        .environmentObject(profileVM)
                }
            }
        }
}

