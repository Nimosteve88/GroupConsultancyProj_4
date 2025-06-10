//
//  CGMService.swift
//  type2DProj
//
//  Created by Nimo, Steve on 02/06/2025.
//

import Foundation
import Combine
import CoreBluetooth
import HealthKit
import CGMBLEKit
import FirebaseFirestore

// MARK: – Connection State

enum ConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case error(String)
}

final class CGMService: NSObject, ObservableObject {
    // MARK: – Public Data Models

    struct Peripheral: Identifiable {
        let id: UUID
        let name: String?
        let peripheral: CBPeripheral
    }

    struct GlucoseReading: Identifiable {
        let id = UUID()
        let value: Double
        let timestamp: Date
        let trend: Int?
    }

    // MARK: – Published Properties (UI observes these)

    @MainActor @Published var discoveredPeripherals: [Peripheral] = []
    @MainActor @Published var connectionState: ConnectionState = .disconnected
    @MainActor @Published var lastError: String?
    @MainActor @Published var glucoseReadings: [GlucoseReading] = []
    private let session: SessionStore


    // MARK: – Private Bluetooth/Transmitter State

    var centralManager: CBCentralManager!
    private var transmitter: Transmitter?
    private var connectionAttempts = 0
    private let maxConnectionAttempts = 3

    // MARK: – Configuration State

    var pendingSN: String?
    var selectedPeripheralID: UUID?

    // MARK: – Initialization

    init(session: SessionStore) {
            self.session = session
            super.init()
            // Use main queue so we can update Published properties directly
            centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: – Public Methods

    /// Start scanning for peripheral broadcasts
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            Task { @MainActor in
                connectionState = .error("Bluetooth is not available")
            }
            return
        }

        resetState(keepPeripherals: false)
        Task { @MainActor in
            connectionState = .scanning
        }
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    /// Connect to a specific peripheral with the given SN
    func connect(to peripheral: Peripheral, withSN sn: String) {
        guard centralManager.state == .poweredOn else {
            Task { @MainActor in
                connectionState = .error("Bluetooth is not available")
            }
            return
        }

        // Stop scanning right away
        centralManager.stopScan()
        Task { @MainActor in
            connectionState = .connecting
        }

        selectedPeripheralID = peripheral.id
        pendingSN = sn.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        connectionAttempts = 0

        // Create Transmitter (active mode)
        transmitter = Transmitter(
            id: pendingSN!,
            peripheralIdentifier: peripheral.id,
            passiveModeEnabled: false
        )
        transmitter?.delegate = self
        transmitter?.stayConnected = true

        // Actually call CoreBluetooth connect; CGMBLEKit will finish handshake
        centralManager.connect(peripheral.peripheral, options: nil)
    }

    /// Disconnect permanently (user tapped “Disconnect”)
    @MainActor func disconnect() {
        // Tear down transmitter
        transmitter?.stopScanning()
        transmitter = nil

        // Cancel CB connection if still alive
        if let id = selectedPeripheralID,
           let p = discoveredPeripherals.first(where: { $0.id == id })?.peripheral {
            centralManager.cancelPeripheralConnection(p)
        }

        resetState(keepPeripherals: true)
        connectionState = .disconnected
    }

    // MARK: – Private Helpers

    /// Clear state. If `keepPeripherals == false` we also wipe the list of discoveredPeripherals
    private func resetState(keepPeripherals: Bool) {
        pendingSN = nil
        selectedPeripheralID = nil
        connectionAttempts = 0

        if !keepPeripherals {
            Task { @MainActor in
                discoveredPeripherals.removeAll()
            }
        }

        Task { @MainActor in
            lastError = nil
            // We do NOT change connectionState here; caller sets it
        }
    }

