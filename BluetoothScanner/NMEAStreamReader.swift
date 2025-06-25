import Foundation
import ExternalAccessory

struct ParsedNMEA {
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var fixQuality: Int?
    var satellites: Int?
    var hdop: Double?
    var horizontalAccuracy: Double?
    var verticalAccuracy: Double?
}

class NMEAStreamReader: NSObject, ObservableObject, StreamDelegate {
    private var session: EASession?
    @Published var nmeaLines: [String] = []
    @Published var parsed: ParsedNMEA = ParsedNMEA()
    @Published var isConnected: Bool = false
    @Published var secondsSinceLastData: Int = 0
    private var buffer = Data()
    private var dataTimeoutTimer: Timer?
    private let timeoutInterval: TimeInterval = 5.0
    private var sinceLastDataTimer: Timer?
    
    func connectToReachRX() {
        print("Trying to connect to Reach RX")
        let manager = EAAccessoryManager.shared()
        let accessories = manager.connectedAccessories
        guard let reachRX = accessories.first(where: { $0.protocolStrings.contains("com.emlid.nmea") }) else {
            print("Reach RX not found")
            isConnected = false
            return
        }
        session = EASession(accessory: reachRX, forProtocol: "com.emlid.nmea")
        session?.inputStream?.delegate = self
        session?.inputStream?.schedule(in: .current, forMode: .default)
        session?.inputStream?.open()
        isConnected = true
        resetTimeoutTimer()
        startSinceLastDataTimer()
        print("Connected to Reach RX NMEA stream")
    }
    
    func disconnect() {
        print("Trying to disconnect from Reach RX NMEA stream")
        session?.inputStream?.close()
        session?.outputStream?.close()
        session = nil
        isConnected = false
        dataTimeoutTimer?.invalidate()
        sinceLastDataTimer?.invalidate()
        print("Disconnected from Reach RX NMEA stream")
    }
    
    private func resetTimeoutTimer() {
        dataTimeoutTimer?.invalidate()
        dataTimeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        secondsSinceLastData = 0
    }
    
    private func startSinceLastDataTimer() {
        sinceLastDataTimer?.invalidate()
        sinceLastDataTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secondsSinceLastData += 1
            }
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let inputStream = aStream as? InputStream else { return }
        if eventCode == .hasBytesAvailable {
            var tempBuffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = inputStream.read(&tempBuffer, maxLength: tempBuffer.count)
            if bytesRead > 0 {
                buffer.append(tempBuffer, count: bytesRead)
                while let range = buffer.range(of: Data([0x0D, 0x0A])) { // \r\n
                    let lineData = buffer.subdata(in: 0..<range.lowerBound)
                    if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                        DispatchQueue.main.async {
                            self.nmeaLines.append(line)
                            self.parseNMEA(line)
                            self.resetTimeoutTimer()
                            self.isConnected = true
                            self.secondsSinceLastData = 0
                        }
                    }
                    buffer.removeSubrange(0..<range.upperBound)
                }
            }
        }
    }
    
    func parseNMEA(_ line: String) {
        let fields = line.components(separatedBy: ",")
        if line.hasPrefix("$GNGGA") || line.hasPrefix("$GPGGA") {
            // $GNGGA,time,lat,N,lon,E,fix,sats,hdop,alt,M,...
            guard fields.count > 9 else { return }
            let lat = parseLat(fields[2], fields[3])
            let lon = parseLon(fields[4], fields[5])
            let fix = Int(fields[6])
            let sats = Int(fields[7])
            let hdop = Double(fields[8])
            let alt = Double(fields[9])
            DispatchQueue.main.async {
                self.parsed.latitude = lat
                self.parsed.longitude = lon
                self.parsed.altitude = alt
                self.parsed.fixQuality = fix
                self.parsed.satellites = sats
                self.parsed.hdop = hdop
            }
        } else if line.hasPrefix("$GNGST") {
            // $GNGST,time,rangeRMS,,,...,sigmaLat,sigmaLon,sigmaAlt*hh
            // Example: $GNGST,062641.20,25.000,,,,0.620,0.970,1.100*5F
            guard fields.count > 8 else { return }
            let sigmaLat = Double(fields[6])
            let sigmaLon = Double(fields[7])
            let sigmaAlt = Double(fields[8].split(separator: "*").first ?? "")
            DispatchQueue.main.async {
                self.parsed.horizontalAccuracy = sigmaLon
                self.parsed.verticalAccuracy = sigmaAlt
            }
        }
    }
    
    private func parseLat(_ lat: String, _ hemi: String) -> Double? {
        guard let d = Double(lat), !lat.isEmpty else { return nil }
        let deg = floor(d / 100)
        let min = d - deg * 100
        var coord = deg + min / 60
        if hemi == "S" { coord = -coord }
        return coord
    }
    private func parseLon(_ lon: String, _ hemi: String) -> Double? {
        guard let d = Double(lon), !lon.isEmpty else { return nil }
        let deg = floor(d / 100)
        let min = d - deg * 100
        var coord = deg + min / 60
        if hemi == "W" { coord = -coord }
        return coord
    }
}
