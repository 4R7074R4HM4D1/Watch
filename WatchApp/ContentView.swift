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
    
    var body: some View {
        VStack(spacing: 20) {
            // Status indicator
            HStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.gray)
                    .frame(width: 12, height: 12)
                Text(isRecording ? "Recording" : "Ready")
                    .font(.caption)
            }
            
            // Session info
            if let startTime = sessionStartTime {
                Text("Session: \(formatDuration(startTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Sample count
            Text("Samples: \(sensorManager.totalSamples)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Start/Stop button
            Button(action: {
                if isRecording {
                    stopSession()
                } else {
                    startSession()
                }
            }) {
                Text(isRecording ? "Stop & Upload" : "Start Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.green)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Upload status
            if showingUploadStatus {
                Text(uploadMessage)
                    .font(.caption)
                    .foregroundColor(uploadMessage.contains("Success") ? .green : .red)
                    .padding(.top, 5)
            }
        }
        .padding()
    }
    
    private func startSession() {
        sessionStartTime = Date()
        isRecording = true
        showingUploadStatus = false
        sensorManager.startCollection()
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

#Preview {
    ContentView()
}

