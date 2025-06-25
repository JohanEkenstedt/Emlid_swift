//
//  ContentView.swift
//  BluetoothScanner
//
//  Created by Johan Ekenstedt on 2025-06-17.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var scanner = BluetoothScanner()
    @StateObject private var viewModel: BluetoothViewModel
    
    init() {
        let scanner = BluetoothScanner()
        _scanner = StateObject(wrappedValue: scanner)
        _viewModel = StateObject(wrappedValue: BluetoothViewModel(scanner: scanner))
    }

    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    viewModel.restartScan()
                }) {
                    Label("Restart Scan", systemImage: "arrow.clockwise")
                }
                .padding()
                List(scanner.scannedPeripherals) { device in
                    NavigationLink(destination: DeviceServicesView(peripheral: device.peripheral, services: viewModel.connectedPeripheral?.identifier == device.peripheral.identifier ? viewModel.discoveredServices : [])) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(device.name)
                                .font(.headline)
                            Text("UUID: \(device.peripheral.identifier.uuidString)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("RSSI: \(device.rssi) dBm")
                                .font(.caption)
                                .foregroundColor(.blue)
                            if let manufacturerData = device.advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                                Text("Manufacturer Data: \(manufacturerData.map { String(format: "%02x", $0) }.joined())")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if let services = device.advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                                Text("Services: \(services.map(\.uuidString).joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onTapGesture {
                        print("Tapped on \(device.name ?? "Device")")
                        viewModel.connect(to: device.peripheral)
                    }
                }
                .navigationTitle("Bluetooth Devices")
            }
        }
    }
}

struct DeviceServicesView: View {
    let peripheral: CBPeripheral
    let services: [CBService]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Services for \(peripheral.name ?? "Device")")
                .font(.title2)
                .padding(.bottom)
            if services.isEmpty {
                Text("No services discovered or still discovering...")
                    .foregroundColor(.gray)
            } else {
                List(services, id: \.uuid) { service in
                    Text(service.uuid.uuidString)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
