//
//  CaseByAgeGroupByDistrictChart.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 24/3/2024.
//

import SwiftUI
import Charts
import SwiftyJSON

struct CaseByAgeGroupByDistrictChart: View {
    
    let allDatas: [Entry]
    @Binding var globalAggregationConfig: GlobalAggregationConfig
    @State private var maxValue: Int = 100
    @State private var sortedDistrict: [String] = DISTRICTS
    @State private var sumCountPerDistrict: [String: Int] = [:]
    @State private var showPopover: Bool = false
    @State private var displayData: [Entry] = []
    @State private var showPercentage: Bool = false
    @State private var isSortLocally: Bool = true
    @State private var isSortDescendingly: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide Age & District")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("Suicide can occurs anywhere anyone")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            ChartView(
                globalAggregationConfig: $globalAggregationConfig,
                showPercentage: $showPercentage,
                isSortLocally: $isSortLocally,
//                hoveredDistrict: $hoveredDistrict,
                displayData: displayData,
                maxValue: maxValue,
                sortedDistrict: sortedDistrict,
                sumCountPerDistrict: sumCountPerDistrict
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
                    isSortLocally: $isSortLocally,
                    isSortDescendingly: $isSortDescendingly
                )
            }
            .padding(8)
            .task(id: [showPercentage, isSortLocally, isSortDescendingly]) {
                await updateIntervalData()
            }
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .task(id: allDatas) {
            await updateIntervalData()
        }
        .animation(.smooth, value: displayData)
        .animation(.smooth, value: allDatas)
        .animation(.smooth, value: sortedDistrict)
        .animation(.smooth, value: showPercentage)
    }
    
    func updateIntervalData() async {
        var matched: [Entry] = allDatas
        
        let sumCountPerDistrict: [String: Int] = Dictionary(grouping: matched, by: { $0.district }).mapValues({ $0.reduce(0, { $0 + $1.count }) })
        maxValue = sumCountPerDistrict.values.reduce(0, { max($0, $1) })
        
        if showPercentage {
            for i in matched.indices {
                matched[i].normalise(max: sumCountPerDistrict[matched[i].district] ?? 1)
            }
        }
        
//        displayData = matched.sorted(by: { (a: Entry, b: Entry) in
//            if isSortLocally {
//                let aAreaIndex = AREAS.firstIndex(of: DISTRICT2AREA[a.district]!) ?? 0
//                let bAreaIndex = AREAS.firstIndex(of: DISTRICT2AREA[b.district]!) ?? 0
//                if aAreaIndex != bAreaIndex {
//                    return isSortDescendingly ? aAreaIndex > bAreaIndex : aAreaIndex < bAreaIndex
//                }
//            }
//            let aDistrictSum = sumCountPerDistrict[a.district] ?? 0
//            let bDistrictSum = sumCountPerDistrict[b.district] ?? 0
//            if aDistrictSum == bDistrictSum {
//                return isSortDescendingly ? a.ageGroup > b.ageGroup : a.ageGroup < b.ageGroup
//            } else {
//                return isSortDescendingly ? aDistrictSum > bDistrictSum : aDistrictSum < bDistrictSum
//            }
//        })
        displayData = matched.sorted(using: [
            KeyPathComparator(\.district),
            KeyPathComparator(\.ageGroup)
        ])
        sortedDistrict = DISTRICTS.sorted(by: { (a: String, b: String) in
            if isSortLocally {
                let aAreaIndex = AREAS.firstIndex(of: DISTRICT2AREA[a]!) ?? 0
                let bAreaIndex = AREAS.firstIndex(of: DISTRICT2AREA[b]!) ?? 0
                if aAreaIndex == bAreaIndex {
                    if isSortDescendingly {
                        return (sumCountPerDistrict[a] ?? 0) > (sumCountPerDistrict[b] ?? 0)
                    } else {
                        return (sumCountPerDistrict[a] ?? 0) < (sumCountPerDistrict[b] ?? 0)
                    }
                } else {
                    if isSortDescendingly {
                        return aAreaIndex > bAreaIndex
                    } else {
                        return aAreaIndex < bAreaIndex
                    }
                }
            } else {
                if isSortDescendingly {
                    return (sumCountPerDistrict[a] ?? 0) > (sumCountPerDistrict[b] ?? 0)
                } else {
                    return (sumCountPerDistrict[a] ?? 0) < (sumCountPerDistrict[b] ?? 0)
                }
            }
        })
    }
}

