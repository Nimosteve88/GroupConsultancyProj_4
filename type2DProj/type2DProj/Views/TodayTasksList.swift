//
//  TodayTasksList.swift
//  type2DProj
//
//  Created by Nimo, Steve on 20/05/2025.
//

import SwiftUI

struct TodayTask: Identifiable {
    let id = UUID()
    let time: String
    let title: String
    var done: Bool = false
}

struct TodayTasksList: View {
    @Binding var tasks: [TodayTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today").font(.title2).bold().padding(.horizontal)
            ForEach($tasks) { $task in
                HStack {
                    Text("\(task.time)  \(task.title)")
                        .strikethrough(task.done, color: .primary)
                    Spacer()
                    Button(action: { task.done.toggle() }) {
                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.done ? .green : .secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    TodayTasksList(tasks: .constant([
        TodayTask(time: "08:00 AM", title: "Breakfast"),
        TodayTask(time: "12:00 PM", title: "Lunch"),
        TodayTask(time: "06:00 PM", title: "Dinner")
    ]))
}
