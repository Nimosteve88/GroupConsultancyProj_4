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
    @EnvironmentObject var tasksVM: TodayTasksViewModel

    @State private var showProfile = false
    @State private var showTaskEditor = false
    @State private var editingTask: TodayTasksViewModelTask? = nil

    private var showBanner: Bool {
        advice.riskLevel == .high
    }

    private func removeTasks(at offsets: IndexSet) {
        offsets.map { tasksVM.tasks[$0] }.forEach { tasksVM.remove($0) }
    }

    private var todayTasks: [TodayTasksViewModelTask] {
        let calendar = Calendar.current
        return tasksVM.tasks.filter { task in
            calendar.isDateInToday(task.time)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if showBanner {
                        AlertBanner(text: "HIGH HYPOGLYCEMIA RISK",
                                    subtext: "Your glucose level is below range!",
                                    color: .red)
                    }

                    NavigationLink(destination: CGMView()) {
                        CombinedChartView()
                                    .frame(height: 200)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())

                    StatsCarousel()

                    QuickActions()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button(action: {
                                editingTask = nil
                                showTaskEditor = true
                            }) {
                                Image(systemName: "plus.circle")
                            }
                        }
                        .padding(.horizontal)


                        // In the List, use todayTasks instead of tasksVM.tasks
                        List {
                            ForEach(todayTasks) { task in
                                HStack {
                                    Button(action: {
                                        var updated = task
                                        updated.done.toggle()
                                        tasksVM.update(updated)
                                    }) {
                                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                    }
                                    // Format time for display
                                    Text("\(task.time.formatted(date: .omitted, time: .shortened)) - \(task.title)")
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            .onDelete { offsets in
                                // Map offsets to todayTasks, then find their index in tasksVM.tasks
                                let tasksToRemove = offsets.map { todayTasks[$0] }
                                tasksToRemove.forEach { tasksVM.remove($0) }
                            }
                        }
                        .frame(height: min(CGFloat(todayTasks.count) * 50, 300))
                        .listStyle(PlainListStyle())
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Text(session.userEmail ?? "No Email")
                        Image(systemName: "person.circle.fill")
                            .onTapGesture { showProfile = true }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView().environmentObject(session)
            }
            .sheet(isPresented: $showTaskEditor) {
                TaskEditorView(task: editingTask)
                    .environmentObject(tasksVM)
            }
        }
    }
}

#Preview {
    let session = SessionStore()
    HomeView()
        .environmentObject(session)
        .environmentObject(HealthKitService.shared)
        .environmentObject(MealLogViewModel(session: session))
        .environmentObject(AdviceEngine.shared)
        .environmentObject(TodayTasksViewModel(session: session))
}
