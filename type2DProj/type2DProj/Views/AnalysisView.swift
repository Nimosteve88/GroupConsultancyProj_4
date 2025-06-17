//
//  AnalysisView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 29/05/2025.
//

import SwiftUI
import Charts
import FirebaseFirestore

struct AnalysisView: View {
    enum Period: String, CaseIterable, Identifiable {
        case day = "Day", week = "Week", month = "Month", year = "Year"
        var id: String { rawValue }
    }

    @EnvironmentObject var session: SessionStore
    @StateObject private var vm = AnalysisViewModel()
    @State private var selectedPeriod: Period = .day
    @State private var isGlucoseInsightExpanded = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Analysis")
                .font(.largeTitle).bold()
                .padding(.horizontal).padding(.top)

            Picker("Period", selection: $selectedPeriod) {
                ForEach(Period.allCases) { p in Text(p.rawValue).tag(p) }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 24) {
                    // Glucose Stats & Chart
                    let data = vm.readings.filter { selectedPeriod.contains($0.timestamp) }
                    HStack(spacing: 16) {
                        StatCard(title: "Average", value: "\(Int(data.average))", icon: "mg/dL")
                        StatCard(title: "Low",     value: "\(Int(data.min ?? 0))",    icon: "mg/dL")
                        StatCard(title: "High",    value: "\(Int(data.max ?? 0))",    icon: "mg/dL")
                    }
                    .padding(.horizontal)

                    Chart(data) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Glucose", point.value)
                        )
                    }
                    .chartXAxis { AxisMarks(values: .automatic) }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: 200)
                    .padding(.horizontal)

                    // Meal Impacts
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal Impact on Glucose").font(.headline).padding(.horizontal)
                        let impacts = vm.mealImpacts(period: selectedPeriod)
                        if impacts.isEmpty {
                            Text("Need more data").foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(impacts) { impact in
                                        MealImpactCard(item: impact)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Glucose Insight Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "flask.fill").foregroundColor(.blue)
                            Text("Glucose Insight").font(.headline)
                        }
                        if vm.isLoadingInsight {
                            ProgressView().padding()
                        } else if let advice = vm.glucoseInsight {
                            let previewCount = max(1, advice.count / 4)
                            Text(isGlucoseInsightExpanded ? advice : "\(advice.prefix(previewCount))...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            Button(action: {
                                isGlucoseInsightExpanded.toggle()
                            }) {
                                Text(isGlucoseInsightExpanded ? "View Less" : "View More")
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)

                    // Nutrition Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Nutrition Summary").font(.headline)
                            .padding(.horizontal)
                        HStack(spacing: 16) {
                            ForEach(vm.nutritionStats) { stat in
                                NutritionCard(stat: stat)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Analysis")
        .onAppear {
            if let uid = session.userId {
                vm.fetchAll(uid: uid)
                vm.fetchInsights(uid: uid)
            }
        }
    }
}

// MARK: - ViewModel

final class AnalysisViewModel: ObservableObject {
    @Published var readings: [Reading] = []
    @Published var meals: [MealEntry] = []
    @Published var nutritionStats: [NutritionStat] = []
    @Published var glucoseInsight: String? = nil
    @Published var isLoadingInsight: Bool = false

    private let db = Firestore.firestore()
    private let chatURL = URL(string: "https://cgm-backend-depr.onrender.com/chat")!

    func fetchAll(uid: String) {
        fetchReadings(uid: uid)
        fetchMeals(uid: uid)
    }

    func fetchInsights(uid: String) {
        isLoadingInsight = true
        // Prepare context from latest stats
        let avg = Int(readings.average)
        let carbsToday = nutritionStats.first(where: { $0.name == "Carbs" })?.value ?? 0
        let prompt = "User has average glucose \(avg) mg/dL and consumed \(carbsToday)g carbs today."
        let body = ["message": prompt]
        var req = URLRequest(url: chatURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let resp = json["reply"] as? String else {
                DispatchQueue.main.async { self.isLoadingInsight = false }
                return
            }
            DispatchQueue.main.async {
                self.glucoseInsight = resp
                self.isLoadingInsight = false
            }
        }.resume()
    }

    private func fetchReadings(uid: String) {
        let ref = db.collection("users").document(uid)
            .collection("glucoseReadings")
            .order(by: "timestamp", descending: false)
        ref.getDocuments { [weak self] snap, _ in
            guard let self = self, let docs = snap?.documents else { return }
            self.readings = docs.compactMap { doc in
                guard let ts = doc.data()["timestamp"] as? Timestamp,
                      let v  = doc.data()["value"] as? Double else { return nil }
                return Reading(id: doc.documentID, value: v, timestamp: ts.dateValue())
            }
        }
    }

