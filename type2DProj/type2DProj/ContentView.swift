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
            MealLibraryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Meals")
                }

            CGMView()
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("CGM")
                }
        }
        .background(Color.primaryBackground.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthKitService.shared)
}

