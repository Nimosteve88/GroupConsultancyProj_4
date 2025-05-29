//
//  AnalysisView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 29/05/2025.
//

import SwiftUI
import Charts

struct AnalysisView: View {
    enum Period: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"
        var id: String { rawValue }
    }
    
    @State private var selectedPeriod: Period = .day
    
    // MARK: - Sample Data
    private let avgGlucose = 92
    private let lowGlucose = 67
    private let highGlucose = 118
    private let mealImpacts: [MealImpact] = [
        MealImpact(type: "Breakfast", delta: 38, label: "Peak", color: .red, recovery: "1h 32m"),
        MealImpact(type: "Lunch", delta: 26, label: "Good", color: .green, recovery: "0h 48m")
    ]
    private let nutritionSummary: [NutritionStat] = [
        NutritionStat(name: "Carbs", value: 210, unit: "g", percent: 55, color: .green),
        NutritionStat(name: "Protein", value: 98, unit: "g", percent: 25, color: .blue),
        NutritionStat(name: "Fat", value: 55, unit: "g", percent: 20, color: .orange)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Analysis")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Period Picker
                    Picker("", selection: $selectedPeriod) {
                        ForEach(Period.allCases) { p in Text(p.rawValue).tag(p) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Blood Glucose Analysis
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Blood Glucose Analysis")
                            .font(.headline)
                            .padding(.horizontal)
                        HStack(spacing: 16) {
                            GlucoseStat(label: "Average", value: avgGlucose, color: .primary)
                            GlucoseStat(label: "Low", value: lowGlucose, color: .red)
                            GlucoseStat(label: "High", value: highGlucose, color: .primary)
                        }
                        .padding(.horizontal)
                        // Placeholder chart area
                        Rectangle()
                            .fill(Color.primaryBackground)
                            .frame(height: 160)
                            .overlay(Text("Detailed glucose chart").foregroundColor(.secondary))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Meal Impact on Glucose
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal Impact on Glucose")
                            .font(.headline)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(mealImpacts) { item in
                                    MealImpactCard(item: item)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Glucose Insight
                    InsightCard(icon: "flask.fill", title: "Glucose Insight", text: "Your glucose response to breakfast shows a significant spike. Consider adding more protein or reducing simple carbs at breakfast.")
                        .padding(.horizontal)
                    
                    // Nutrition Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Nutrition Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        HStack(spacing: 16) {
                            ForEach(nutritionSummary) { stat in
                                NutritionCard(stat: stat)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Insight
                    InsightCard(icon: "lightbulb.fill", title: "Insight", text: "Your protein intake is slightly below your goal. Consider adding a protein-rich snack.")
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Analysis")
        }
    }
}

// MARK: - Subcomponents
struct GlucoseStat: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        VStack {
            Text(label).font(.caption)
            Text("\(value) mg/dL").font(.title2).bold().foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealImpact: Identifiable {
    let id = UUID()
    let type: String
    let delta: Int
    let label: String
    let color: Color
    let recovery: String
}

struct MealImpactCard: View {
    let item: MealImpact
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.type).font(.subheadline).bold()
                Spacer()
                Text(item.recovery).font(.caption).foregroundColor(.secondary)
            }
            Text("+\(item.delta) mg/dL")
                .font(.headline).foregroundColor(item.color)
                + Text(" ")
                + Text(item.label).font(.caption).foregroundColor(item.color)
            Text("Recovery: \(item.recovery)")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .frame(width: 200)
    }
}

struct NutritionStat: Identifiable {
    let id = UUID()
    let name: String
    let value: Int
    let unit: String
    let percent: Int
    let color: Color
}

struct NutritionCard: View {
    let stat: NutritionStat
    var body: some View {
        VStack(spacing: 8) {
            Text(stat.name).font(.caption)
            Text("\(stat.value)\(stat.unit)")
                .font(.title2).bold().foregroundColor(stat.color)
            Text("\(stat.percent)%").font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    AnalysisView()
}
