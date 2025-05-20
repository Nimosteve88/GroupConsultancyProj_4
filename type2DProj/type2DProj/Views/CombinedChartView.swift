//
//  CombinedChartView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI
import Charts

struct CombinedChartView: View {
    let actual: [GlucoseSample]
    let predicted: [GlucoseSample]

    var body: some View {
        Chart {
            ForEach(actual) { p in
                LineMark(
                    x: .value("Time", p.time),
                    y: .value("Actual", p.value)
                )
            }
            ForEach(predicted) { p in
                LineMark(
                    x: .value("Time", p.time),
                    y: .value("Predicted", p.value)
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))            }
        }
        .chartXAxis { AxisMarks(values: .automatic) }
        .chartYAxis { AxisMarks(position: .leading) }
    }
}

extension AdviceEngine {
    func predictedSamples() -> [GlucoseSample] {
        let now = Date()
        return (0..<24).map { i in
            GlucoseSample(
                time: Calendar.current.date(byAdding: .hour, value: -i, to: now)!,
                value: Double.random(in: 4...10)
            )
        }.sorted { $0.time < $1.time }
    }
}

#Preview {
    CombinedChartView(
        actual: [
            GlucoseSample(time: Date(), value: 5.0),
            GlucoseSample(time: Date().addingTimeInterval(-3600), value: 6.0),
            GlucoseSample(time: Date().addingTimeInterval(-7200), value: 7.0)
        ],
        predicted: AdviceEngine.shared.predictedSamples()
    )
}
