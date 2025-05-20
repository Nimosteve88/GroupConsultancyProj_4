//
//  HomeView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI
import Charts

struct HomeView: View {
    @EnvironmentObject var healthKit: HealthKitService
    @EnvironmentObject var mealLog: MealLogViewModel
    @EnvironmentObject var advice: AdviceEngine

    @State private var tasks: [TodayTask] = [
        .init(time: "07:30 AM", title: "Morning walk"),
        .init(time: "12:30 PM", title: "Exercise"),
        .init(time: "17:50 PM", title: "Inject insulin"),
        .init(time: "20:00 PM", title: "Drink warm water")
    ]

    private var showBanner: Bool {
        advice.riskLevel == .high
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if showBanner {
                        AlertBanner(
                            text: "HIGH HYPOGLYCEMIA RISK",
                            subtext: "Your glucose level is below range!",
                            color: .red
                        )
                    }

                    CombinedChartView(
                        actual: healthKit.glucoseSamples,
                        predicted: advice.predictedSamples()
                    )
                    .frame(height: 200)
                    .padding(.horizontal)

                    StatsCarousel()

                    QuickActions()

                    TodayTasksList(tasks: $tasks)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    HomeView()
}
