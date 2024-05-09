//
//  CaseByTimeHeatmap.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 23/3/2024.
//

import Foundation
import SwiftUI
import SwiftyJSON
import Charts
import SwiftDate

struct CaseByMonthHeatmap: View {
    
    /// Data needed for the Hover Annotation
    @State private var hoveredEntry: Entry?
    @State private var hoveredEntryPosition: CGPoint?
    
//    let startYear: Int
//    let endYear: Int
    let allDatas: [Entry]
    let months: [Int]
    let years2Index: [Int: Int]
    let months2Index: [Int: Int]
    let index2Year: [Int: Int]
    let index2Month: [Int: Int]
    let maxValue: Double
    let minValue: Double
    
    init(allDatas: [Entry]) {
        self.allDatas = allDatas
        self.maxValue = Double(allDatas.map(\.value).max() ?? 0)
        self.minValue = Double(allDatas.map(\.value).min() ?? 0)
        self.months = Array(Set(allDatas.map(\.date.month))).sorted()
        
        let years: [Int] = Array(Set(allDatas.map(\.date.year))).sorted()
        self.years2Index = Dictionary(uniqueKeysWithValues: zip(years, Array(0..<years.count)))
//        var years2Index = Dictionary(grouping: allDatas, by: { $0.date.year }).mapValues({ $0.reduce(0, { $0 + $1.value }) })
//        var runningSum: Int = 0
//        for year in years {
//            years2Index[year]! += runningSum
//            runningSum += years2Index[year]!
//        }
//        self.years2Index = years2Index
        self.index2Year = Dictionary(uniqueKeysWithValues: years2Index.map({ ($0.value, $0.key) }))
        self.months2Index = Dictionary(uniqueKeysWithValues: zip(months, Array(0..<months.count)))
        self.index2Month = Dictionary(uniqueKeysWithValues: months2Index.map({ ($0.value, $0.key) }))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide Period")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("Suicide can occurs anytime")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            Chart(allDatas) { (entry: Entry) in
                RectangleMark(
//                    xStart: .value("xStart", Double(years2Index[entry.date.year - 1] ?? 0)),
//                    xEnd: .value("xEnd", Double(years2Index[entry.date.year]!)),
                    xStart: .value("xStart", Double(years2Index[entry.date.year]!)),
                    xEnd: .value("xEnd", Double(years2Index[entry.date.year]! + 1)),
                    yStart: .value("yStart", Double(months2Index[entry.date.month]!)),
                    yEnd: .value("yEnd", Double(months2Index[entry.date.month]! + 1))
                )
                .foregroundStyle(by: .value("Value", entry.value))
                .annotation(position: .overlay) {
                    Text("\(entry.value)").bold()
                }
            }
//            .chartXScale(domain: [0, years2Index.values.max() ?? 0])
            .chartXScale(domain: [0, years2Index.count])
            .chartYScale(domain: [months2Index.count, 0])
            .chartForegroundStyleScale(mapping: { (value: Int) in
                let delta = Double(value) - minValue
                let maxDiff = maxValue - minValue
                return if delta/maxDiff >=  Double(3) / Double(4) {
                    Color(red: 1, green: 0, blue: 0)
                } else if delta/maxDiff >=  Double(2) / Double(4) {
                    Color(red: 0.75, green: 0, blue: 0)
                } else if delta/maxDiff >=  Double(1) / Double(4) {
                    Color(red: 0.5, green: 0, blue: 0)
                } else {
                    Color(red: 0.25, green: 0, blue: 0)
                }
            })
//            .chartForegroundStyleScale(range: Gradient(colors: [.yellow, .red]))
            .chartLegend(position: .bottom, alignment: .bottom, spacing: 0) {
                HStack {
                    ForEach([1, 0.75, 0.5, 0.25], id: \.self) { (value: Double) in
                        HStack {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(Color(red: value, green: 0, blue: 0))
                            Text("\(Int((value-1)*maxValue))-\(Int(value*maxValue))")
                                .font(.footnote)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .top, values: Array(0...years2Index.count)) { (value: AxisValue) in
                    if let year: Double = value.as(Double.self), year <= Double(years2Index.count - 1) {
                        AxisValueLabel(centered: true) {
                            Text(String(index2Year[Int(year)]!))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: Array(0...months2Index.count)) { (value: AxisValue) in
                    if let month: Double = value.as(Double.self), month <= Double(months2Index.count - 1) {
                        AxisValueLabel(centered: true) {
                            let dateStr: String = "2019-\(index2Month[Int(month)]!)-01"
                            let date: DateInRegion = dateStr.toDate("yyyy-MM-dd")!
                            let monStr: String = date.toFormat("LLLL", locale: nil)
                            Text(monStr.prefix(3))
                        }
                    }
                }
            }
            .chartLegend(alignment: .bottom)
            .chartOverlay(alignment: .topLeading) { _ in
                if let hoveredEntry: Entry = hoveredEntry,
                   let hoveredEntryPosition: CGPoint = hoveredEntryPosition {
                    HoverAnnotation(hoveredEntry: hoveredEntry)
                        .animation(.smooth) {
                            $0.offset(hoveredEntryPosition)
                        }
                }
            }
            .chartOverlay { (chartProxy: ChartProxy) in
                GeometryReader { (geometryProxy: GeometryProxy) in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover(coordinateSpace: .local) { (phase: HoverPhase) in
                            switch phase {
                            case .active(let cGPoint):
                                guard let plotFrameAnchor: Anchor<CGRect> = chartProxy.plotFrame else { return }
                                let plotFrame: CGRect = geometryProxy[plotFrameAnchor]
                                let origin: CGPoint = plotFrame.origin
                                let location = CGPoint(
                                    x: cGPoint.x - origin.x,
                                    y: cGPoint.y - origin.y
                                )
//                                print(location)
                                guard let (year, month): (Double, Double) = chartProxy.value(at: location, as: (Double, Double).self)
                                else { return }
//                                print(year, month)
                                if let hoveredEntry: Entry = allDatas.first(where: { (entry: Entry) in
                                    let entryYear: Int = entry.date.year
                                    let entryMonth: Int = entry.date.month
                                    let xStart: Double = Double(years2Index[entryYear]!)
                                    let xEnd: Double = Double(years2Index[entryYear]!) + 1
                                    let yStart: Double = Double(months2Index[entryMonth]!)
                                    let yEnd: Double = Double(months2Index[entryMonth]!) + 1
                                    return xStart < year && year < xEnd && yStart < month && month < yEnd
                                }) {
                                    self.hoveredEntry = hoveredEntry
                                    hoveredEntryPosition = CGPoint(
                                        x: cGPoint.x > plotFrame.midX ? cGPoint.x - 300 : cGPoint.x,
                                        y: cGPoint.y > plotFrame.midY ? cGPoint.y - 150 : cGPoint.y
                                    )
                                }
                            case .ended:
                                hoveredEntry = nil
                                hoveredEntryPosition = nil
                            }
                        }
                }
            }
            HStack {
                ForEach([0.25, 0.5, 0.75, 1], id: \.self) { (value: Double) in
                    let maxDiff = maxValue - minValue
                    HStack {
                        Rectangle()
                            .frame(width: 30, height: 10)
                            .foregroundStyle(Color(red: value, green: 0, blue: 0))
                        Text("\(Int((value-0.25)*maxDiff + minValue))-\(Int(value*maxDiff + minValue))")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .animation(.spring, value: allDatas)
    }
    
    func initialisation(allDatas: [Entry]) {
        
    }
}

extension CaseByMonthHeatmap {
    fileprivate struct HoverAnnotation: View {
        let hoveredEntry: Entry
        var body: some View {
            let dateStr: String = "2019-\(hoveredEntry.date.month)-01"
            let date: DateInRegion = dateStr.toDate("yyyy-MM-dd")!
            let monStr: String = date.toFormat("LLLL", locale: nil)
            VStack(alignment: .leading) {
                Text(String(hoveredEntry.date.year))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                (
                    Text(String(hoveredEntry.value))
                        .foregroundStyle(.primary)
                        .font(.title.bold())
                    +
                    Text(" people committed suicide at ")
                        .foregroundStyle(.primary)
                        .font(.body)
                    +
                    Text("\(monStr), \(String(hoveredEntry.date.year))")
                        .foregroundStyle(.primary)
                        .font(.title3.bold())
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(width: 250)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

extension CaseByMonthHeatmap {
    struct Entry: Identifiable, Codable, Hashable, Equatable {
        struct Key: Codable, Hashable, Equatable {
            let date: Date
        }
        var id: Key { key }
        let key: Key
        var value: Int
        
        var date: Date {
            key.date
        }
        
        init(key: Key, value: Int) {
            self.key = key
            self.value = value
        }
    }
}
