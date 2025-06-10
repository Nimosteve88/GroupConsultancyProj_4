//
//  CGMView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI
import Charts

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    
    var id: String { self.rawValue }
}

struct CGMView: View {
    @EnvironmentObject var session: SessionStore
    @ObservedObject var cgmService = CGMService(session: SessionStore())
    @StateObject private var readingVM = CGMReadingsViewModel()
    @State private var showPairing = false
    @State private var filterSelection: FilterOption = .all

    var filteredReadings: [FirestoreGlucoseReading] {
        let now = Date()
        switch filterSelection {
        case .all:
            return readingVM.readings
        case .today:
            return readingVM.readings.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .lastWeek:
            guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return [] }
            return readingVM.readings.filter { $0.timestamp >= weekAgo }
        case .lastMonth:
            guard let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) else { return [] }
            return readingVM.readings.filter { $0.timestamp >= monthAgo }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {

            // Connection status indicator
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Connected")
                    .bold()
                Spacer()
                // Show disconnect button if connected
                Button(action: {
                    cgmService.disconnect()
                }) {
                    Text("Disconnect")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Picker("Filter", selection: $filterSelection) {
                ForEach(FilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if filteredReadings.isEmpty {
                Spacer()
                Text("No glucose readings yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Chart {
                    ForEach(filteredReadings) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("mg/dL", sample.value)
                        )
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis { AxisMarks(values: .automatic) }
                .frame(height: 300)
                .padding(.horizontal)
                
                // Sort readings descending: latest first
                let sortedReadings = filteredReadings.sorted { $0.timestamp > $1.timestamp }
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(sortedReadings.enumerated()), id: \.element.id) { index, reading in
                            HStack {
                                Text(String(format: "%.1f mg/dL", reading.value))
                                    .font(.title2)
                                    .bold()
                                
                                // Compare with the next reading (chronologically earlier) if available.
                                if index < sortedReadings.count - 1 {
                                    let next = sortedReadings[index + 1]
                                    if reading.value > next.value {
                                        Image(systemName: "arrow.up")
                                            .foregroundColor(.green)
                                    } else if reading.value < next.value {
                                        Image(systemName: "arrow.down")
                                            .foregroundColor(.red)
                                    } else {
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text(reading.timestamp, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let uid = session.userId {
                readingVM.startListening(uid: uid)
            }
            if let cfg = readingVM.currentCGMConfig {
                cgmService.attemptAutoReconnect(using: cfg)
            }
        }
        .onDisappear {
            cgmService.disconnect()
            readingVM.stopListening()
        }
        .navigationTitle("CGM Data")
    }
}

