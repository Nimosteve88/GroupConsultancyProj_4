//
//  SettingsView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 27/05/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @EnvironmentObject var session: SessionStore

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                Section(header: Text("Options")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("Placeholder 1", systemImage: "gearshape")
                    }
                    NavigationLink(destination: EmptyView()) {
                        Label("Placeholder 2", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
