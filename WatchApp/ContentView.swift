//
//  ContentView.swift
//  SensorCollector
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var dataManager = DataManager()
    @State private var isRecording = false
    @State private var sessionStartTime: Date?
    @State private var showingUploadStatus = false
    @State private var uploadMessage = ""
    @State private var showingGraph = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
            // Session timer - Fitness app style (smaller)
            if let startTime = sessionStartTime {
                VStack(spacing: 1) {
                    Text(formatDuration(startTime))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Ready")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // Server configuration (IP and Port)
            VStack(spacing: 2) {
                Text("Server")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    TextField("IP", text: $dataManager.serverHost)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.leading)
                    Text(":")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("Port", text: $dataManager.serverPort)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 40)
                }
            }
            .padding(.top, 2)
            
            // Sensor rings - Fitness app style (smaller)
            if isRecording {
                VStack(spacing: 4) {
                    // Top row - 2 rings
                    HStack(spacing: 8) {
                        SensorRing(
                            value: sensorManager.accelerometerSamples,
                            color: .red,
                            label: "Accel"
                        )
                        SensorRing(
                            value: sensorManager.gyroscopeSamples,
                            color: .green,
                            label: "Gyro"
                        )
                    }
                    
                    // Bottom row - 2 rings
                    HStack(spacing: 8) {
                        SensorRing(
                            value: sensorManager.magnetometerSamples,
                            color: .blue,
                            label: "Mag"
                        )
                        SensorRing(
                            value: sensorManager.deviceMotionSamples,
                            color: .orange,
                            label: "Motion"
                        )
                    }
                }
            }
            
            Spacer(minLength: 4)
            
            // Start/Stop button - Fitness app style
            Button(action: {
                if isRecording {
                    stopSession()
                } else {
                    startSession()
                }
            }) {
                Text(isRecording ? "Stop" : "Start")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isRecording ? Color.red : Color.green)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Upload status
            if showingUploadStatus {
                Text(uploadMessage)
                    .font(.caption2)
                    .foregroundColor(uploadMessage.contains("Success") ? .green : .red)
            }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        if value.translation.width > 0 && abs(value.translation.height) < abs(value.translation.width) {
                            // Swipe right detected
                            showingGraph = true
                        }
                    }
            )
            .sheet(isPresented: $showingGraph) {
                AccelerometerGraphView(sensorManager: sensorManager)
            }
        }
    }
    
    private func startSession() {
        sessionStartTime = Date()
        isRecording = true
        showingUploadStatus = false
        
        // Small delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sensorManager.startCollection()
        }
    }
    
    private func stopSession() {
        isRecording = false
        sensorManager.stopCollection()
        
        // Get collected data
        let sensorData = sensorManager.getAllData()
        
        // Save and upload
        Task {
            await dataManager.saveAndUpload(data: sensorData, startTime: sessionStartTime ?? Date())
            
            await MainActor.run {
                showingUploadStatus = true
                uploadMessage = dataManager.uploadStatus
                
                // Reset after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showingUploadStatus = false
                    sessionStartTime = nil
                }
            }
        }
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Sensor Ring View (Fitness app style)
struct SensorRing: View {
    let value: Int
    let color: Color
    let label: String
    
    // Calculate progress (normalize to 0-1, using a reasonable max for visualization)
    private var progress: Double {
        let maxValue = 10000.0 // Adjust this based on expected max samples
        return min(Double(value) / maxValue, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)
            
            // Center value
            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 55, height: 55)
    }
}

// MARK: - Accelerometer Graph View
struct AccelerometerGraphView: View {
    @ObservedObject var sensorManager: SensorManager
    @Environment(\.dismiss) var dismiss
    @State private var accelerometerData: [SensorDataPoint] = []
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Accelerometer")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.caption)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Graph
            if accelerometerData.isEmpty {
                VStack {
                    Spacer()
                    Text("No data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // Background grid
                        Path { path in
                            let midY = geometry.size.height / 2
                            path.move(to: CGPoint(x: 0, y: midY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                        }
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        
                        // Plot lines
                        if accelerometerData.count > 1 {
                            // X axis (red)
                            plotLine(
                                data: accelerometerData,
                                valueKey: \.x,
                                color: .red,
                                geometry: geometry
                            )
                            
                            // Y axis (green)
                            plotLine(
                                data: accelerometerData,
                                valueKey: \.y,
                                color: .green,
                                geometry: geometry
                            )
                            
                            // Z axis (blue)
                            plotLine(
                                data: accelerometerData,
                                valueKey: \.z,
                                color: .blue,
                                geometry: geometry
                            )
                        }
                    }
                }
                .frame(height: 120)
                .padding(.horizontal)
            }
            
            // Legend
            HStack(spacing: 12) {
                LegendItem(color: .red, label: "X")
                LegendItem(color: .green, label: "Y")
                LegendItem(color: .blue, label: "Z")
            }
            .padding(.bottom, 8)
            
            // Sample count
            Text("\(accelerometerData.count) samples")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
        }
        .onAppear {
            updateData()
            // Update periodically while recording
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                updateData()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateData() {
        accelerometerData = sensorManager.getAccelerometerData()
    }
    
    @ViewBuilder
    private func plotLine(data: [SensorDataPoint], valueKey: KeyPath<SensorDataPoint, Double>, color: Color, geometry: GeometryProxy) -> some View {
        if data.isEmpty {
            EmptyView()
        } else {
            // Find min/max for normalization
            let values = data.map { $0[keyPath: valueKey] }
            let minValue = values.min() ?? -1.0
            let maxValue = values.max() ?? 1.0
            let range = maxValue - minValue
            let normalizedRange = range > 0 ? range : 2.0
            
            // Only plot recent data (last 500 points for performance)
            let recentData = Array(data.suffix(500))
            
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2
                
                for (index, point) in recentData.enumerated() {
                    let x = CGFloat(index) / CGFloat(max(recentData.count - 1, 1)) * width
                    let normalizedValue = (point[keyPath: valueKey] - minValue) / normalizedRange
                    let y = midY - CGFloat(normalizedValue - 0.5) * height * 0.8
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 1.5)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}

