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
    var badge: Int? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(label)
            Spacer()
            if let b = badge {
                Text("\(b)")
                    .font(.caption2).bold()
                    .padding(4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.accent)
        .foregroundColor(.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ActionButton(label: "Log Meal", icon: "plus")
        
}
