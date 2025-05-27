//
//  StatsCarousel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI

struct StatsCarousel: View {
    @EnvironmentObject var mealsVM: MealLogViewModel
    @EnvironmentObject var userVM: ProfileSetupViewModel

    private var todayCalories: Int {
        let calendar = Calendar.current
        return mealsVM.meals
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + Int($1.calories) }
    }

    private var recommendedCalories: Int {
        // Example formula: 2000 + (age - 18) * 10
        let age = Int(userVM.age) ?? 30
        return 2000 + max(0, (age - 18) * 10)
    }

    var body: some View {
        TabView {
            StatCard(title: "Blood Glucose", value: "\(Int.random(in:50...120)) mg/dl", icon: "drop.fill")
            StatCard(
                title: "Eaten",
                value: "\(todayCalories)/\(recommendedCalories) cal",
                icon: "fork.knife"
            )
            StatCard(title: "Risk", value: AdviceEngine.shared.riskLevel.rawValue, icon: "lightbulb.fill")
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .frame(height: 150)
        .padding(.horizontal)
    }
}

#Preview {
    StatsCarousel()
        .environmentObject(MealLogViewModel(session: SessionStore()))
        .environmentObject(SessionStore())
}
