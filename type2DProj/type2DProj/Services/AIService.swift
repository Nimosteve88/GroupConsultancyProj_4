//
//  AIService.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import Foundation
import UIKit

class AIService {
    static let shared = AIService()
    
    private let baseURL = "https://cgm-backend-depr.onrender.com"
    
    func analyzeMeal(_ message: String, completion: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat") else {
            completion(["error": "Invalid URL"])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a prompt that instructs the AI to return structured data
        let prompt = """
        Analyze this meal description and return ONLY a JSON object with nutritional information:
        "\(message)"
        
        Return ONLY this JSON format (no other text):
        {
            "name": "meal name",
            "carbs": number,
            "protein": number,
            "fat": number,
            "fiber": number
        }
        """
        
        let body: [String: String] = ["message": prompt]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            completion(["error": "Serialization failed"])
            return
        }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(["error": "Network error: \(error.localizedDescription)"])
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(["error": "No data received"])
                }
                return
            }
            
            // First, parse the backend response
            guard let backendResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let aiReply = backendResponse["reply"] as? String else {
                DispatchQueue.main.async {
                    completion(["error": "Failed to parse backend response"])
                }
                return
            }
            
            // Clean the AI reply to extract JSON
            var cleaned = aiReply
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Find JSON object in the response
            if let jsonStart = cleaned.firstIndex(of: "{"),
               let jsonEnd = cleaned.lastIndex(of: "}") {
                let jsonString = String(cleaned[jsonStart...jsonEnd])
                
                if let jsonData = jsonString.data(using: .utf8),
                   let nutritionData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    DispatchQueue.main.async {
                        completion(nutritionData)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(["error": "Failed to parse nutrition data"])
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(["error": "No JSON found in response"])
                }
            }
        }.resume()
    }
    
    func analyzeImage(_ image: UIImage, completion: @escaping ([String: Any]) -> Void) {
        guard let url = URL(string: "\(baseURL)/analyze-image/") else {
            completion(["error": "Invalid URL"])
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(["error": "Failed to convert image"])
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"meal.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(["error": "Network error: \(error.localizedDescription)"])
                }
                return
            }
            
            guard let data = data,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let imageDescription = response["text"] as? String else {
                DispatchQueue.main.async {
                    completion(["error": "Failed to analyze image"])
                }
                return
            }
            
            // Now analyze the description to get nutrition info
            self.analyzeMeal(imageDescription, completion: completion)
        }.resume()
    }
}
