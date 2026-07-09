import SwiftUI
import CoreBluetooth

/// A discovered Bluetooth kitchen scale (or the built-in simulated one).
struct ScaleDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let isSimulated: Bool

    static let simulated = ScaleDevice(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000FAB")!,
        name: "Demo Scale", isSimulated: true)
}

enum ScaleConnectionState: Equatable {
    case idle, scanning, connecting, connected, bluetoothUnavailable
}

/// Live connection to a Bluetooth digital food scale.
///
/// Speaks the standard GATT Weight Scale service (0x181D, Weight Measurement 0x2A9D),
/// which covers spec-compliant kitchen scales; vendor-specific protocols can be added in
/// `peripheral(_:didUpdateValueFor:)`. A simulated device is always offered so the
/// weigh-to-log flow works in demo mode, on the simulator, and without hardware.
///
/// Weight readings are software-tared: `tare()` zeroes the current raw reading and
/// `grams` reports net weight from then on.
@Observable
final class SmartScaleService: NSObject {

    private(set) var state: ScaleConnectionState = .idle
    private(set) var discovered: [ScaleDevice] = []
    private(set) var connectedDevice: ScaleDevice?

    /// Net weight in grams (raw − tare), nil until the first reading arrives.
    private(set) var grams: Double?
    /// True once the reading has settled (±1 g for ~1.5 s) — the moment worth logging.
    private(set) var isStable = false

    private var rawGrams: Double?
    private var tareOffset: Double = 0
    private var lastChange = Date.distantPast
    private var stabilityTask: Task<Void, Never>?

    private var central: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var simulatorTask: Task<Void, Never>?

    private static let weightScaleService = CBUUID(string: "181D")
    private static let weightMeasurement = CBUUID(string: "2A9D")

    var statusDescription: String {
        switch state {
        case .connected: return "Connected to \(connectedDevice?.name ?? "scale")"
        case .connecting: return "Connecting…"
        case .scanning: return "Searching for scales…"
        case .bluetoothUnavailable: return "Bluetooth is off or unavailable"
        case .idle: return "Not connected"
        }
    }

    // MARK: - Public API

    func startScanning() {
        discovered = [.simulated]
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main)
        }
        guard let central, central.state == .poweredOn else {
            state = central?.state == .poweredOn ? .scanning : state
            return   // scanning kicks off in centralManagerDidUpdateState
        }
        state = .scanning
        central.scanForPeripherals(withServices: [Self.weightScaleService])
    }

    func stopScanning() {
        central?.stopScan()
        if state == .scanning { state = .idle }
    }

    func connect(_ device: ScaleDevice) {
        stopScanning()
        resetReading()
        connectedDevice = device

        if device.isSimulated {
            state = .connected
            startSimulator()
            return
        }
        guard let central, let peripheral = peripherals[device.id] else {
            state = .idle
            connectedDevice = nil
            return
        }
        state = .connecting
        central.connect(peripheral)
    }

    func disconnect() {
        simulatorTask?.cancel()
        simulatorTask = nil
        stabilityTask?.cancel()
        stabilityTask = nil
        if let connectedPeripheral {
            central?.cancelPeripheralConnection(connectedPeripheral)
        }
        connectedPeripheral = nil
        connectedDevice = nil
        resetReading()
        state = .idle
    }

    /// Software tare: zero out whatever is on the platform right now.
    func tare() {
        tareOffset = rawGrams ?? 0
        updateNet()
    }

    // MARK: - Reading pipeline

    private func resetReading() {
        rawGrams = nil
        grams = nil
        tareOffset = 0
        isStable = false
    }

    private func ingest(rawGrams value: Double) {
        if let previous = rawGrams, abs(previous - value) > 1 {
            lastChange = .now
            isStable = false
        } else if rawGrams == nil {
            lastChange = .now
        }
        rawGrams = value
        updateNet()
        armStabilityCheck()
    }

    private func updateNet() {
        guard let rawGrams else { return }
        grams = max(0, rawGrams - tareOffset)
    }

    private func armStabilityCheck() {
        stabilityTask?.cancel()
        stabilityTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard let self, !Task.isCancelled else { return }
            if Date.now.timeIntervalSince(self.lastChange) >= 1.4, self.grams != nil {
                self.isStable = true
            }
        }
    }

    // MARK: - Simulated device

    private func startSimulator() {
        simulatorTask?.cancel()
        simulatorTask = Task { [weak self] in
            let target = Double(Int.random(in: 120...320))
            var current = 0.0
            while !Task.isCancelled {
                guard let self else { return }
                if abs(current - target) > 2 {
                    current += (target - current) * 0.35 + Double.random(in: -1.5...1.5)
                } else {
                    current = target + Double.random(in: -0.4...0.4)
                }
                self.ingest(rawGrams: max(0, current))
                try? await Task.sleep(for: .milliseconds(220))
            }
        }
    }

    // MARK: - GATT parsing

    /// Bluetooth SIG Weight Measurement (0x2A9D): flags byte, then UInt16 LE weight with
    /// 0.005 kg resolution (SI) or 0.01 lb resolution (imperial, flag bit 0).
    private func parseWeightMeasurement(_ data: Data) -> Double? {
        guard data.count >= 3 else { return nil }
        let flags = data[0]
        let raw = UInt16(data[1]) | (UInt16(data[2]) << 8)
        guard raw != 0xFFFF else { return nil }
        let imperial = flags & 0x01 != 0
        return imperial
            ? Double(raw) * 0.01 * 453.592
            : Double(raw) * 0.005 * 1000
    }
}

// MARK: - CoreBluetooth delegates

extension SmartScaleService: CBCentralManagerDelegate, CBPeripheralDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if state == .bluetoothUnavailable { state = .idle }
            if state == .scanning || state == .idle {
                state = .scanning
                central.scanForPeripherals(withServices: [Self.weightScaleService])
            }
        case .unauthorized, .poweredOff, .unsupported:
            state = .bluetoothUnavailable
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral
        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "Scale \(peripheral.identifier.uuidString.prefix(4))"
        let device = ScaleDevice(id: peripheral.identifier, name: name, isSimulated: false)
        if !discovered.contains(device) {
            discovered.append(device)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        state = .connected
        peripheral.discoverServices([Self.weightScaleService])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        connectedDevice = nil
        state = .idle
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        if peripheral.identifier == connectedPeripheral?.identifier {
            connectedPeripheral = nil
            connectedDevice = nil
            resetReading()
            state = .idle
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid == Self.weightScaleService {
            peripheral.discoverCharacteristics([Self.weightMeasurement], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? []
        where characteristic.uuid == Self.weightMeasurement {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == Self.weightMeasurement,
              let data = characteristic.value,
              let grams = parseWeightMeasurement(data) else { return }
        ingest(rawGrams: grams)
    }
}
