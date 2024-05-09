//
//  CaseByTimeChart.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 24/3/2024.
//

import SwiftUI
import Charts
import SwiftyJSON

struct CaseByTimeChart: View {
    private static let emojiHourScales: [Int: String] = [
        0: "🌝",
        3: "🌛",
        6: "⛅️",
        9: "🌤️",
        12: "☀️",
        15: "🌤️",
        18: "⛅️",
        21: "🌜",
    ]
    
    let allDatas: [Entry]
    let weekOfDays: [String]
    let hour2Index: [Int: Int]
    let index2Hour: [Int: Int]
    let sumCountPerWeekOfDay: [String: Int]
    @State private var showPopover: Bool = false
    @State private var hourDisplayOption: HourDisplayScale = .number
    
    init(allDatas: [Entry]) {
        self.weekOfDays = Array(Set(allDatas.map(\.weekOfDay))).sorted(by: { (a: String, b: String) in
            let aIndex = WEEK_OF_DAYS.firstIndex(of: a) ?? 0
            let bIndex = WEEK_OF_DAYS.firstIndex(of: b) ?? 0
            return aIndex < bIndex
        })
        let hours: [Int] = Array(Set(allDatas.map(\.hour))).sorted()
        self.hour2Index = Dictionary(uniqueKeysWithValues: zip(hours, Array(0..<hours.count)))
        self.index2Hour = Dictionary(uniqueKeysWithValues: zip(Array(0..<hours.count), hours))
        
        var matched = allDatas
        self.sumCountPerWeekOfDay = Dictionary(
            grouping: allDatas,
            by: { $0.weekOfDay }).mapValues({ $0.reduce(Int.zero, { $0 + $1.value })}
            )
        for i in allDatas.indices {
            matched[i].normalise(max: sumCountPerWeekOfDay[matched[i].weekOfDay] ?? 1)
        }
        
        self.allDatas = matched.sorted(using: KeyPathComparator(\.weekOfDay, order: .forward))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide Time")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("Suicide occurs most often at morning")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            Chart(allDatas) { (entry: Entry) in
                PointMark(
                    x: .value("Week Of Day", entry.weekOfDay),
                    y: .value("Hour", hour2Index[entry.hour]!)
                )
                .symbolSize(entry.percentage * 10)
                .foregroundStyle(by: .value("Percentage", entry.percentage))
//                .symbolSize(Double(entry.value))
//                .foregroundStyle(by: .value("Value", entry.value))
                .annotation(position: .overlay) {

                }
            }
            .chartXScale(domain: weekOfDays)
            .chartYScale(domain: [hour2Index.count-1, 0])
//            .chartXAxisLabel(position: .top, alignment: .center) {
//                Text("Week of Days")
//            }
            .chartForegroundStyleScale(range: Gradient(colors: [.yellow, .red]))
//            .chartYAxisLabel(position: .leading, alignment: .center) {
//                Text("Hour")
//            }
            .chartXAxis {
                AxisMarks(position: .top, values: weekOfDays) { (value: AxisValue) in
                    if let weekOfDay: String = value.as(String.self) {
                        AxisValueLabel(centered: true) {
                            VStack {
                                Text(weekOfDay.prefix(3))
                                    .font(.caption)
                                Text(String(sumCountPerWeekOfDay[weekOfDay] ?? 0))
                                    .font(.footnote)
                                    .bold()
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: Array(0..<hour2Index.count)) { (value: AxisValue) in
                    switch hourDisplayOption {
                    case .number:
                        if let index: Int = value.as(Int.self),
                           let hour: Int = index2Hour[index] {
                            AxisValueLabel(centered: false) {
                                Text(String(format: "%02d", hour))
                            }
                        }
                    case .simple:
                        if let index: Int = value.as(Int.self),
                           let hour: Int = index2Hour[index],
                           hour % 3 == 0 {
                            AxisValueLabel(centered: false) {
                                Text(String(format: "%02d", hour))
                            }
                        }
                    case .emoji:
                        if let index: Int = value.as(Int.self),
                           let hour: Int = index2Hour[index],
                           let emoji: String = CaseByTimeChart.emojiHourScales[hour] {
                            AxisValueLabel(centered: false) {
                                Text(emoji)
                            }
                        }
                    }
                }
            }
            .chartLegend(alignment: .bottom)
            .chartOverlay(alignment: .topLeading) { _ in
                VStack {
                    Text("Sum")
                        .font(.caption)
                        .opacity(0)
                    Text("Sum")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .chartPlotStyle { chartContent in
                chartContent
                    .padding(.trailing, -16)
            }
            .padding(.leading, 8)
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
                PopOverView(hourDisplayOption: $hourDisplayOption)
            }
            .padding(8)
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .animation(.smooth, value: allDatas)
    }
}

fileprivate struct PopOverView: View {
    @Binding var hourDisplayOption: HourDisplayScale
    
    private static let width: CGFloat = 400
    private static let height: CGFloat = 200
    
    var body: some View {
        List {
            HStack {
                Text("Hour-axis Scale")
                Spacer()
                Picker(selection: $hourDisplayOption) {
                    ForEach(HourDisplayScale.allCases, id: \.self) { (option: HourDisplayScale) in
                        Text(option.displayText).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
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

fileprivate enum HourDisplayScale: CaseIterable {
    case number
    case simple
    case emoji
    
    var displayText: String {
        switch self {
        case .number:
            "Number"
        case .simple:
            "Simple"
        case .emoji:
            "Emoji"
        }
    }
}

extension CaseByTimeChart {
    struct Entry: Identifiable, Hashable, Codable, Equatable {
        struct Key: Hashable, Codable, Equatable {
            let weekOfDay: String
            let hour: Int
        }
        var id: Key { key }
        let key: Key
        var value: Int
        var percentage: Double = 0
        
        var weekOfDay: String {
            key.weekOfDay
        }
        
        var hour: Int {
            key.hour
        }
        
        init(key: Key, value: Int) {
            self.key = key
            self.value = value
        }
        
        mutating func normalise(max: Int) {
            self.percentage = Double(self.value)/Double(max)*Double(100)
        }
    }
}
