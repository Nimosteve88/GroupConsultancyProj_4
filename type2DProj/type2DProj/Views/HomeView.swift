//
//  HomeView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var mealLogVM: MealLogViewModel
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var adviceEngine: AdviceEngine

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Good \(greeting()),")
                                .font(.title)
                                .bold()
                            Text(Date(), style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                        StatCard(title: "Last Meal", value: lastMealSummary(), icon: "fork.knife")
                        StatCard(title: "Glucose", value: latestGlucoseValue(), icon: "waveform.path.ecg")
                        StatCard(title: "Advice", value: adviceEngine.riskLevel.rawValue, icon: "lightbulb")
                    }
                    .padding(.horizontal)

                    VStack(spacing: 16) {
                        NavigationLink(destination: MealLibraryView()) {
                            ActionButton(label: "Log a Meal", icon: "plus.circle")
                        }
                        NavigationLink(destination: CGMView()) {
                            ActionButton(label: "View CGM Data", icon: "waveform.path.ecg")
                        }
                        NavigationLink(destination: AdviceView()) {
                            ActionButton(label: "Get Advice", icon: "lightbulb.fill")
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }

    func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Morning"
        case 12..<18: return "Afternoon"
        case 18..<22: return "Evening"
        default: return "Night"
        }
    }

    func lastMealSummary() -> String {
        if let meal = mealLogVM.meals.first {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: meal.date)
            return "\(meal.name) at \(timeString)"
        }
        return "No meals logged"
    }

    func latestGlucoseValue() -> String {
        let samples = healthKitService.glucoseSamples
        let latest = samples.isEmpty ? Double.random(in: 4...10) : samples.last!.value
        return String(format: "%.1f", latest)
    }
}

#Preview {
    HomeView()
}