extension CaseByAgeGroupByDistrictChart {
    fileprivate struct ChartView: View {
        @Binding var globalAggregationConfig: GlobalAggregationConfig
        @Binding var showPercentage: Bool
        @Binding var isSortLocally: Bool
        let displayData: [Entry]
        let maxValue: Int
        let sortedDistrict: [String]
        let districtsOnChange: [String]
        let districtsInMediean: [String]
        
        /// Data needed for the Hover Annotation
        @State private var hoveredEntry: Entry?
        @State private var hoveredEntryPosition: CGPoint?
        private let entryGroupByDistrict: [String: [Entry]]
        
        init(
            globalAggregationConfig: Binding<GlobalAggregationConfig>,
            showPercentage: Binding<Bool>,
            isSortLocally: Binding<Bool>,
            displayData: [Entry],
            maxValue: Int,
            sortedDistrict: [String],
            sumCountPerDistrict: [String: Int]
        ) {
            self._globalAggregationConfig = globalAggregationConfig
            self._showPercentage = showPercentage
            self._isSortLocally = isSortLocally
            self.displayData = displayData
            self.maxValue = maxValue
            self.sortedDistrict = sortedDistrict
            self.districtsOnChange = sortedDistrict.reduce([String: String](), {
                let area = DISTRICT2AREA[$1]!
                if $0[area] == nil {
                    return $0.merging([(area, $1)], uniquingKeysWith: { _, _ in "" })
                } else {
                    return $0
                }
            }).map({ (key: String, value: String) in
                value
            })
            self.districtsInMediean = Dictionary(grouping: sortedDistrict, by: { DISTRICT2AREA[$0]! })
                .mapValues({ (districts: [String]) in
                    districts[Int(districts.count/2)]
                })
                .map({ (key: String, value: String) in
                    value
                })
            
            var _entryGroupByDistrict: [String: [Entry]] = [:]
            for entry in displayData {
                if _entryGroupByDistrict[entry.district] != nil {
                    if let firstIndex: Int = _entryGroupByDistrict[entry.district]!.firstIndex(where: { (e: Entry) in
                        e.ageGroup > entry.ageGroup
                    }) {
                        _entryGroupByDistrict[entry.district]!.insert(entry, at: firstIndex)
                    } else {
                        _entryGroupByDistrict[entry.district]!.append(entry)
                    }
                } else {
                    _entryGroupByDistrict[entry.district] = [entry]
                }
            }
            self.entryGroupByDistrict = _entryGroupByDistrict
        }
        
        var body: some View {
            Chart(displayData) { (entry: Entry) in
                BarMark(
                    x: .value("District", entry.district),
                    y: .value(showPercentage ? "Percentage" : "Count", showPercentage ? entry.percentage : Double(entry.count))
                )
                .foregroundStyle(by: .value("Age Group", entry.ageGroup))
                .annotation(position: .overlay) {
                    Annotation(entry: entry, showPercentage: showPercentage, isHovered: hoveredEntry == entry)
                }
            }
            .chartXScale(domain: sortedDistrict)
            .chartYScale(domain: [0, showPercentage ? 100 : maxValue])
            .chartXAxis {
                AxisMarks(position: .bottom, values: sortedDistrict) { (value: AxisValue) in
                    if let district: String = value.as(String.self) {
                        let area = DISTRICT2AREA[district]!
                        if districtsOnChange.contains(district) && isSortLocally {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 2))
                                .foregroundStyle(Color.adaptable(light: .black, dark: .white))
                            AxisTick(stroke: StrokeStyle(lineWidth: 2))
                                .foregroundStyle(Color.adaptable(light: .black, dark: .white))
                        }
                        AxisValueLabel(centered: true) {
                            VStack {
                                Text(district)
                                if isSortLocally && area != "港島" && districtsInMediean.contains(district) {
                                    Text(area)
                                }
                            }
                        }
                        if area == "港島" && districtsInMediean.contains(district) && isSortLocally {
                            AxisValueLabel(centered: false, anchor: .top) {
                                VStack {
                                    Text(area).opacity(0)
                                    Text(area)
                                }
                            }
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
            .chartForegroundStyleScale(mapping: { (ageGroup: String) in
                AGE_GROUP2COLOR[ageGroup]!
            })
            .chartLegend(alignment: .bottom) {
                HStack {
                    ForEach(AGE_GROUPS, id: \.self) { (age: String) in
                        HStack {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(AGE_GROUP2COLOR[age]!)
                            Text(age)
                                .font(.footnote)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartOverlay(alignment: .topLeading) { _ in
                if let hoveredEntry: Entry = hoveredEntry,
                   let hoveredEntryPosition: CGPoint = hoveredEntryPosition {
                    let isDistrictIndexLessThanOrEqualToMiddle: Bool = districtIndex(district: hoveredEntry.district) <= (DISTRICTS.count/2)
                    HoverAnnotation(hoveredEntry: hoveredEntry)
                        .animation(.smooth) {
                            $0
                                .offset(hoveredEntryPosition)
                                .offset(x: isDistrictIndexLessThanOrEqualToMiddle ? 0 : -300)
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
                                guard let plotFrame: Anchor<CGRect> = chartProxy.plotFrame else { return }
                                let origin: CGPoint = geometryProxy[plotFrame].origin
                                let location = CGPoint(
                                    x: cGPoint.x - origin.x,
                                    y: cGPoint.y - origin.y
                                )
//                                print(location)
                                guard let (district, value): (String, Double) = chartProxy.value(at: location, as: (String, Double).self)
                                else { return }
                                let hoveredEntries: [Entry] = entryGroupByDistrict[district] ?? []
                                var prefixSum: Double = 0
                                for entry in hoveredEntries {
                                    let entryValue: Double = showPercentage ? entry.percentage : Double(entry.count)
                                    if 0 < value && value < (prefixSum + entryValue) {
                                        hoveredEntry = entry
                                        hoveredEntryPosition = cGPoint
                                        return
                                    }
                                    prefixSum += entryValue
                                }
                            case .ended:
                                hoveredEntry = nil
                                hoveredEntryPosition = nil
                            }
                        }
                        .onTapGesture { (cGPoint: CGPoint) in
                            guard let plotFrame: Anchor<CGRect> = chartProxy.plotFrame else { return }
                            let origin: CGPoint = geometryProxy[plotFrame].origin
                            let location = CGPoint(
                                x: cGPoint.x - origin.x,
                                y: cGPoint.y - origin.y
                            )
//                                print(location)
                            guard let (district, value): (String, Double) = chartProxy.value(at: location, as: (String, Double).self)
                            else { return }
                            let hoveredEntries: [Entry] = entryGroupByDistrict[district] ?? []
                            var prefixSum: Double = 0
                            for entry in hoveredEntries {
                                let entryValue: Double = showPercentage ? entry.percentage : Double(entry.count)
                                if 0 < value && value < (prefixSum + entryValue) {
                                    self.globalAggregationConfig.ageGroups = [entry.ageGroup]
                                    return
                                }
                                prefixSum += entryValue
                            }
                        }
                }
            }
            .gesture(
                MagnifyGesture()
                    .onEnded { (value: MagnifyGesture.Value) in
                        showPercentage = value.magnification > 1
                    }
            )
        }
        
        func districtIndex(district: String?) -> Int {
            guard district != nil else { return 0 }
            return DISTRICTS.firstIndex(where: { $0 == district }) ?? 0
        }
    }
    
    fileprivate struct Annotation: View {
        let entry: Entry
        let showPercentage: Bool
        let isHovered: Bool
        var body: some View {
            VStack {
                if showPercentage {
                    ViewThatFits {
                        Text("\(String(format: "%.2f", entry.percentage))%")
                            .font(.caption)
                            .bold()
                        Text("\(String(format: "%.1f", entry.percentage))%")
                            .font(.caption)
                            .bold()
                        Text("\(String(format: "%.0f", entry.percentage))%")
                            .font(.caption)
                            .bold()
                        Text("\(String(format: "%.0f", entry.percentage))%")
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
    
    fileprivate struct HoverAnnotation: View {
        let hoveredEntry: Entry
        var body: some View {
            VStack(alignment: .leading) {
                Text(hoveredEntry.district)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                (
                    Text(String(hoveredEntry.count))
                        .foregroundStyle(.primary)
                        .font(.title.bold())
                    +
                    Text(" people aged at ")
                        .foregroundStyle(.primary)
                        .font(.body)
                    +
                    Text(String(hoveredEntry.ageGroup))
                        .foregroundStyle(.primary)
                        .font(.title3.bold())
                    +
                    Text(" committed suicide in \(hoveredEntry.district)")
                        .foregroundStyle(.primary)
                        .font(.body)
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(width: 250)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

fileprivate struct PopOverView: View {
    @Binding var showPercentage: Bool
    @Binding var isSortLocally: Bool
    @Binding var isSortDescendingly: Bool
    
    private static let width: CGFloat = 300
    private static let height: CGFloat = 300
    
    var body: some View {
        List {
            Toggle("Show Percentage", isOn: $showPercentage)
            Toggle("Sort Within District", isOn: $isSortLocally)
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

extension CaseByAgeGroupByDistrictChart {
    struct Entry: Identifiable, Hashable, Codable, Equatable {
        struct Key: Hashable, Codable, Equatable {
            let district: String
            let ageGroup: String
        }
        var id: Key { key }
        let key: Key
        var count: Int
        var percentage: Double = 0
        
        var district: String {
            key.district
        }
        
        var ageGroup: String {
            key.ageGroup
        }
        
        init(key: Key, count: Int = 0) {
            self.key = key
            self.count = count
        }
        
        mutating func normalise(max: Int) {
            self.percentage = Double(self.count)/Double(max)*Double(100)
        }
    }
}

