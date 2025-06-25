//
//  ContentView.swift
//  BluetoothScanner
//
//  Created by Johan Ekenstedt on 2025-06-17.
//

import SwiftUI
import CoreLocation
import ExternalAccessory

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Received location: \(location.coordinate.latitude), \(location.coordinate.longitude), acc: \((location.horizontalAccuracy))")
        lastLocation = location

        // iOS 15+ only
        if #available(iOS 15.0, *) {
            if let sourceInfo = location.sourceInformation {
                if sourceInfo.isSimulatedBySoftware {
                    print("Location is simulated (mock location)")
                } else if sourceInfo.isProducedByAccessory {
                    print("Location is from EXTERNAL GNSS (e.g., Reach RX)")
                } else {
                    print("Location is from INTERNAL GNSS")
                }
            } else {
                print("No source information available (likely internal GNSS)")
            }
        } else {
            print("iOS version too old for sourceInformation; cannot determine source.")
        }
    }
}

struct ContentView: View {
    @StateObject var nmeaReader = NMEAStreamReader()
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(nmeaReader.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(nmeaReader.isConnected ? "Emlid Connected" : "Emlid Disconnected")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                Spacer()
                Text("Last data: \(nmeaReader.secondsSinceLastData) s ago")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Button(nmeaReader.isConnected ? "Disconnect to Reach RX" : "Connect to Reach RX") {
                if nmeaReader.isConnected {
                    nmeaReader.disconnect()
                } else {
                    nmeaReader.connectToReachRX()
                }
            }
            if let lat = nmeaReader.parsed.latitude, let lon = nmeaReader.parsed.longitude {
                Text("Latitude: \(lat)")
                Text("Longitude: \(lon)")
            }
            if let alt = nmeaReader.parsed.altitude {
                Text("Altitude: \(alt) m")
            }
            if let fix = nmeaReader.parsed.fixQuality {
                Text("Fix Quality: \(fix)")
            }
            if let sats = nmeaReader.parsed.satellites {
                Text("Satellites: \(sats)")
            }
            if let hdop = nmeaReader.parsed.hdop {
                Text("HDOP: \(hdop)")
            }
            if let hacc = nmeaReader.parsed.horizontalAccuracy {
                Text("Horizontal Accuracy: \(hacc) m")
            }
            if let vacc = nmeaReader.parsed.verticalAccuracy {
                Text("Vertical Accuracy: \(vacc) m")
            }
            Divider()
            Text("Raw NMEA (last 10 lines):")
                .font(.headline)
            List(nmeaReader.nmeaLines.suffix(10), id: \.self) { line in
                Text(line)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