    private func fetchMeals(uid: String) {
        let ref = db.collection("users").document(uid)
            .collection("meals")
            .order(by: "date", descending: false)
        ref.getDocuments { [weak self] snap, _ in
            guard let self = self, let docs = snap?.documents else { return }
            self.meals = docs.compactMap { doc in
                guard let ts = doc.data()["date"] as? Timestamp else { return nil }
                let carbs   = doc.data()["carbs"]   as? Double ?? 0
                let protein = doc.data()["protein"] as? Double ?? 0
                let fat     = doc.data()["fat"]     as? Double ?? 0
                return MealEntry(id: doc.documentID, date: ts.dateValue(), carbs: carbs, protein: protein, fat: fat)
            }
            self.computeNutrition()
        }
    }

    private func computeNutrition() {
        let today = Calendar.current
        let todayMeals = meals.filter { today.isDateInToday($0.date) }
        let sumCarbs   = todayMeals.reduce(0) { $0 + $1.carbs }
        let sumProt    = todayMeals.reduce(0) { $0 + $1.protein }
        let sumFat     = todayMeals.reduce(0) { $0 + $1.fat }
        let total = sumCarbs + sumProt + sumFat
        let stats: [NutritionStat] = [
            NutritionStat(name: "Carbs",   value: Int(sumCarbs), unit: "g", percent: total>0 ? Int((sumCarbs/total)*100):0, color:.green),
            NutritionStat(name: "Protein", value: Int(sumProt),  unit: "g", percent: total>0 ? Int((sumProt/total)*100):0, color:.blue),
            NutritionStat(name: "Fat",     value: Int(sumFat),   unit: "g", percent: total>0 ? Int((sumFat/total)*100):0, color:.orange)
        ]
        DispatchQueue.main.async { self.nutritionStats = stats }
    }

    func mealImpacts(period: AnalysisView.Period) -> [MealImpact] {
        let filtered = readings.filter { period.contains($0.timestamp) }
        var impacts: [MealImpact] = []
        for meal in meals {
            guard let before = filtered.last(where: { $0.timestamp <= meal.date }) else { continue }
            let after = filtered.filter { $0.timestamp > meal.date && $0.timestamp <= meal.date.addingTimeInterval(7200) }
            guard let peak = after.max(by: { $0.value < $1.value }) else { continue }
            let delta = Int(peak.value - before.value)
            let threshold = before.value + 5
            let rec = after.first(where: { $0.value <= threshold })
            let recStr = rec.map { TimeInterval($0.timestamp.timeIntervalSince(peak.timestamp)).minutesString } ?? "-"
            let label: String
            let color: Color
            switch delta {
            case ..<15: label = "Low";      color = .green
            case 15..<30: label = "Moderate"; color = .orange
            default:      label = "High";     color = .red
            }
            impacts.append(MealImpact(id: meal.id, type: meal.date, delta: delta, label: label, color: color, recovery: recStr))
        }
        return impacts
    }
}

// MARK: - Models & Views

struct Reading: Identifiable { let id: String; let value: Double; let timestamp: Date }
struct MealEntry: Identifiable { let id: String; let date: Date; let carbs: Double; let protein: Double; let fat: Double }
struct NutritionStat: Identifiable { let id=UUID(); let name:String; let value:Int; let unit:String; let percent:Int; let color:Color }
struct MealImpact: Identifiable { let id:String; let type:Date; let delta:Int; let label:String; let color:Color; let recovery:String }


struct NutritionCard: View {
    let stat: NutritionStat
    var body: some View {
        VStack(spacing: 8) {
            Text(stat.name)
                .font(.caption)
            Text("\(stat.value)\(stat.unit)")
                .font(.title2)
                .bold()
                .foregroundColor(stat.color)
            Text("\(stat.percent)%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        // No background color applied; padding remains transparent.
        .frame(maxWidth: .infinity)
    }
}

struct MealImpactCard: View { let item:MealImpact; var body: some View { VStack(alignment:.leading,spacing:8){ Text(item.type,style:.time).font(.subheadline).bold(); (Text("+\(item.delta) mg/dL").font(.headline).foregroundColor(item.color)+Text(" \(item.label)").font(.caption).foregroundColor(item.color)); Text("Recovery: \(item.recovery)").font(.caption).foregroundColor(.secondary) }.padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius:2).frame(width:200) } }

// MARK: - Extensions

extension Array where Element == Reading {
    var average: Double { isEmpty ? 0 : reduce(0){ $0+$1.value}/Double(count) }
    var min: Double? { map({$0.value}).min() }
    var max: Double? { map({$0.value}).max() }
}
extension AnalysisView.Period { func contains(_ date:Date)->Bool{ let cal=Calendar.current; switch self{case .day:return cal.isDateInToday(date);case .week:return cal.dateComponents([.weekOfYear],from:date,to:Date()).weekOfYear==0;case .month:return cal.component(.month,from:date)==cal.component(.month,from:Date());case .year:return cal.component(.year,from:date)==cal.component(.year,from:Date())}}}
extension TimeInterval{var minutesString:String{"\(Int(self/60)) min"}}


#Preview {
    AnalysisView()
}
