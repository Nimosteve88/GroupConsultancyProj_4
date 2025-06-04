//
//  CGMView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI
import CoreBluetooth

struct CGMView: View {
    @StateObject private var cgmService = CGMService()
    @State private var showSNEntry = false
    @State private var selectedPeripheral: CGMService.Peripheral?
    @State private var snInput = ""
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                connectionStatusHeader

                switch cgmService.connectionState {
                case .connected:
                    glucoseReadingsView

                case .connecting:
                    connectingView

                default:
                    deviceListView
                }

                Spacer()
            }
            .padding()
            .navigationTitle("CGM Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if cgmService.connectionState == .connected {
                        Button("Disconnect") {
                            cgmService.disconnect()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(cgmService.lastError != nil)) {
                Button("OK") {
                    cgmService.lastError = nil
                }
            } message: {
                Text(cgmService.lastError ?? "Unknown error")
            }
            .sheet(isPresented: $showSNEntry) {
                serialNumberEntryView
            }
        }
    }

    // MARK: – Subviews

    private var connectionStatusHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Real-Time Glucose")
                .font(.largeTitle)
                .bold()

            HStack(spacing: 6) {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 12, height: 12)
                Text(connectionStatusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var glucoseReadingsView: some View {
        Group {
            if cgmService.glucoseReadings.isEmpty {
                VStack {
                    Spacer()
                    Text("No readings received yet")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    // Show most recent first
                    ForEach(cgmService.glucoseReadings) { reading in
                        HStack {
                            Text(reading.timestamp, style: .time)
                                .font(.body)

                            Spacer()

                            Text("\(Int(reading.value))")
                                .font(.title2)
                                .bold()
                                .foregroundColor(glucoseColor(for: reading.value))

                            if let trend = reading.trend {
                                trendArrow(for: trend)
                                    .foregroundColor(trendColor(for: trend))
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var connectingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Connecting…")
                .font(.headline)
                .padding(.top)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var deviceListView: some View {
        VStack(spacing: 16) {
            Text("Available CGM Devices")
                .font(.headline)

            TextField("Search devices…", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            List(filteredPeripherals) { peripheral in
                Button(action: {
                    selectedPeripheral = peripheral
                    snInput = ""
                    showSNEntry = true
                }) {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text(peripheral.name ?? peripheral.id.uuidString)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .frame(height: 200)

            Button(action: {
                cgmService.startScanning()
            }) {
                Label("Scan for Devices", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var serialNumberEntryView: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Enter 6-digit SN", text: $snInput)
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                } header: {
                    Text("Serial Number")
                } footer: {
                    Text("Example: 01A2B3")
                }
            }
            .navigationTitle("Connect to Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSNEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        if let p = selectedPeripheral {
                            cgmService.connect(to: p, withSN: snInput)
                        }
                        showSNEntry = false
                    }
                    .disabled(
                        snInput.trimmingCharacters(in: .whitespacesAndNewlines).count != 6
                    )
                }
            }
        }
    }

    // MARK: – Helper Computed Properties

    private var filteredPeripherals: [CGMService.Peripheral] {
        if searchText.isEmpty {
            return cgmService.discoveredPeripherals
        } else {
            return cgmService.discoveredPeripherals.filter {
                ($0.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var connectionStatusText: String {
        switch cgmService.connectionState {
        case .disconnected:   return "Disconnected"
        case .scanning:       return "Scanning for devices…"
        case .connecting:     return "Connecting…"
        case .connected:      return "Connected"
        case .error(let msg): return msg
        }
    }

    private var connectionStatusColor: Color {
        switch cgmService.connectionState {
        case .connected: return .green
        case .error:     return .red
        default:         return .orange
        }
    }

    // MARK: – Trend / Color Helpers

    private func glucoseColor(for value: Double) -> Color {
        switch value {
        case ..<70:    return .red
        case 70..<180: return .green
        default:       return .orange
        }
    }

    private func trendArrow(for trend: Int) -> some View {
        let systemName: String
        switch trend {
        case ..<(-2):  systemName = "arrow.down"       // Rapid fall
        case -2:       systemName = "arrow.down.right" // Moderate fall
        case -1:       systemName = "arrow.right"      // Slight fall
        case 0:        systemName = "arrow.right"      // Steady
        case 1:        systemName = "arrow.right"      // Slight rise
        case 2:        systemName = "arrow.up.right"   // Moderate rise
        default:       systemName = "arrow.up"         // Rapid rise / other
        }
        return Image(systemName: systemName)
    }

    private func trendColor(for trend: Int) -> Color {
        switch trend {
        case ..<(-1): return .red
        case -1...1:  return .gray
        default:      return .green
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

