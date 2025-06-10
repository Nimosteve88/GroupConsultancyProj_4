//
//  PairCGMView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 09/06/2025.
//

import SwiftUI
import CoreBluetooth
import FirebaseFirestore

struct PairCGMView: View {
    @EnvironmentObject var session: SessionStore
    @ObservedObject private var cgmService = CGMService(session: SessionStore())
    @State private var peripherals: [CGMService.Peripheral] = []
    @State private var enteredSN: String = ""
    @State private var showSerialEntry = false
    @State private var selectedPeripheral: CGMService.Peripheral?

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    switch cgmService.connectionState {
                    case .scanning:
                        Text("Scanning for devices…")
                            .foregroundColor(.secondary)
                    case .connecting:
                        ProgressView()
                        Text("Connecting…")
                    case .connected:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connected")
                            .bold()
                    case .disconnected, .error:
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(.red)
                        Text("Disconnected")
                            .foregroundColor(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                        
                List(peripherals) { peripheral in
                    Button(action: {
                        selectedPeripheral = peripheral
                        showSerialEntry = true
                    }) {
                        Text(peripheral.name ?? "Unknown Device")
                            
                    }
                }
                .onReceive(cgmService.$discoveredPeripherals) { list in
                    peripherals = list
                }
                .onAppear {
                    cgmService.startScanning()
                }
                .sheet(isPresented: $showSerialEntry) {
                    NavigationView {
                        Form {
                            Section(header: Text("Enter Serial Number")) {
                                TextField("Serial Number", text: $enteredSN)
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                            }
                        }
                        .navigationBarTitle("Serial Number", displayMode: .inline)
                        .navigationBarItems(
                            leading: Button("Cancel") {
                                showSerialEntry = false
                            },
                            trailing: Button("Connect") {
                                if let peripheral = selectedPeripheral {
                                    cgmService.connect(to: peripheral, withSN: enteredSN)
                                }
                            }
                        )
                    }
                }

                Spacer()

                if case .connected = cgmService.connectionState {
                    Text("Connected: \(cgmService.pendingSN ?? "")")
                        .font(.headline)
                        .padding()
                }
                Spacer()
            }
            .navigationBarTitle("Pair Your CGM", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Complete Later") {
                    session.needsCGMPairing = false
                }
                .foregroundColor(.secondary)
            )
            .onChange(of: cgmService.connectionState) { state in
                if case .connected = state, let uid = session.userId {
                    let cfgRef = db.collection("users").document(uid)
                        .collection("cgmConfig").document("info")
                    cfgRef.setData([
                        "sn": cgmService.pendingSN ?? "",
                        "peripheralID": cgmService.selectedPeripheralID?.uuidString ?? ""
                    ]) { error in
                        if let error = error {
                            print("Error saving CGM config: \(error)")
                        } else {
                            session.needsCGMPairing = false
                        }
                    }
                }
            }
        }
    }
}
