//
//  HomeView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI
import Charts

struct HomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var healthKit: HealthKitService
    @EnvironmentObject var mealLog: MealLogViewModel
    @EnvironmentObject var advice: AdviceEngine
    @State private var showProfile = false
    @State private var showProfileSetup = false

    @State private var tasks: [TodayTask] = [
        .init(time: "07:30 AM", title: "Morning walk"),
        .init(time: "12:30 PM", title: "Exercise"),
        .init(time: "17:50 PM", title: "Inject insulin"),
        .init(time: "20:00 PM", title: "Drink warm water")
    ]

    private var showBanner: Bool {
        advice.riskLevel == .high
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if showBanner {
                        AlertBanner(
                            text: "HIGH HYPOGLYCEMIA RISK",
                            subtext: "Your glucose level is below range!",
                            color: .red
                        )
                    }

                    CombinedChartView(
                        actual: healthKit.glucoseSamples,
                        predicted: advice.predictedSamples()
                    )
                    .frame(height: 200)
                    .padding(.horizontal)

                    StatsCarousel()

                    QuickActions()

                    TodayTasksList(tasks: $tasks)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack(spacing: 8) {
                                Text(session.userEmail)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .onTapGesture {
                                        showProfile = true
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                        .environmentObject(session)
                }
                .onAppear {
                            showProfileSetup = session.needsProfileSetup
                        }
                        .onChange(of: session.needsProfileSetup) { needs in
                            showProfileSetup = needs
                        }
                        .fullScreenCover(isPresented: $showProfileSetup) {
                            ProfileSetupView()
                                .environmentObject(session)
                        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
        .environmentObject(HealthKitService.shared)
        .environmentObject(MealLogViewModel())
        .environmentObject(AdviceEngine.shared)
}
