//
//  CGMView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI
import Charts

struct CGMView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    private var fallbackSamples: [GlucoseSample] {
        let now = Date()
        return (0..<24).map { i in GlucoseSample(time: Calendar.current.date(byAdding: .hour, value: -i, to: now)!, value: Double.random(in: 4...10)) }
            .sorted { $0.time < $1.time }
    }
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground.edgesIgnoringSafeArea(.all)
                let samples = healthKitService.glucoseSamples.isEmpty ? fallbackSamples : healthKitService.glucoseSamples
                Chart {
                    ForEach([4.0,7.8], id: \.self) { threshold in
                        RuleMark(y: .value("Threshold", threshold))
                            .lineStyle(StrokeStyle(lineWidth:1,dash:[5]))
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    ForEach(samples) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Glucose", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle())
                        .symbolSize(50)
                        .foregroundStyle(point.value < 4.0 || point.value > 7.8 ? .red : .green)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .padding()
            }
            .navigationTitle("CGM Data")
        }
    }
}

//#Preview {
//    let session = SessionStore()
//    Group {
//        ContentView()
//            .environmentObject(MealLogViewModel(session: session))
//            .environmentObject(HealthKitService.shared)
//
//        MealDetailView(
//            meal: Meal(
//                name: "Oatmeal with Berries",
//                carbs: 45,
//                protein: 5,
//                fat: 2,
//                fiber: 4,
//                calories: 80,
//                date: Date(),
//                imageName: "oatmeal"
//            )
//        )
//    }
//}

