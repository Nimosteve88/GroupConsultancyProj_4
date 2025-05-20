//
//  StatCard.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: icon).font(.title2); Spacer() }
            Text(title).font(.headline)
            Text(value).font(.title).bold()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}


#Preview {
    StatCard(title: "Last Meal", value: "Pasta", icon: "fork.knife")
        .padding()
        
}
