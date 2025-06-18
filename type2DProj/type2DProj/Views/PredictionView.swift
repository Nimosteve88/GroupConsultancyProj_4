//
//  PredictionView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 14/06/2025.
//

import SwiftUI

struct PredictionView: View {
  @EnvironmentObject var session: SessionStore
  @StateObject private var vm = GluNetViewModel()

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.secondarySystemBackground))
        .shadow(radius: 4)

      VStack(spacing: 20) {
        Text("CGM Forecast")
          .font(.headline)
        
        Text("Predict your change in glucose levels based on recent CGM data. Positive values indicate an increase, negative values indicate a decrease.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
          
            

        if let error = vm.errorMessage {
          // Error state
          VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.largeTitle)
              .foregroundColor(.yellow)
            Text(error)
              .multilineTextAlignment(.center)
            Button("Got it") {
              vm.errorMessage = nil
            }
            .buttonStyle(.bordered)
          }
          .padding()

        } else if vm.isLoading {
          // Loading state
          VStack(spacing: 12) {
            ProgressView()
              .scaleEffect(1.5)
            Text("Calculating…")
              .foregroundColor(.secondary)
          }

        } else if let val = vm.prediction {
          // Success state
          VStack(spacing: 12) {
            Text("\(String(describing: val)) mg/dL")
              .font(.system(size: 48, weight: .bold, design: .rounded))
              .foregroundStyle(
                LinearGradient(
                  colors: [.blue, .cyan],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
            Button("Refresh") {
              if let uid = session.userId {
                vm.start(uid: uid)
              }
            }
            .buttonStyle(.borderedProminent)
          }

        } else {
          // Initial / idle state
          VStack(spacing: 12) {
            Text("Start Prediction")
              .foregroundColor(.secondary)
            Button("Predict Now") {
              if let uid = session.userId {
                vm.start(uid: uid)
              }
            }
            .buttonStyle(.bordered)
          }
        }
      }
      .padding()
      .animation(.default, value: vm.errorMessage)
      .animation(.default, value: vm.isLoading)
      .animation(.default, value: vm.prediction)
    }
    .padding()
    // Note: No onAppear here — prediction only runs when the button is tapped,
    // and because we DO NOT call vm.stop(), it continues even if you leave the view.
  }
}

//struct PredictionView_Previews: PreviewProvider {
//  static var previews: some View {
//    PredictionView()
//      .environmentObject(SessionStore())
//  }
//}