    /// Called each time we get a fresh CGM packet. We append it to glucoseReadings.
    private func handleNewGlucose(_ glucose: CGMBLEKit.Glucose) {
        guard let hkQty = glucose.glucose else { return }

        let valueMgdl = hkQty.doubleValue(for: HKUnit(from: "mg/dL"))
        let newReading = GlucoseReading(
            value: valueMgdl,
            timestamp: glucose.readDate,
            trend: glucose.trend
        )

        print("New glucose reading: \(newReading.value) at \(newReading.timestamp)")
        
        // Add to newReading to Firestore under users/{uid}/glucoseReadings
        
        guard let uid = session.userId else { return }
        let data: [String: Any] = [
                    "timestamp": Timestamp(date: newReading.timestamp),
                    "value": newReading.value,
                ]
        Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("glucoseReadings")
                .addDocument(data: data) { error in
                    if let error = error {
                        print("Error writing glucose reading: \(error)")
                    }
                }
        print("Wrote glucose reading to Firestore: \(newReading.value) at \(newReading.timestamp)")
        

        // Keep only last 24h, most recent first
        Task { @MainActor in
            let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
            glucoseReadings = (glucoseReadings + [newReading])
                .filter { $0.timestamp > cutoff }
                .sorted { $0.timestamp > $1.timestamp }
        }
    }
}

// MARK: – CBCentralManagerDelegate

extension CGMService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                // If we were showing a Bluetooth error, try scanning again automatically
                if case .error("Bluetooth is not available") = connectionState {
                    startScanning()
                }
            case .poweredOff, .unauthorized, .unsupported:
                connectionState = .error("Bluetooth is not available")
                lastError = "Bluetooth is turned off or not authorized"
            default:
                break
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)

        // Only show Dexcom/“CGM”‐named devices
        guard
            let nm = name,
            (nm.contains("Dexcom") || nm.contains("CGM"))
        else { return }

        let newPeripheral = Peripheral(
            id: peripheral.identifier,
            name: nm,
            peripheral: peripheral
        )

        Task { @MainActor in
            if !discoveredPeripherals.contains(where: { $0.id == peripheral.identifier }) {
                discoveredPeripherals.append(newPeripheral)
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        guard peripheral.identifier == selectedPeripheralID else { return }
        // Handshake: CGMBLEKit discovers services/authenticates, then calls transmitterDidConnect
        transmitter?.resumeScanning()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        guard peripheral.identifier == selectedPeripheralID else { return }

        connectionAttempts += 1

        Task { @MainActor in
            if let err = error {
                // If Dexcom disconnects after sending data, we treat it as normal.
                // Only surface an error if we’ve failed too many times in a row.
                if connectionAttempts >= maxConnectionAttempts {
                    connectionState = .error("Disconnected: \(err.localizedDescription)")
                    lastError = err.localizedDescription
                    transmitter?.stayConnected = false
                } else {
                    // Stay in “connected” state; immediately try to resume scanning
                    transmitter?.resumeScanning()
                }
            } else {
                // Clean disconnect without error—if user tapped “Disconnect”, state was already reset.
                if transmitter?.stayConnected == true,
                   connectionAttempts < maxConnectionAttempts
                {
                    transmitter?.resumeScanning()
                } else if connectionAttempts >= maxConnectionAttempts {
                    connectionState = .error("Lost connection after \(maxConnectionAttempts) attempts")
                    lastError = "Failed to keep Dexcom alive"
                    transmitter?.stayConnected = false
                }
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        guard peripheral.identifier == selectedPeripheralID else { return }
        let msg = error?.localizedDescription ?? "Unknown error"
        Task { @MainActor in
            connectionState = .error("Connection failed: \(msg)")
            lastError = msg
        }
    }
}

// MARK: – TransmitterDelegate

extension CGMService: TransmitterDelegate {
    func transmitterDidConnect(_ transmitter: Transmitter) {
        Task { @MainActor in
            connectionState = .connected
            lastError = nil
        }
    }

    func transmitter(_ transmitter: Transmitter, didError error: Error) {
        // Only show an error if we are already “connected”;
        // ignore any errors during the initial “connecting” handshake.
//        Task { @MainActor in
//            guard connectionState == .connected else { return }
//            connectionState = .error(error.localizedDescription)
//            lastError = error.localizedDescription
//        }
    }

    func transmitter(_ transmitter: Transmitter, didRead glucose: CGMBLEKit.Glucose) {
        // Each time Dexcom pushes a new glucose packet, we receive it here:
        handleNewGlucose(glucose)
    }

    func transmitter(_ transmitter: Transmitter, didReadBackfill glucose: [CGMBLEKit.Glucose]) {
        glucose.forEach { single in
            handleNewGlucose(single)
        }
    }

    func transmitter(_ transmitter: Transmitter, didReadUnknownData data: Data) {
        // ignore
    }
}







