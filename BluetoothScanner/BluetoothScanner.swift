//
//  BluetoothScanner.swift
//  BluetoothScanner
//
//  Created by Johan Ekenstedt on 2025-06-17.
//

import CoreBluetooth

struct ScannedPeripheral: Identifiable {
    var id: UUID { peripheral.identifier }
    let peripheral: CBPeripheral
    let rssi: Int
    let name: String
    let advertisementData: [String: Any]
}

class BluetoothScanner: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    
    @Published var scannedPeripherals: [ScannedPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var discoveredServices: [CBService] = []

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        guard !scannedPeripherals.contains(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            return
        }

        let device = ScannedPeripheral(
            peripheral: peripheral,
            rssi: RSSI.intValue,
            name: advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Unnamed Device",
            advertisementData: advertisementData
        )

        DispatchQueue.main.async {
            self.scannedPeripherals.append(device)
            self.scannedPeripherals.sort { $0.rssi > $1.rssi }
        }
    }

    func restartScan() {
        scannedPeripherals.removeAll()
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            DispatchQueue.main.async {
                self.discoveredServices = services
            }
        }
    }
}
