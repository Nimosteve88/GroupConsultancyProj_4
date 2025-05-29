//
//  AdviceView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 18/05/2025.
//

import SwiftUI

struct AdviceView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case short = "Short-Term"
        case long = "Long-Term"
        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .short

    // Sample data
    private let shortTermItems: [AdviceItem] = [
        AdviceItem(
            id: 1,
            icon: "exclamationmark.triangle.fill",
            color: .red,
            title: "Low Blood Sugar Alert",
            description: "Your current reading of 67 mg/dL is below target range. Consider having a quick snack with 15g of carbs.",
            primary: AdviceAction(title: "Log Snack", style: .primary),
            secondary: AdviceAction(title: "Dismiss", style: .secondary)
        ),
        AdviceItem(
            id: 2,
            icon: "drop.fill",
            color: .blue,
            title: "Hydration Reminder",
            description: "You've only logged 2 glasses of water today. Aim for at least 8 glasses daily for optimal health.",
            primary: AdviceAction(title: "Log Water", style: .primary),
            secondary: AdviceAction(title: "Remind Later", style: .secondary)
        ),
        AdviceItem(
            id: 3,
            icon: "fork.knife",
            color: .purple,
            title: "Meal Planning Suggestion",
            description: "Your lunch was high in carbohydrates. Consider a protein-rich dinner with fewer carbs.",
            primary: AdviceAction(title: "Suggestions", style: .primary),
            secondary: AdviceAction(title: "Dismiss", style: .secondary)
        )
    ]
    private let longTermItems: [LongTermAdvice] = [
        LongTermAdvice(
            id: 1,
            title: "Consistent Meal Timing",
            description: "Your breakfast time varies significantly. Eating at consistent times can help stabilize blood sugar levels.",
            progress: 0.65,
            progressLabel: "65%",
            days: ["M","T","W","T","F","S","S"],
            activeDays: [0,1,3,4],
            footer: "Try to eat breakfast between 7:00-8:00 AM daily"
        ),
        LongTermAdvice(
            id: 2,
            title: "Regular Physical Activity",
            description: "Regular exercise helps improve insulin sensitivity. Aim for 30 minutes of moderate activity daily.",
            progress: 4/7,
            progressLabel: "4/7 days",
            days: [],
            activeDays: [],
            footer: "Add a 15-minute walk after dinner"
        ),
        LongTermAdvice(
            id: 3,
            title: "Evening Snacking Reduction",
            description: "Late night snacking can disrupt blood sugar levels during sleep. Try to finish eating 2-3 hours before bedtime.",
            progress: 0.5,
            progressLabel: "Improving",
            days: [],
            activeDays: [],
            footer: "Try herbal tea as an evening alternative"
        ),
    ]

    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Advice")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .padding(.horizontal)

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 16) {
                    if selectedTab == .short {
                        ForEach(shortTermItems) { item in
                            ShortTermCard(item: item)
                        }
                    } else {
                        ForEach(longTermItems) { item in
                            LongTermCard(item: item)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Models
struct AdviceItem: Identifiable {
    let id: Int
    let icon: String
    let color: Color
    let title: String
    let description: String
    let primary: AdviceAction
    let secondary: AdviceAction
}
struct AdviceAction {
    let title: String
    let style: ButtonStyleType
}
enum ButtonStyleType { case primary, secondary }

struct LongTermAdvice: Identifiable {
    let id: Int
    let title: String
    let description: String
    let progress: Double
    let progressLabel: String
    let days: [String]
    let activeDays: [Int]
    let footer: String
}

// MARK: - Card Views

struct ShortTermCard: View {
    let item: AdviceItem
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(item.color)
                .frame(width: 6)
                .cornerRadius(3, corners: [.topLeft, .bottomLeft])
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: item.icon)
                        .foregroundColor(item.color)
                    Text(item.title)
                        .font(.headline)
                    Spacer()
                }
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    AdviceButton(action: item.primary)
                    AdviceButton(action: item.secondary)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .padding(.vertical, 6)
    }
}

// Helper for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 12.0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct LongTermCard: View {
    let item: LongTermAdvice
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .font(.headline)
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            // Progress bar
            HStack {
                Text(item.progressLabel)
                    .font(.footnote)
                Spacer()
            }
            ProgressView(value: item.progress)
                .progressViewStyle(LinearProgressViewStyle())
            // Days row if applicable
            if !item.days.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(item.days.enumerated()), id: \.offset) { index, day in
                        Circle()
                            .fill(item.activeDays.contains(index) ? Color.accent : Color.primaryBackground)
                            .frame(width: 32, height: 32)
                            .overlay(Text(day).foregroundColor(item.activeDays.contains(index) ? .white : .secondary))
                    }
                }
            }
            Text(item.footer)
                .font(.footnote)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct AdviceButton: View {
    let action: AdviceAction
    var body: some View {
        Button(action: {}) {
            Text(action.title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(action.style == .primary ? .blue : .gray.opacity(0.3))
    }
}

#Preview {
    let session = SessionStore()
    ContentView()
        .environmentObject(MealLogViewModel(session: session))
        .environmentObject(HealthKitService.shared)
        .environmentObject(AdviceEngine.shared)
}
