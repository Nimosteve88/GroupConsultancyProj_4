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
    @EnvironmentObject var healthKit: HealthKitService
    @EnvironmentObject var advice: AdviceEngine

    var body: some View {
        VStack(spacing: 12) {
            // Log Meal navigates to AddMealView
            NavigationLink(destination: AddMealView().environmentObject(mealLog)) {
                ActionButton(label: "Log Meal", icon: "plus.circle")
            }
            .buttonStyle(PressableButtonStyle())

            // Other quick actions (stubbing destinations)
            Button(action: {
                // TODO: show Daily Meal Plan
            }) {
                ActionButton(label: "Daily Meal Plan", icon: "list.bullet")
            }
            .buttonStyle(PressableButtonStyle())

            Button(action: {
                // TODO: show Personal Report
            }) {
                ActionButton(label: "Personal Report", icon: "doc.text")
            }
            .buttonStyle(PressableButtonStyle())

            Button(action: {
                // TODO: show Suggestion Center
            }) {
                ActionButton(label: "Suggestion Center", icon: "bubble.left.and.bubble.right.fill", badge: 4)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal)
    }
}

#Preview {
    QuickActions()
        .environmentObject(MealLogViewModel())
}
