//
//  ActionButton.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI

struct ActionButton: View {
    let label: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
            Text(label)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accent)
        .foregroundColor(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ActionButton(label: "Log Meal", icon: "plus")
        
}
