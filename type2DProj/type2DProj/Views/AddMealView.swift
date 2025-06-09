//  AddMealView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI
import Speech

struct AddMealView: View {
    @EnvironmentObject var mealLogVM: MealLogViewModel
    @Environment(\ .dismiss) var dismiss

    let defaultType: MealType
    @State private var type: MealType

    @State private var name = ""
    @State private var carbs = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var date = Date()

    @StateObject private var speechManager = SpeechManager()
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var showImageSourceAlert = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isAnalyzingImage = false

    @State private var resultText = ""
    @State private var adviceFromLLM = ""
    @State private var imageResultText = ""
    @State private var aiInputText = ""
    @State private var aiTextError = ""

    // New loading state flags
    @State private var isAnalyzingText = false
    @State private var isAnalyzingVoice = false

    init(defaultType: MealType = .breakfast) {
        self.defaultType = defaultType
        _type = State(initialValue: defaultType)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Type") {
                    Picker("Meal Type", selection: $type) {
                        ForEach(MealType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Meal Info") {
                    TextField("Name", text: $name)
                    TextField("Carbs (g)", text: $carbs).keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $protein).keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fat).keyboardType(.decimalPad)
                    TextField("Fiber (g)", text: $fiber).keyboardType(.decimalPad)
                    DatePicker("Time", selection: $date)
                }

                Section("AI Text Input") {
                    TextEditor(text: $aiInputText)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.4))

                    Button(action: {
                        isAnalyzingText = true
                        AIService.shared.analyzeMeal(aiInputText) { result in
                            DispatchQueue.main.async {
                                isAnalyzingText = false
                                if let error = result["error"] as? String {
                                    aiTextError = error
                                    return
                                }
                                name = result["name"] as? String ?? ""
                                carbs = "\(result["carbs"] ?? "")"
                                protein = "\(result["protein"] ?? "")"
                                fat = "\(result["fat"] ?? "")"
                                fiber = "\(result["fiber"] ?? "")"
                                aiTextError = ""
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Analyze Description")
                        }
                    }
                    .disabled(isAnalyzingText || aiInputText.isEmpty)

                    if isAnalyzingText {
                        ProgressView("Analyzing description...")
                            .padding(.top, 5)
                    }

                    if !aiTextError.isEmpty {
                        Text("❗️\(aiTextError)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section("Voice Input") {
                    Button(action: {
                        #if targetEnvironment(simulator)
                        let simulatedText = "I had a chicken sandwich with lettuce and tomato"
                        resultText = simulatedText
                        isAnalyzingVoice = true
                        AIService.shared.analyzeMeal(simulatedText) { result in
                            DispatchQueue.main.async {
                                isAnalyzingVoice = false
                                if let error = result["error"] as? String {
                                    adviceFromLLM = "❗️" + error
                                    return
                                }
                                name = result["name"] as? String ?? ""
                                carbs = "\(result["carbs"] ?? "")"
                                protein = "\(result["protein"] ?? "")"
                                fat = "\(result["fat"] ?? "")"
                                fiber = "\(result["fiber"] ?? "")"
                                adviceFromLLM = "✅ Analyzed successfully"
                            }
                        }
                        #else
                        speechManager.startRecording { text in
                            resultText = text
                            isAnalyzingVoice = true
                            AIService.shared.analyzeMeal(text) { result in
                                DispatchQueue.main.async {
                                    isAnalyzingVoice = false
                                    if let error = result["error"] as? String {
                                        adviceFromLLM = "❗️" + error
                                        return
                                    }
                                    name = result["name"] as? String ?? ""
                                    carbs = "\(result["carbs"] ?? "")"
                                    protein = "\(result["protein"] ?? "")"
                                    fat = "\(result["fat"] ?? "")"
                                    fiber = "\(result["fiber"] ?? "")"
                                    adviceFromLLM = "✅ Analyzed successfully"
                                }
                            }
                        }
                        #endif
                    }) {
                        HStack {
                            Image(systemName: "mic.fill")
                            Text(speechManager.isRecording ? "Stop Recording" : "Start Talking")
                        }
                        .foregroundColor(speechManager.isRecording ? .red : .blue)
                    }
                    .disabled(isAnalyzingVoice)

                    if isAnalyzingVoice {
                        ProgressView("Analyzing voice...")
                            .padding(.top, 5)
                    }

                    if !resultText.isEmpty {
                        Text("You said: \(resultText)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    if !adviceFromLLM.isEmpty {
                        Text(adviceFromLLM)
                            .font(.subheadline)
                            .foregroundColor(adviceFromLLM.contains("❗️") ? .red : .green)
                    }
                }

                Section("Photo Input") {
                    Button(action: { showImageSourceAlert = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Take or Choose Photo")
                        }
                        .foregroundColor(.blue)
                    }

                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)

                            if isAnalyzingImage {
                                ProgressView("Analyzing image...")
                                    .padding(.top, 5)
                            }
                        }
                    }

                    if !imageResultText.isEmpty {
                        Text(imageResultText)
                            .font(.subheadline)
                            .foregroundColor(imageResultText.contains("❗️") ? .red : .green)
                    }
                }
            }
            .navigationTitle("Add Meal")
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(sourceType: imageSourceType) { image in
                    selectedImage = image
                    isAnalyzingImage = true
                    imageResultText = ""
                    AIService.shared.analyzeImage(image) { result in
                        DispatchQueue.main.async {
                            isAnalyzingImage = false
                            if let error = result["error"] as? String {
                                imageResultText = "❗️" + error
                                return
                            }
                            name = result["name"] as? String ?? ""
                            carbs = "\(result["carbs"] ?? "")"
                            protein = "\(result["protein"] ?? "")"
                            fat = "\(result["fat"] ?? "")"
                            fiber = "\(result["fiber"] ?? "")"
                            imageResultText = "✅ Analysis complete: \(name)"
                        }
                    }
                }
            }
            .alert("Choose Photo Source", isPresented: $showImageSourceAlert) {
                Button("Camera") {
                    imageSourceType = .camera
                    isImagePickerPresented = true
                }
                Button("Photo Library") {
                    imageSourceType = .photoLibrary
                    isImagePickerPresented = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let cd = Double(carbs), let pd = Double(protein), let fd = Double(fat), let fib = Double(fiber), !name.isEmpty else { return }
                        let meal = Meal(name: name, type: type, carbs: cd, protein: pd, fat: fd, fiber: fib, date: date)
                        mealLogVM.add(meal)
                        dismiss()
                    }
                    .disabled(name.isEmpty || Double(carbs) == nil || Double(protein) == nil || Double(fat) == nil || Double(fiber) == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddMealView()
}
