//
//  CaseByCategoryAndHouseType.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 26/3/2024.
//

import SwiftUI
import SwiftUIX
import SwiftyJSON
import Charts

struct CaseByAgeGroupAndReason: View {
    let allDatas: [Entry]
    @State private var maxValue: Int = 100
    
    @State var showPopover: Bool = false
    @State var displayData: [Entry] = []
    @State var showPercentage: Bool = false
    @State var isSortDescendingly: Bool = false
    @State var sortedAgeGroups: [String] = []
    @State var isSortByAgeGroup: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide Age Group & Reason")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("People usually jump at public estate")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            ChartView(
                showPercentage: $showPercentage,
                sortedAgeGroups: sortedAgeGroups,
                displayData: displayData,
                maxValue: maxValue
            )
                .frame(minWidth: 100, minHeight: 100)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showPopover = true
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .padding(8)
            .contentShape(Circle())
            .hoverEffect()
            .popover(isPresented: $showPopover) {
                PopOverView(
                    showPercentage: $showPercentage,
                    isSortDescendingly: $isSortDescendingly,
                    isSortByAgeGroup: $isSortByAgeGroup
                )
            }
            .padding(8)
            .task(id: [showPercentage, isSortDescendingly, isSortByAgeGroup]) {
                await updateIntervalData()
            }
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .task(id: allDatas) {
            await updateIntervalData()
        }
        .animation(.spring, value: displayData)
        .animation(.spring, value: allDatas)
        .animation(.easeInOut, value: showPercentage)
        .animation(.spring, value: sortedAgeGroups)
    }
    
    func updateIntervalData() async {
        var matched: [Entry] = allDatas
        let sumCountPerAgeGroup: [String: Int] = Dictionary(grouping: matched, by: { $0.ageGroup }).mapValues({ $0.reduce(0, { $0 + $1.count })})
        
        maxValue = sumCountPerAgeGroup.values.reduce(0, { max($0, $1)})
        
        if showPercentage {
            for i in matched.indices {
                matched[i].normalise(sum: sumCountPerAgeGroup[matched[i].ageGroup] ?? 1)
            }
        }
        
        displayData = matched.sorted(using: [KeyPathComparator(\.ageGroup, order: .reverse), KeyPathComparator(\.reason)])
        
        typealias AgeSumTuple = (ageGroup: String, ageSum: Int)
        let ageSumPairs: [AgeSumTuple] = sumCountPerAgeGroup.map({ (ageGroup: $0, ageSum: $1) })
        if isSortByAgeGroup {
            sortedAgeGroups = ageSumPairs
                .sorted(using: KeyPathComparator(\.ageGroup, order: isSortDescendingly ? .reverse : .forward))
                .map(\.0)
        } else {
            sortedAgeGroups = ageSumPairs
                .sorted(using: KeyPathComparator(\.ageSum, order: isSortDescendingly ? .reverse : .forward))
                .map(\.0)
        }
    }

}

extension CaseByAgeGroupAndReason {
    fileprivate struct ChartView: View {
        @Binding var showPercentage: Bool
        let sortedAgeGroups: [String]
        let displayData: [Entry]
        let maxValue: Int
        
        var body: some View {
            Chart(displayData) { (entry: Entry) in
                BarMark(
                    x: .value("Category", entry.ageGroup),
                    y: .value(showPercentage ? "Percentage" : "Count", showPercentage ? entry.percentage : Double(entry.count))
                )
                .foregroundStyle(by: .value("Reason", entry.reason))
                .annotation(position: .overlay) {
                    VStack {
                        if showPercentage {
                            ViewThatFits {
                                Text("\(String(format: "%.2f", entry.percentage))")
                                    .font(.caption)
                                    .bold()
                                Text("\(String(format: "%.1f", entry.percentage))")
                                    .font(.caption)
                                    .bold()
                                Text("\(String(format: "%.0f", entry.percentage))")
                                    .font(.caption)
                                    .bold()
                                Text("\(String(format: "%.0f", entry.percentage))")
                                    .font(.caption)
                                    .bold()
                                Text("")
                            }
                        } else {
                            ViewThatFits {
                                Text("\(entry.count)")
                                    .font(.caption)
                                    .bold()
                                Text("")
                            }
                        }
                    }
                }
            }
            .chartXScale(domain: sortedAgeGroups)
            .chartYScale(domain: [0, showPercentage ? 100 : maxValue])
            .chartXAxis {
                AxisMarks(position: .bottom, values: AGE_GROUPS) { (value: AxisValue) in
                    if let ageGroup: String = value.as(String.self) {
                        AxisValueLabel(centered: true) {
                            Text(ageGroup)
                        }
                    }
                }
            }
            .chartYAxis {
                if showPercentage {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { (value: AxisValue) in
                        if let percentile: Int = value.as(Int.self) {
                            AxisValueLabel(centered: false) {
                                Text("\(percentile)%")
                            }
                        }
                    }
                } else {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { (value: AxisValue) in
                        if let count: Int = value.as(Int.self) {
                            AxisValueLabel(centered: false) {
                                Text("\(count)")
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartLegend(alignment: .bottom)
            .gesture(
                MagnifyGesture()
                    .onEnded { (value: MagnifyGesture.Value) in
                        showPercentage = value.magnification > 1
                    }
            )
        }
    }
}

fileprivate struct PopOverView: View {
    @Binding var showPercentage: Bool
    @Binding var isSortDescendingly: Bool
    @Binding var isSortByAgeGroup: Bool
    
    private static let width: CGFloat = 300
    private static let height: CGFloat = 250
    
    var body: some View {
        List {
            Toggle("Show Percentage", isOn: $showPercentage)
            Toggle("Sort Descendingly", isOn: $isSortDescendingly)
            Toggle("Sort by Age Group", isOn: $isSortByAgeGroup)
        }
        .padding(.top, 48)
        .frame(width: PopOverView.width)
        .overlay(alignment: .top) {
            Text("Plot Configuration")
                .bold()
                .font(.headline)
                .frame(width: PopOverView.width)
                .padding(.vertical)
                .background(.ultraThinMaterial)
        }
        .frame(height: PopOverView.height)
    }
}

extension CaseByAgeGroupAndReason {
    struct Entry: Hashable, Equatable, Codable, Identifiable {
        struct Key: Hashable, Equatable, Codable {
            let ageGroup: String
            let reason: String
        }
        var id: Key { key }
        let key: Key
        var count: Int
        var percentage: Double = 0
        
        var ageGroup: String {
            key.ageGroup
        }
        
        var reason: String {
            key.reason
        }
        
        init(key: Key, count: Int) {
            self.key = key
            self.count = count
        }
        
        mutating func normalise(sum: Int) {
            self.percentage = Double(self.count)/Double(sum)*Double(100)
        }
    }
}
