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

    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    init() {
        FirebaseApp.configure()
        healthKitService.requestAuthorization()
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
    
//12344444
    

    var body: some Scene {
        WindowGroup {
            Group {
                if !session.isLoggedIn {
                    LoginView()
                        .environmentObject(session)
                } else if session.needsProfileSetup {
                    ProfileSetupView()
                        .environmentObject(session)
                } else {
                    ContentView()
                        .environmentObject(session)
                        .environmentObject(healthKitService)
                        .environmentObject(mealLogVM)
                        .environmentObject(adviceEngine)
                        .environmentObject(profileVM)
                }
            }
            .preferredColorScheme(isDarkMode ? ColorScheme.dark : ColorScheme.light)
        }
    }
}

