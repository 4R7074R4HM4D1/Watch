//
//  SensorManager.swift
//  SensorCollector
//
//  Created on 2024
//

import Foundation
import CoreMotion
import Combine

class SensorManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var simulationTimer: Timer?
    private var isSimulating = false
    
    @Published var totalSamples = 0
    @Published var statusMessage = "Ready"
    @Published var availableSensors: [String] = []
    
    // Individual sensor sample counts
    @Published var accelerometerSamples = 0
    @Published var gyroscopeSamples = 0
    @Published var magnetometerSamples = 0
    @Published var deviceMotionSamples = 0
    @Published var altimeterSamples = 0
    
    // Data storage
    private var accelerometerData: [SensorDataPoint] = []
    private var gyroscopeData: [SensorDataPoint] = []
    private var magnetometerData: [SensorDataPoint] = []
    private var deviceMotionData: [DeviceMotionDataPoint] = []
    private var altimeterData: [AltimeterDataPoint] = []
    private var altimeter: CMAltimeter?
    
    private let dataQueue = DispatchQueue(label: "sensorDataQueue", attributes: .concurrent)
    
    // Maximum update intervals for highest frequency
    private let accelerometerUpdateInterval: TimeInterval = 1.0 / 100.0  // 100 Hz
    private let gyroscopeUpdateInterval: TimeInterval = 1.0 / 100.0      // 100 Hz
    private let magnetometerUpdateInterval: TimeInterval = 1.0 / 50.0    // 50 Hz
    private let deviceMotionUpdateInterval: TimeInterval = 1.0 / 100.0   // 100 Hz
    
    var isCollecting: Bool {
        return isSimulating ||
               motionManager.isAccelerometerActive || 
               motionManager.isGyroActive || 
               motionManager.isMagnetometerActive ||
               motionManager.isDeviceMotionActive
    }
    
    func startCollection() {
        // Clear previous data
        clearData()
        
        // Check if we're on simulator (sensors may not work)
        #if targetEnvironment(simulator)
        print("⚠️ Running on Simulator - starting simulation mode")
        DispatchQueue.main.async { [weak self] in
            self?.statusMessage = "🧪 Simulator Mode\nGenerating test data"
        }
        startSimulation()
        return
        #endif
        
        var sensorsStarted: [String] = []
        
        // Diagnostic: Check what's available
        print("📱 Sensor Availability Check:")
        print("   Accelerometer: \(motionManager.isAccelerometerAvailable ? "✅" : "❌")")
        print("   Gyroscope: \(motionManager.isGyroAvailable ? "✅" : "❌")")
        print("   Magnetometer: \(motionManager.isMagnetometerAvailable ? "✅" : "❌")")
        print("   Device Motion: \(motionManager.isDeviceMotionAvailable ? "✅" : "❌")")
        print("   Altimeter: \(CMAltimeter.isRelativeAltitudeAvailable() ? "✅" : "❌")")
        
        // On watchOS, Device Motion takes priority and includes gyroscope/magnetometer data
        // We'll extract that data into separate arrays
        let useDeviceMotion = motionManager.isDeviceMotionAvailable
        
        // Check and start accelerometer (can work alongside Device Motion)
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = accelerometerUpdateInterval
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                if let error = error {
                    print("❌ Accelerometer error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else { return }
                self?.addAccelerometerData(data)
            }
            sensorsStarted.append("Accelerometer")
            print("✅ Accelerometer started")
        } else {
            print("⚠️ Accelerometer not available")
        }
        
        // Only start individual gyroscope if Device Motion is NOT available
        // (Device Motion includes rotation rate, so we'll extract it from there)
        if !useDeviceMotion && motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = gyroscopeUpdateInterval
            motionManager.startGyroUpdates(to: .main) { [weak self] (data, error) in
                if let error = error {
                    print("❌ Gyroscope error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else { return }
                self?.addGyroscopeData(data)
            }
            sensorsStarted.append("Gyroscope")
            print("✅ Gyroscope started (standalone)")
        } else if useDeviceMotion {
            sensorsStarted.append("Gyroscope (from Device Motion)")
            print("ℹ️  Gyroscope data will be extracted from Device Motion")
        } else {
            print("⚠️ Gyroscope not available")
        }
        
        // Only start individual magnetometer if Device Motion is NOT available
        // (Device Motion includes magnetic field, so we'll extract it from there)
        if !useDeviceMotion && motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = magnetometerUpdateInterval
            motionManager.startMagnetometerUpdates(to: .main) { [weak self] (data, error) in
                if let error = error {
                    print("❌ Magnetometer error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else { return }
                self?.addMagnetometerData(data)
            }
            sensorsStarted.append("Magnetometer")
            print("✅ Magnetometer started (standalone)")
        } else if useDeviceMotion {
            sensorsStarted.append("Magnetometer (from Device Motion)")
            print("ℹ️  Magnetometer data will be extracted from Device Motion")
        } else {
            print("⚠️ Magnetometer not available")
        }
        
        // Start device motion (includes attitude, rotation rate, gravity, user acceleration, magnetic field)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = deviceMotionUpdateInterval
            
            // Use xArbitraryZVertical as default (most compatible with watchOS)
            // This reference frame is always available on watchOS
            let referenceFrame: CMAttitudeReferenceFrame = .xArbitraryZVertical
            
            motionManager.startDeviceMotionUpdates(using: referenceFrame, to: .main) { [weak self] (data, error) in
                if let error = error {
                    print("❌ Device Motion error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else { return }
                self?.addDeviceMotionData(data)
            }
            sensorsStarted.append("Device Motion")
            print("✅ Device Motion started with reference frame: xArbitraryZVertical")
        } else {
            print("⚠️ Device Motion not available")
        }
        
        // Start altimeter if available (for watchOS)
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter = CMAltimeter()
            altimeter?.startRelativeAltitudeUpdates(to: .main) { [weak self] (data, error) in
                if let error = error {
                    print("❌ Altimeter error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else { return }
                self?.addAltimeterData(data)
            }
            sensorsStarted.append("Altimeter")
            print("✅ Altimeter started")
        } else {
            print("⚠️ Altimeter not available")
        }
        
        // Update status
        DispatchQueue.main.async { [weak self] in
            self?.availableSensors = sensorsStarted
            if sensorsStarted.isEmpty {
                self?.statusMessage = "⚠️ No sensors available"
            } else {
                self?.statusMessage = "✅ \(sensorsStarted.count) sensor(s) active"
            }
        }
        
        print("📊 Started collection from \(sensorsStarted.count) sensor(s): \(sensorsStarted.joined(separator: ", "))")
        
        // Important note about Device Motion
        if sensorsStarted.contains("Device Motion") {
            print("ℹ️  Note: Gyroscope and Magnetometer data are being extracted from Device Motion")
        }
    }
    
    func stopCollection() {
        // Stop simulation if running
        if isSimulating {
            stopSimulation()
        }
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        altimeter?.stopRelativeAltitudeUpdates()
        altimeter = nil
    }
    
    // MARK: - Simulation Mode (for Simulator)
    
    private func startSimulation() {
        isSimulating = true
        let startTime = Date().timeIntervalSince1970
        var sampleCount: Int = 0
        
        // Update available sensors for simulation
        DispatchQueue.main.async { [weak self] in
            self?.availableSensors = ["Accelerometer (Simulated)", "Gyroscope (Simulated)", "Device Motion (Simulated)"]
            self?.statusMessage = "🧪 Simulator Mode\nGenerating test data"
        }
        
        // Generate simulated data at 100 Hz (every 0.01 seconds)
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self, self.isSimulating else {
                timer.invalidate()
                return
            }
            
            let currentTime = Date().timeIntervalSince1970
            let timestamp = currentTime
            
            // Generate realistic-looking sensor data with some variation
            let time = currentTime
            let frequency = 2.0 // Hz for oscillation
            
            // Simulated accelerometer data (sine wave with noise)
            let accelX = 0.1 * sin(time * frequency * 2 * .pi) + Double.random(in: -0.05...0.05)
            let accelY = 0.15 * cos(time * frequency * 2 * .pi) + Double.random(in: -0.05...0.05)
            let accelZ = -1.0 + 0.1 * sin(time * frequency * 1.5 * 2 * .pi) + Double.random(in: -0.05...0.05)
            
            // Simulated gyroscope data
            let gyroX = 0.5 * sin(time * frequency * 1.2 * 2 * .pi) + Double.random(in: -0.1...0.1)
            let gyroY = 0.3 * cos(time * frequency * 1.3 * 2 * .pi) + Double.random(in: -0.1...0.1)
            let gyroZ = 0.2 * sin(time * frequency * 1.1 * 2 * .pi) + Double.random(in: -0.1...0.1)
            
            // Add simulated data
            self.dataQueue.async(flags: .barrier) {
                // Accelerometer
                self.accelerometerData.append(SensorDataPoint(
                    timestamp: timestamp,
                    x: accelX,
                    y: accelY,
                    z: accelZ
                ))
                
                // Gyroscope
                self.gyroscopeData.append(SensorDataPoint(
                    timestamp: timestamp,
                    x: gyroX,
                    y: gyroY,
                    z: gyroZ
                ))
                
                // Device Motion (includes all sensor data)
                self.deviceMotionData.append(DeviceMotionDataPoint(
                    timestamp: timestamp,
                    attitude: AttitudeData(
                        roll: 0.1 * sin(time * frequency * 2 * .pi),
                        pitch: 0.15 * cos(time * frequency * 2 * .pi),
                        yaw: 0.2 * sin(time * frequency * 1.5 * 2 * .pi)
                    ),
                    rotationRate: SensorDataPoint(
                        timestamp: timestamp,
                        x: gyroX,
                        y: gyroY,
                        z: gyroZ
                    ),
                    gravity: SensorDataPoint(
                        timestamp: timestamp,
                        x: 0.0,
                        y: 0.0,
                        z: -1.0
                    ),
                    userAcceleration: SensorDataPoint(
                        timestamp: timestamp,
                        x: accelX,
                        y: accelY,
                        z: accelZ
                    ),
                    magneticField: SensorDataPoint(
                        timestamp: timestamp,
                        x: 20.0 + Double.random(in: -2...2),
                        y: 30.0 + Double.random(in: -2...2),
                        z: 40.0 + Double.random(in: -2...2)
                    )
                ))
            }
            
            // Update sample counts on main thread
            sampleCount += 3 // 3 sensors per update
            DispatchQueue.main.async {
                self.totalSamples = sampleCount
                self.accelerometerSamples += 1
                self.gyroscopeSamples += 1
                self.deviceMotionSamples += 1
            }
        }
        
        print("🧪 Simulation mode started - generating test sensor data at 100 Hz")
    }
    
    private func stopSimulation() {
        isSimulating = false
        simulationTimer?.invalidate()
        simulationTimer = nil
        print("🧪 Simulation mode stopped")
    }
    
    private func clearData() {
        dataQueue.async(flags: .barrier) {
            self.accelerometerData.removeAll()
            self.gyroscopeData.removeAll()
            self.magnetometerData.removeAll()
            self.deviceMotionData.removeAll()
            self.altimeterData.removeAll()
        }
        DispatchQueue.main.async { [weak self] in
            self?.totalSamples = 0
            self?.accelerometerSamples = 0
            self?.gyroscopeSamples = 0
            self?.magnetometerSamples = 0
            self?.deviceMotionSamples = 0
            self?.altimeterSamples = 0
        }
    }
    
    private func addAccelerometerData(_ data: CMAccelerometerData) {
        dataQueue.async(flags: .barrier) {
            let point = SensorDataPoint(
                timestamp: data.timestamp,
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z
            )
            self.accelerometerData.append(point)
            DispatchQueue.main.async {
                self.totalSamples += 1
                self.accelerometerSamples += 1
            }
        }
    }
    
    private func addGyroscopeData(_ data: CMGyroData) {
        dataQueue.async(flags: .barrier) {
            let point = SensorDataPoint(
                timestamp: data.timestamp,
                x: data.rotationRate.x,
                y: data.rotationRate.y,
                z: data.rotationRate.z
            )
            self.gyroscopeData.append(point)
            DispatchQueue.main.async {
                self.totalSamples += 1
                self.gyroscopeSamples += 1
            }
        }
    }
    
    private func addMagnetometerData(_ data: CMMagnetometerData) {
        dataQueue.async(flags: .barrier) {
            let point = SensorDataPoint(
                timestamp: data.timestamp,
                x: data.magneticField.x,
                y: data.magneticField.y,
                z: data.magneticField.z
            )
            self.magnetometerData.append(point)
            DispatchQueue.main.async {
                self.totalSamples += 1
                self.magnetometerSamples += 1
            }
        }
    }
    
    private func addDeviceMotionData(_ data: CMDeviceMotion) {
        dataQueue.async(flags: .barrier) {
            let timestamp = data.timestamp
            
            // Extract rotation rate (gyroscope data) from Device Motion
            let gyroPoint = SensorDataPoint(
                timestamp: timestamp,
                x: data.rotationRate.x,
                y: data.rotationRate.y,
                z: data.rotationRate.z
            )
            self.gyroscopeData.append(gyroPoint)
            
            // Extract magnetic field (magnetometer data) from Device Motion
            // Accept all magnetic field data (even uncalibrated - it's still useful)
            let magPoint = SensorDataPoint(
                timestamp: timestamp,
                x: data.magneticField.field.x,
                y: data.magneticField.field.y,
                z: data.magneticField.field.z
            )
            self.magnetometerData.append(magPoint)
            
            // Store full Device Motion data
            let point = DeviceMotionDataPoint(
                timestamp: timestamp,
                attitude: AttitudeData(
                    roll: data.attitude.roll,
                    pitch: data.attitude.pitch,
                    yaw: data.attitude.yaw
                ),
                rotationRate: SensorDataPoint(
                    timestamp: timestamp,
                    x: data.rotationRate.x,
                    y: data.rotationRate.y,
                    z: data.rotationRate.z
                ),
                gravity: SensorDataPoint(
                    timestamp: timestamp,
                    x: data.gravity.x,
                    y: data.gravity.y,
                    z: data.gravity.z
                ),
                userAcceleration: SensorDataPoint(
                    timestamp: timestamp,
                    x: data.userAcceleration.x,
                    y: data.userAcceleration.y,
                    z: data.userAcceleration.z
                ),
                magneticField: SensorDataPoint(
                    timestamp: timestamp,
                    x: data.magneticField.field.x,
                    y: data.magneticField.field.y,
                    z: data.magneticField.field.z
                )
            )
            self.deviceMotionData.append(point)
            
            // Update sample counts (Device Motion adds to multiple arrays)
            DispatchQueue.main.async {
                self.totalSamples += 1
                self.deviceMotionSamples += 1
                self.gyroscopeSamples += 1
                self.magnetometerSamples += 1
            }
        }
    }
    
    private func addAltimeterData(_ data: CMAltitudeData) {
        dataQueue.async(flags: .barrier) {
            let point = AltimeterDataPoint(
                timestamp: Date().timeIntervalSince1970,
                relativeAltitude: data.relativeAltitude.doubleValue,
                pressure: data.pressure.doubleValue
            )
            self.altimeterData.append(point)
            DispatchQueue.main.async {
                self.totalSamples += 1
                self.altimeterSamples += 1
            }
        }
    }
    
    func getAllData() -> SensorSessionData {
        return dataQueue.sync {
            SensorSessionData(
                accelerometer: accelerometerData,
                gyroscope: gyroscopeData,
                magnetometer: magnetometerData,
                deviceMotion: deviceMotionData,
                altimeter: altimeterData,
                startTime: Date()
            )
        }
    }
    
    func getAccelerometerData() -> [SensorDataPoint] {
        return dataQueue.sync {
            return accelerometerData
        }
    }
}

// MARK: - Data Models

struct SensorDataPoint: Codable {
    let timestamp: TimeInterval
    let x: Double
    let y: Double
    let z: Double
}

struct AttitudeData: Codable {
    let roll: Double
    let pitch: Double
    let yaw: Double
}

struct DeviceMotionDataPoint: Codable {
    let timestamp: TimeInterval
    let attitude: AttitudeData
    let rotationRate: SensorDataPoint
    let gravity: SensorDataPoint
    let userAcceleration: SensorDataPoint
    let magneticField: SensorDataPoint
}

struct AltimeterDataPoint: Codable {
    let timestamp: TimeInterval
    let relativeAltitude: Double
    let pressure: Double
}

struct SensorSessionData: Codable {
    let accelerometer: [SensorDataPoint]
    let gyroscope: [SensorDataPoint]
    let magnetometer: [SensorDataPoint]
    let deviceMotion: [DeviceMotionDataPoint]
    let altimeter: [AltimeterDataPoint]
    let startTime: Date
}

