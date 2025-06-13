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
    @EnvironmentObject var session: SessionStore
    @StateObject private var readingVM = CGMReadingsViewModel()

    private var todayCalories: Int {
        let calendar = Calendar.current
        return mealsVM.meals
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + Int($1.calories) }
    }

    private var recommendedCalories: Int {
        let age = Int(userVM.age) ?? 30
        return 2000 + max(0, (age - 18) * 10)
    }

    private var latestGlucoseValue: String {
        guard let first = readingVM.readings.first else {
            return "—"
        }
        return "\(Int(first.value)) mg/dl"
    }

    var body: some View {
        TabView {
            StatCard(
                title: "Blood Glucose",
                value: latestGlucoseValue,
                icon: "drop.fill"
            )

            StatCard(
                title: "Eaten",
                value: "\(todayCalories)/\(recommendedCalories) cal",
                icon: "fork.knife"
            )

            StatCard(
                title: "Risk",
                value: AdviceEngine.shared.riskLevel.rawValue,
                icon: "lightbulb.fill"
            )
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .frame(height: 150)
        .padding(.horizontal)
        .onAppear {
            if let uid = session.userId {
                readingVM.startListening(uid: uid)
            }
        }
    }
}

#Preview {
    StatsCarousel()
        .environmentObject(MealLogViewModel(session: SessionStore()))
        .environmentObject(ProfileSetupViewModel())
        .environmentObject(SessionStore())
}

