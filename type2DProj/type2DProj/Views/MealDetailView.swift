//
//  MealDetailView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 15/05/2025.
//

import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    @State private var aiFeedback: String?
    @Namespace private var animation

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let imageName = meal.imageName {
                    Image(imageName)
                        .resizable()
                        .matchedGeometryEffect(id: imageName, in: animation)
                        .scaledToFit()
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                Text(meal.name)
                    .font(.largeTitle)
                    .bold()

                HStack {
                    Label("Carbs", systemImage: "leaf.fill")
                    Spacer()
                    Text("\(Int(meal.carbs)) g")
                        .font(.title3)
                }
                .padding(.horizontal)

                Button(action: {
                    AIService.shared.analyzeMeal(meal.name) { result in
                        if let error = result["error"] as? String {
                            aiFeedback = "❗️" + error
                            return
                        }

                        let feedbackText = """
                        Name: \(result["name"] ?? "N/A")
                        Carbs: \(result["carbs"] ?? "-") g
                        Protein: \(result["protein"] ?? "-") g
                        Fat: \(result["fat"] ?? "-") g
                        Fiber: \(result["fiber"] ?? "-") g
                        """

                        aiFeedback = feedbackText
                    }
                }) {
                    Label("Analyze Meal", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if let feedback = aiFeedback {
                    Text(feedback)
                        .padding()
                        .background(Color.primaryBackground)
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .slide))
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
        }
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

//#Preview {
//    MealDetailView(meal: Meal(name: "Oatmeal", carbs: 50, protein: 20, fat: 10, fiber: 5, calories: 300, date: Date(), imageName: "oatmeal"))
//        .environmentObject(HealthKitService.shared)
//}

