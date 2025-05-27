//
//  AdviceView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI

struct AdviceView: View {
    @EnvironmentObject var adviceEngine: AdviceEngine

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Risk Level: \(adviceEngine.riskLevel.rawValue)")
                    .font(.title2).bold().padding()
                Text(adviceEngine.currentAdvice)
                    .font(.body).padding().background(Color.cardBackground).cornerRadius(12)
                Spacer()
                Button("Refresh Advice") {
                    adviceEngine.generateAdvice(meals: adviceEngine.currentAdvice.isEmpty ? [] : [], glucoseSamples: adviceEngine.currentAdvice.isEmpty ? [] : [])
                }
                .buttonStyle(.borderedProminent).padding()
            }
            .padding()
            .navigationTitle("Advice")
        }
    }
}

#Preview {
    let session = SessionStore()
    Group {
        ContentView()
            .environmentObject(MealLogViewModel(session: session))
            .environmentObject(HealthKitService.shared)
            .environmentObject(AdviceEngine.shared)

        MealDetailView(meal: Meal(name:"Oatmeal",carbs:45,protein:5,fat:2,fiber:4,calories:80, date:Date(),imageName:"oatmeal"))
    }
}
