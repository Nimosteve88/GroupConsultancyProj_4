//
//  CGMService+AutoReconnect.swift
//  type2DProj
//
//  Created by Nimo, Steve on 09/06/2025.
//

import CoreBluetooth

extension CGMService {
    func attemptAutoReconnect(using config: (sn: String, peripheralID: UUID)) {
        let peripherals = centralManager
            .retrievePeripherals(withIdentifiers: [config.peripheralID])
        if let cbPeripheral = peripherals.first {
            let wrapper = Peripheral(id: config.peripheralID,
                                     name: config.sn,
                                     peripheral: cbPeripheral)
            connect(to: wrapper, withSN: config.sn)
        } else {
            startScanning()
        }
    }
}
