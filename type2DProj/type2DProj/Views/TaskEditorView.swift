//
//  TaskEditorView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 27/05/2025.
//

import SwiftUI

struct TaskEditorView: View {
    @EnvironmentObject var tasksVM: TodayTasksViewModel
    @Environment(\.dismiss) var dismiss

    @State var time: Date
    @State var title: String
    var task: TodayTasksViewModelTask?

    init(task: TodayTasksViewModelTask?) {
        self.task = task
        _time = State(initialValue: task?.time ?? Date())
        _title = State(initialValue: task?.title ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Info")) {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    TextField("Title", text: $title)
                }
            }
            .navigationTitle(task == nil ? "Add Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(task == nil ? "Add" : "Update") {
                        if let existing = task {
                            var updated = existing
                            updated.time = time
                            updated.title = title
                            tasksVM.update(updated)
                        } else {
                            let newTask = TodayTasksViewModelTask(id: "", time: time, title: title, done: false)
                            tasksVM.add(newTask)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let session = SessionStore()
    TaskEditorView(task: nil)
        .environmentObject(TodayTasksViewModel(session: session))
}
