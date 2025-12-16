//
//  DataManager.swift
//  SensorCollector
//
//  Created on 2024
//

import Foundation
import Combine

class DataManager: ObservableObject {
    @Published var uploadStatus = ""
    
    // MARK: - Server Configuration
    // You can change these from the watch UI before starting a session
    @Published var serverHost: String = "localhost"
    @Published var serverPort: String = "3000"
    
    // Computed server URL from host and port
    private var serverURLString: String {
        return "http://\(serverHost):\(serverPort)/upload"
    }
    
    func saveAndUpload(data: SensorSessionData, startTime: Date) async {
        // Create filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "sensor_data_\(formatter.string(from: startTime)).json"
        
        // Encode data to JSON
        guard let jsonData = try? JSONEncoder().encode(data) else {
            await MainActor.run {
                uploadStatus = "Error: Failed to encode data"
            }
            return
        }
        
        // Save to documents directory
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            do {
                try jsonData.write(to: fileURL)
                print("Data saved to: \(fileURL.path)")
            } catch {
                await MainActor.run {
                    uploadStatus = "Error: Failed to save file - \(error.localizedDescription)"
                }
                return
            }
            
            // Upload to server
            await uploadFile(fileURL: fileURL, filename: filename)
        } else {
            await MainActor.run {
                uploadStatus = "Error: Could not access documents directory"
            }
        }
    }
    
    private func uploadFile(fileURL: URL, filename: String) async {
        guard let url = URL(string: serverURLString) else {
            await MainActor.run {
                uploadStatus = "Error: Invalid server URL"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(filename, forHTTPHeaderField: "X-Filename")
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            request.httpBody = fileData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    await MainActor.run {
                        uploadStatus = "Success: File uploaded (\(fileData.count) bytes)"
                    }
                } else {
                    await MainActor.run {
                        uploadStatus = "Error: Server returned status \(httpResponse.statusCode)"
                    }
                }
            }
        } catch {
            await MainActor.run {
                uploadStatus = "Error: Upload failed - \(error.localizedDescription)"
            }
        }
    }
}

