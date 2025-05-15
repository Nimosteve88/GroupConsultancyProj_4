//
//  type2DProjApp.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI

@main
struct type2DProjApp: App {
    @StateObject private var healthKitService = HealthKitService.shared

    init() {
        healthKitService.requestAuthorization()
        // Configure global appearance
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitService)
                .accentColor(.purple)
        }
    }
}
