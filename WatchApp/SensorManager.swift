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
    
    @Published var totalSamples = 0
    @Published var statusMessage = "Ready"
    @Published var availableSensors: [String] = []
    
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
        return motionManager.isAccelerometerActive || 
               motionManager.isGyroActive || 
               motionManager.isMagnetometerActive ||
               motionManager.isDeviceMotionActive
    }
    
    func startCollection() {
        // Clear previous data
        clearData()
        
        var sensorsStarted: [String] = []
        
        // Check and start accelerometer
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
        
        // Check and start gyroscope
        if motionManager.isGyroAvailable {
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
            print("✅ Gyroscope started")
        } else {
            print("⚠️ Gyroscope not available")
        }
        
        // Check and start magnetometer
        if motionManager.isMagnetometerAvailable {
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
            print("✅ Magnetometer started")
        } else {
            print("⚠️ Magnetometer not available")
        }
        
        // Start device motion (includes attitude, rotation rate, gravity, user acceleration, magnetic field)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = deviceMotionUpdateInterval
            
            // Try to find an available reference frame
            let availableFrames = CMAttitudeReferenceFrame.available
            var referenceFrame: CMAttitudeReferenceFrame = .xMagneticNorthZVertical
            
            // Prefer xMagneticNorthZVertical, fallback to others
            if availableFrames.contains(.xMagneticNorthZVertical) {
                referenceFrame = .xMagneticNorthZVertical
            } else if availableFrames.contains(.xArbitraryZVertical) {
                referenceFrame = .xArbitraryZVertical
            } else if availableFrames.contains(.xArbitraryCorrectedZVertical) {
                referenceFrame = .xArbitraryCorrectedZVertical
            }
            
            motionManager.startDeviceMotionUpdates(using: referenceFrame, to: .main) { [weak self] (data, error) in
                if let error = error {
                    print("❌ Device Motion error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else { return }
                self?.addDeviceMotionData(data)
            }
            sensorsStarted.append("Device Motion")
            print("✅ Device Motion started with reference frame: \(referenceFrame.rawValue)")
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
                self?.statusMessage = "⚠️ No sensors available\n(Use physical Apple Watch)"
            } else {
                let sensorList = sensorsStarted.joined(separator: ", ")
                self?.statusMessage = "✅ \(sensorsStarted.count) sensor(s) active:\n\(sensorList)"
                
                // Note about Device Motion including gyro data
                if sensorsStarted.contains("Device Motion") && !sensorsStarted.contains("Gyroscope") {
                    self?.statusMessage += "\n(Device Motion includes rotation rate)"
                }
            }
        }
        
        print("📊 Started collection from \(sensorsStarted.count) sensor(s): \(sensorsStarted.joined(separator: ", "))")
        
        // Important note about Device Motion
        if sensorsStarted.contains("Device Motion") {
            print("ℹ️  Note: Device Motion includes rotation rate (gyroscope-like data) even if Gyroscope sensor is not available")
        }
    }
    
    func stopCollection() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        altimeter?.stopRelativeAltitudeUpdates()
        altimeter = nil
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
            }
        }
    }
    
    private func addDeviceMotionData(_ data: CMDeviceMotion) {
        dataQueue.async(flags: .barrier) {
            let point = DeviceMotionDataPoint(
                timestamp: data.timestamp,
                attitude: AttitudeData(
                    roll: data.attitude.roll,
                    pitch: data.attitude.pitch,
                    yaw: data.attitude.yaw
                ),
                rotationRate: SensorDataPoint(
                    timestamp: data.timestamp,
                    x: data.rotationRate.x,
                    y: data.rotationRate.y,
                    z: data.rotationRate.z
                ),
                gravity: SensorDataPoint(
                    timestamp: data.timestamp,
                    x: data.gravity.x,
                    y: data.gravity.y,
                    z: data.gravity.z
                ),
                userAcceleration: SensorDataPoint(
                    timestamp: data.timestamp,
                    x: data.userAcceleration.x,
                    y: data.userAcceleration.y,
                    z: data.userAcceleration.z
                ),
                magneticField: SensorDataPoint(
                    timestamp: data.timestamp,
                    x: data.magneticField.field.x,
                    y: data.magneticField.field.y,
                    z: data.magneticField.field.z
                )
            )
            self.deviceMotionData.append(point)
            DispatchQueue.main.async {
                self.totalSamples += 1
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

