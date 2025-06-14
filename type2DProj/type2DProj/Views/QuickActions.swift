//
//  QuickActions.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI

// Custom pressable button style for touch animations
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct QuickActions: View {
    @EnvironmentObject var mealLog: MealLogViewModel
    @EnvironmentObject var session: SessionStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            // Log Meal
            NavigationLink(destination: AddMealView().environmentObject(mealLog)) {
                ActionButton(label: "Log Meal", icon: "plus.circle")
            }
            .buttonStyle(PressableButtonStyle())

            // AI Prediction
            NavigationLink(destination: PredictionView()
                            .environmentObject(session)) {
                ActionButton(label: "AI Prediction", icon: "waveform.path.ecg")
            }
            .buttonStyle(PressableButtonStyle())

            // Personal Report
            Button(action: {
                // TODO: show Personal Report
            }) {
                ActionButton(label: "Personal Report", icon: "doc.text")
            }
            .buttonStyle(PressableButtonStyle())

            // Copilot
            NavigationLink(destination: ChatView()) {
                ActionButton(label: "Copilot", icon: "bubble.left.and.bubble.right.fill", badge: 4)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal)
    }
}

//#Preview {
//    QuickActions()
//        .environmentObject(MealLogViewModel(session: SessionStore()))
//        .environmentObject(SessionStore())
//}

