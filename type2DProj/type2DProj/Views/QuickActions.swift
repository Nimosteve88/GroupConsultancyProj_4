//
//  QuickActions.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI

struct QuickActions: View {
    var body: some View {
        VStack(spacing: 12) {
            ActionButton(label: "Log Meal", icon: "plus.circle")
            ActionButton(label: "Daily Meal Plan", icon: "list.bullet")
            ActionButton(label: "Personal Report", icon: "doc.text")
            ActionButton(label: "Suggestion Center", icon: "bubble.left.and.bubble.right.fill", badge: 4)
        }
        .padding(.horizontal)
    }
}


#Preview {
    QuickActions()
}
