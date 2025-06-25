//
//  BluetoothViewModel.swift
//  BluetoothScanner
//
//  Created by Johan Ekenstedt on 2025-06-17.
//

import Foundation
import Combine
import CoreBluetooth

@MainActor
class BluetoothViewModel: ObservableObject {
    @Published var discoveredNames: [String] = []
    @Published var connectedPeripheral: CBPeripheral? = nil
    @Published var discoveredServices: [CBService] = []
    
    private var scanner: BluetoothScanner
    private var cancellables = Set<AnyCancellable>()
    
    init(scanner: BluetoothScanner) {
        self.scanner = scanner
        scanner.$scannedPeripherals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scanned in
                self?.discoveredNames = scanned.map { $0.name }
            }
            .store(in: &cancellables)
        scanner.$connectedPeripheral
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectedPeripheral)
        scanner.$discoveredServices
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredServices)
    }
    
    func restartScan() {
        scanner.restartScan()
    }
    
    func connect(to peripheral: CBPeripheral) {
        scanner.connect(to: peripheral)
    }
}
