//
//  CombinedChartView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI
import Charts

struct CombinedChartView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var cgmService = CGMService(session: SessionStore())
    @StateObject private var readingVM = CGMReadingsViewModel()
    @State private var showPairing = false
    @State private var isConnecting = false
    @State private var navigateToCGM = false

    // MARK: - Predicted Dummy Data
    private var predictedSamples: [FirestoreGlucoseReading] {
        let now = Date()
        return (0..<24).compactMap { i in
            guard let date = Calendar.current.date(byAdding: .hour, value: -i, to: now) else { return nil }
            return FirestoreGlucoseReading(id: "pred_\(i)", value: Double.random(in: 80...150), timestamp: date)
        }.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        ZStack {
            // MARK: - Chart View
            Group {
                if cgmService.connectionState == .connected {
                    liveChart
                } else {
                    predictedChart
                }
            }

            // MARK: - Connect Overlay
            if cgmService.connectionState != .connected {
                VStack {
                    Spacer()
                    Button(action: {
                        isConnecting = true
                        if let cfg = readingVM.currentCGMConfig {
                            cgmService.attemptAutoReconnect(using: cfg)
                        } else {
                            showPairing = true
                        }
                    }) {
                        HStack {
                            if isConnecting || cgmService.connectionState == .connecting {
                                ProgressView()
                            }
                            Text(cgmService.connectionState == .connecting ? "Connecting…" : "Connect CGM")
                                .bold()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.accentColor.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }

            // MARK: - Navigate to Full CGM View
            if cgmService.connectionState == .connected {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { navigateToCGM = true }) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }

            // MARK: - Navigation Links
            NavigationLink(destination: PairCGMView().environmentObject(session),
                           isActive: $showPairing) { EmptyView() }
            NavigationLink(destination: CGMView().environmentObject(session),
                           isActive: $navigateToCGM) { EmptyView() }
        }
        .onAppear {
            guard let uid = session.userId else { return }
            readingVM.startListening(uid: uid)
            if let cfg = readingVM.currentCGMConfig {
                cgmService.attemptAutoReconnect(using: cfg)
            }
        }
        .onChange(of: cgmService.connectionState) { state in
            isConnecting = (state == .connecting)
        }
    }

    // MARK: - Subviews
    private var liveChart: some View {
        Chart {
            ForEach(readingVM.readings) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Glucose", sample.value)
                )
            }
        }
        .chartXAxis { AxisMarks(values: .automatic) }
        .chartYAxis { AxisMarks(position: .leading) }
        .padding()
    }

    private var predictedChart: some View {
        Chart {
            ForEach(predictedSamples) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Predicted", sample.value)
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            }
        }
        .chartXAxis { AxisMarks(values: .automatic) }
        .chartYAxis { AxisMarks(position: .leading) }
        .padding()
    }
}

#Preview {
    CombinedChartView()
        .environmentObject(SessionStore())
}


