//
//  ContentView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            MealLibraryView()
                .tabItem { Label("Meals", systemImage: "book.fill") }
            AnalysisView()
                .tabItem { Label("Analysis", systemImage: "chart.bar.fill") }
            AdviceView()
                .tabItem { Label("Advice", systemImage: "lightbulb.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .background(Color.primaryBackground.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    let session = SessionStore()
    ContentView()
        .environmentObject(HealthKitService.shared)
        .environmentObject(MealLogViewModel(session: session))
        .environmentObject(AdviceEngine.shared)
}

