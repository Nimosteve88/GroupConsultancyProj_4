//
//  AlertBanner.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI

struct AlertBanner: View {
    let text: String
    let subtext: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text(text).bold()
                Text(subtext).font(.subheadline)
            }
            Spacer()
            Button(action: {
                // dismiss logic
            }) {
                Image(systemName: "xmark.circle.fill")
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(color)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
#Preview {
    AlertBanner(text: "High Glucose Level", subtext: "Your glucose level is above the recommended range.", color: .red)
        
}
