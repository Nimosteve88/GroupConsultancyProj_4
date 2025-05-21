//
//  StatsCarousel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI

struct StatsCarousel: View {
    var body: some View {
        TabView {
            StatCard(title: "Blood Glucose", value: "\(Int.random(in:50...120)) mg/dl", icon: "drop.fill")
            StatCard(title: "Eaten", value: "2000/3200 cal", icon: "fork.knife")
            StatCard(title: "Risk", value: AdviceEngine.shared.riskLevel.rawValue, icon: "lightbulb.fill")
        }
        //show numbers of dots
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .frame(height: 150)
        .padding(.horizontal)
    }
}

#Preview {
    StatsCarousel()
}
