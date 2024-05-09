//
//  CaseByCategoryAndStatus.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 26/3/2024.
//

import SwiftUI
import SwiftUIX
import SwiftyJSON
import Charts

struct CaseByCategoryAndStatus: View {
    let allDatas: [Entry]
    @State private var maxValue: Int = 100
    
    @State var showPopover: Bool = false
    @State var displayData: [Entry] = []
    @State var showPercentage: Bool = false
    @State var isSortDescendingly: Bool = false
    @State var sorteCategories: [String] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide Category & Status")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("Many dies via jump, and people self-hanging most likely dies")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            ChartView(
                showPercentage: $showPercentage,
                sorteCategories: sorteCategories,
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
                    isSortDescendingly: $isSortDescendingly
                )
            }
            .padding(8)
            .task(id: [showPercentage, isSortDescendingly]) {
                await updateIntervalData()
            }
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .task(id: allDatas) {
            await updateIntervalData()
        }
        .animation(.smooth, value: displayData)
        .animation(.smooth, value: showPercentage)
        .animation(.smooth, value: isSortDescendingly)
        .animation(.smooth, value: sorteCategories)
    }
    
    func updateIntervalData() async {
        var matched: [Entry] = allDatas
        var sumCountPerCategory: [String: Int] = Dictionary(grouping: matched, by: { $0.category }).mapValues({ $0.reduce(0, { $0 + $1.count })})
        maxValue = sumCountPerCategory.values.reduce(0, { max($0, $1)})
        
        if showPercentage {
            for i in matched.indices {
                matched[i].normalise(sum: sumCountPerCategory[matched[i].category] ?? 1)
            }
        }
        
        displayData = matched.sorted(using: KeyPathComparator(\.status, order: .forward))
        
        let catSumPairs: [(String, Int)] = sumCountPerCategory.map({ ($0, $1) })
        sorteCategories = catSumPairs
            .sorted(using: KeyPathComparator(\.1, order: isSortDescendingly ? .reverse : .forward))
            .map(\.0)
    }

}

extension CaseByCategoryAndStatus {
    fileprivate struct ChartView: View {
        @Binding var showPercentage: Bool
        let sorteCategories: [String]
        let displayData: [Entry]
        let maxValue: Int
        
        var body: some View {
            Chart(displayData) { (entry: Entry) in
                BarMark(
                    x: .value("Category", entry.category),
                    y: .value(showPercentage ? "Percentage" : "Count", showPercentage ? entry.percentage : Double(entry.count))
                )
                .foregroundStyle(by: .value("Status", entry.status))
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
            .chartXScale(domain: sorteCategories/*CATEGORIES*/)
            .chartYScale(domain: [0, showPercentage ? 100 : maxValue])
            .chartXAxis {
                AxisMarks(position: .bottom, values: CATEGORIES) { (value: AxisValue) in
                    if let category: String = value.as(String.self) {
                        AxisValueLabel(centered: true) {
                            Text(category)
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
    
    private static let width: CGFloat = 300
    private static let height: CGFloat = 200
    
    var body: some View {
        List {
            Toggle("Show Percentage", isOn: $showPercentage)
            Toggle("Sort Descendingly", isOn: $isSortDescendingly)
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

extension CaseByCategoryAndStatus {
    struct Entry: Identifiable, Hashable, Codable, Equatable {
        struct Key: Hashable, Codable, Equatable {
            let category: String
            let status: String
        }
        var id: Key { key }
        let key: Key
        var count: Int
        var percentage: Double = 0
        
        var category: String {
            key.category
        }
        
        var status: String {
            key.status
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
