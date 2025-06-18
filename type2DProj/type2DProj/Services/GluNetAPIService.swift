//
//  GluNetAPIService.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/06/2025.
//

import Foundation

struct GluNetAPIService {
    private let apiUrl = URL(string: "https://cgm-backend-depr.onrender.com/predict")!
    
    func predict(glucose: [Float], carbs: [Float], insulin: [Float], times: [Date]) async throws -> Float {
        // Normalize inputs
        let normalizedGlucose = normalize(glucose, mean: 100.0, std: 12.0)
        let normalizedCarbs = normalize(carbs, mean: 0.0, std: 50.0)
        let normalizedInsulin = normalize(insulin, mean: 0.0, std: 1.0)
        let normalizedTimes = times.map { normalizeTime($0) }
        
        // Prepare input array in one line format (like curl example)
        let inputArray: [Float] = (0..<16).flatMap { i in
            [normalizedGlucose[i], normalizedCarbs[i], normalizedInsulin[i], normalizedTimes[i]]
        }
        
        // Create JSON data - using JSONSerialization for exact formatting
        let jsonData = try JSONSerialization.data(
            withJSONObject: inputArray,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        
        // Debug print
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Final JSON being sent:")
            print(jsonString)
        }
        
        // Create request
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Configure URLSession with timeout
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        let session = URLSession(configuration: sessionConfig)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.cannotParseResponse)
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseBody = String(data: data, encoding: .utf8) ?? "No body"
            print("API Error Response: \(responseBody)")
            throw URLError(.badServerResponse)
        }
        
        // Try parsing response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw response: \(responseString)")
            
            // Try parsing as JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Handle both array and direct float cases
                    if let predictionArray = json["prediction"] as? [Float],
                       let firstValue = predictionArray.first {
                        let res = (firstValue-128)*0.1
                        print("Resultant prediction from array: \(res)")
                        return res
                    } else if let prediction = json["prediction"] as? Float {
                        let res = (prediction-128)*0.1
                        print("Resultant prediction from array: \(res)")
                        return res
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
            
            // Last attempt: try parsing as direct float string
            if let floatValue = Float(responseString) {
                return floatValue
            }
        }

        throw URLError(.cannotParseResponse)
    }
    
    private func normalize(_ values: [Float], mean: Float, std: Float) -> [Float] {
        return values.map { ($0 - mean) / std }
    }
    
    private func normalizeTime(_ date: Date) -> Float {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let totalMinutes = Float(components.hour! * 60 + components.minute!)
        return totalMinutes / (24 * 60)
    }
}
