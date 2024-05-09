//
//  ReadMeView.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 21/3/2024.
//

import Sankey
import SwiftyJSON
import SwiftUI
import SwiftUIX
import SwiftDate
import Combine

struct ReadMeView: View {
    @Environment(\.colorScheme) var colorScheme
    /// Configuration that controls the data to be shown on screen
    @State private var globalAggregationConfig: GlobalAggregationConfig = GlobalAggregationConfig.defaultValue
    
    /// View-related state that syncs with the size of the slider view
    @State private var sliderRect: CGRect = ScrollViewPreferenceKey.defaultValue
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
    
    /// Datas that will be passed to each figure
    @State private var suicideData: [SuicideData] = []
    @State private var aggregatedSuicideData: [AggregatedSuicideData] = []
    @State private var caseByDistrictTreeData: [CaseByDistrictTree.Entry] = []
    @State private var aggregatedDistrictIncomes: [String: Double] = [:]
    @State private var aggregatedDistrictPopulations: [String: Double] = [:]
    @State private var caseByAgeGroupAndReason: [CaseByAgeGroupAndReason.Entry] = []
    @State private var caseByCategoryAndStatusData: [CaseByCategoryAndStatus.Entry] = []
    @State private var caseByMonthHeatmapData: [CaseByMonthHeatmap.Entry] = []
    @State private var suicideSankeyData: [SankeyLink] = []
    @State private var caseByAgeGroupByDistrictData: [CaseByAgeGroupByDistrictChart.Entry] = []
    @State private var caseByTimeChartData: [CaseByTimeChart.Entry] = []
    
    fileprivate static let coordinateSpaceName: String = "Global"
    fileprivate static let sidePadding: CGFloat = 16
    
    var scrolled: Bool {
        sliderRect.minY < 0
    }
    
    var contentHeight: CGFloat {
        ReadMeView.sidePadding +
        50 + 32 +
        ReadMeView.sidePadding +
        900 +
        ReadMeView.sidePadding +
        450 +
        ReadMeView.sidePadding +
        600 +
        ReadMeView.sidePadding +
        900 +
        ReadMeView.sidePadding
    }

    var body: some View {
        GeometryReader { (geo: GeometryProxy) in
            let size: CGSize = geo.size
            let width: CGFloat = size.width
            let height: CGFloat = size.height
            ScrollView {
                VStack(alignment: .leading, spacing: ReadMeView.sidePadding) {
                    AggregationConfigurationSlider(config: $globalAggregationConfig, timer: $timer)
                        .frame(height: 100)
                        .padding(scrolled ? 16 : 0)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: scrolled ? 20 : 8))
                        .padding(scrolled ? 16 : 0)
                        .padding(.top, geo.safeAreaInsets.top)
                        .frame(width: width - ReadMeView.sidePadding*2, height: 100 + (scrolled ? 32 : 32), alignment: .center)
                        .offset(y: max(0, -sliderRect.minY))
                        .animation(.easeOut, value: scrolled)
                        .zIndex(2)
                        .offset(
                            preferenceKey: ScrollViewPreferenceKey.self,
                            coordinateSpace: ReadMeView.coordinateSpaceName
                        ) { (rect: CGRect) in
                            sliderRect = rect
                        }
                    
                
                    CaseByDistrictTree(
                        _allDatas: caseByDistrictTreeData,
                        aggregatedDistrictIncomes: aggregatedDistrictIncomes,
                        aggregatedDistrictPopulations: aggregatedDistrictPopulations,
                        globalAggregationConfig: $globalAggregationConfig
                    )
                    .frame(width: width - ReadMeView.sidePadding*2, height: 900)
                    
                    CaseByAgeGroupByDistrictChart(
                        allDatas: caseByAgeGroupByDistrictData,
                        globalAggregationConfig: $globalAggregationConfig
                    )
                        .frame(width: width - ReadMeView.sidePadding*2, height: 600)
                    
                    HStack(spacing: ReadMeView.sidePadding) {
                        SuicideSankey(allDatas: suicideSankeyData)
                            .onRotate { (o: UIDeviceOrientation) in
                                /// A trick to update the size of SankeyDiagram
                                self.suicideSankeyData = suicideSankeyData
                            }
                            .frame(width: (width - ReadMeView.sidePadding*3)/2)
                        VStack(spacing: ReadMeView.sidePadding) {
                            CaseByAgeGroupAndReason(allDatas: caseByAgeGroupAndReason)
                            CaseByCategoryAndStatus(allDatas: caseByCategoryAndStatusData)
                        }
                        .frame(width: (width - ReadMeView.sidePadding*3)/2)
                    }
                    .frame(height: 900)
                    
                    HStack(spacing: ReadMeView.sidePadding) {
                        CaseByMonthHeatmap(allDatas: caseByMonthHeatmapData)
                            .frame(width: (width - ReadMeView.sidePadding*3)/2)
                        CaseByTimeChart(allDatas: caseByTimeChartData)
                            .frame(width: (width - ReadMeView.sidePadding*3)/2)
                    }
                    .frame(height: 450)
                }
                .padding(ReadMeView.sidePadding*2)
//                .frame(width: width, height: contentHeight)
            }
            .coordinateSpace(name: ReadMeView.coordinateSpaceName)
            .frame(width: width, height: height)
        }
        .task {
            suicideData = await SuicideData.fetchData()
            fetchEntriesForAllPlots()
        }
        .onChange(of: globalAggregationConfig, initial: false) { _, _ in
            fetchEntriesForAllPlots()
        }
    }
}

extension ReadMeView {
    fileprivate struct AggregationConfigurationSlider: View {
        @Binding var config: GlobalAggregationConfig
        @Binding var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
        var body: some View {
            GeometryReader { (proxy: GeometryProxy) in
                VStack(alignment: .center, spacing: 8) {
                    VStack(spacing: 0) {
                        Text("Hong Kong Suicide Visualizer")
                            .bold()
                            .font(.title3)
                            .foregroundStyle(.primary)
                        Text("by Group 2 VizSoul Team")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            Spacer()
                            yearButton // year
                            monthButton // month
                            weekOfDayButton // week of day
                            timeButton  // time
                            ageGroupButton // age group
                            genderButton // gender
                            houseTypeButton // house type
                            areaButton // area
                            districtButton // district
                            statusButton // status
                            reasonButton // reason
                            categoryButton // category
                            Spacer()
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    HStack {
                        Button {
                            config = GlobalAggregationConfig.defaultValue
                        } label: {
                            Label("Select All", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.plain)
                        .hoverEffect()
                        .padding(.trailing)
                        
                        Button {
                            config = GlobalAggregationConfig.emptyValue
                        } label: {
                            Label("Deselect All", systemImage: "trash.circle")
                        }
                        .buttonStyle(.plain)
                        .hoverEffect()
                        .padding(.trailing)
                    }
                }
                .frame(minWidth: proxy.size.width)
                .frame(height: proxy.size.height)
            }
        }
        
        var yearButton: some View {
            Menu {
                Menu("Animate") {
                    if timer != nil {
                        Button {
                            timer?.upstream.connect().cancel()
                            timer = nil
                        } label: {
                            Label("Stop looping", systemImage: "stop.circle")
                        }
                    }
                    Button {
                        timer = Timer.publish(every: 3, tolerance: 1, on: .main, in: .common).autoconnect()
                    } label: {
                        Label("Loop Year Repeatedly", systemImage: "memories")
                    }
                    .disabled(timer != nil)
                }
                Menu("Year") {
                    ForEach(Array(START_YEAR...END_YEAR), id: \.self) { year in
                        Button {
                            config.years.toggle(element: year)
                        } label: {
                            let isContain: Bool = config.years.contains(year)
                            if isContain {
                                Label(String(year), systemImage: "checkmark")
                            } else {
                                Text(String(year))
                            }
                        }
                        .tag(year)
                    }
                }
            } label: {
                Label("Year", systemImage: "calendar")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
            .onReceive(timer) { _ in
                let firstYear = config.years.first ?? START_YEAR
                if firstYear >= END_YEAR {
                    config.years = [START_YEAR]
                } else {
                    config.years = [firstYear + 1]
                }
            }
        }
        
        var monthButton: some View {
            Menu {
                Section("Month") {
                    ForEach(Array(1...12), id: \.self) { month in
                        Button {
                            config.months.toggle(element: month)
                        } label: {
                            let isContain: Bool = config.months.contains(month)
                            if isContain {
                                Label(DateFormatter().monthSymbols[month-1], systemImage: "checkmark")
                            } else {
                                Text(DateFormatter().monthSymbols[month-1])
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "calendar.badge.clock")
                Label("Month", systemImage: "calendar.badge.clock")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var timeButton: some View {
            Menu {
                Section("Time") {
                    ForEach(Array(0...23), id: \.self) { time in
                        Button {
                            config.times.toggle(element: time)
                        } label: {
                            let isContain: Bool = config.times.contains(time)
                            if isContain {
                                Label(String(time), systemImage: "checkmark")
                            } else {
                                Text(String(time))
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "clock")
                Label("Time", systemImage: "clock")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var weekOfDayButton: some View {
            Menu {
                Section("Week Of Day") {
                    ForEach(WEEK_OF_DAYS, id: \.self) { element in
                        Button {
                            config.weekOfDays.toggle(element: element)
                        } label: {
                            let isContain: Bool = config.weekOfDays.contains(element)
                            if isContain {
                                Label(String(element), systemImage: "checkmark")
                            } else {
                                Text(String(element))
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "clock")
                Label("Week Of Day", systemImage: "calendar.day.timeline.left")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var ageGroupButton: some View {
            Menu {
                Section("Age Group") {
                    ForEach(AGE_GROUPS, id: \.self) { ag in
                        Button {
                            config.ageGroups.toggle(element: ag)
                        } label: {
                            let isContain: Bool = config.ageGroups.contains(ag)
                            if isContain {
                                Label(ag, systemImage: "checkmark")
                            } else {
                                Text(ag)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "person.3")
                Label("Age Group", systemImage: "person.3")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var genderButton: some View {
            Menu {
                Section("Gender") {
                    ForEach(GENDERS, id: \.self) { g in
                        Button {
                            config.genders.toggle(element: g)
                        } label: {
                            let isContain: Bool = config.genders.contains(g)
                            if isContain {
                                Label(g, systemImage: "checkmark")
                            } else {
                                Text(g)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "figure.child")
                Label("Gender", systemImage: "figure.child")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var houseTypeButton: some View {
            Menu {
                Section("House Type") {
                    ForEach(HOUSE_TYPES, id: \.self) { ht in
                        Button {
                            config.houseTypes.toggle(element: ht)
                        } label: {
                            let isContain: Bool = config.houseTypes.contains(ht)
                            if isContain {
                                Label(ht, systemImage: "checkmark")
                            } else {
                                Text(ht)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "house")
                Label("House Type", systemImage: "house")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var areaButton: some View {
            Menu {
                Section("Area") {
                    ForEach(AREAS, id: \.self) { element in
                        Button {
                            config.areas.toggle(element: element)
                        } label: {
                            let isContain: Bool = config.areas.contains(element)
                            if isContain {
                                Label(element, systemImage: "checkmark")
                            } else {
                                Text(element)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "map.fill")
                Label("Area", systemImage: "map.fill")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var districtButton: some View {
            Menu {
                Section("District") {
                    ForEach(DISTRICTS, id: \.self) { element in
                        Button {
                            config.districts.toggle(element: element)
                        } label: {
                            let isContain: Bool = config.districts.contains(element)
                            if isContain {
                                Label(element, systemImage: "checkmark")
                            } else {
                                Text(element)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "house.lodge.fill")
                Label("District", systemImage: "house.lodge.fill")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var statusButton: some View {
            Menu {
                Section("Status") {
                    ForEach(STATUS, id: \.self) { element in
                        Button {
                            config.statuses.toggle(element: element)
                        } label: {
                            let isContain: Bool = config.statuses.contains(element)
                            if isContain {
                                Label(element, systemImage: "checkmark")
                            } else {
                                Text(element)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "person.fill.xmark")
                Label("Status", systemImage: "person.fill.xmark")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var reasonButton: some View {
            Menu {
                Section("Reason") {
                    ForEach(REASONS, id: \.self) { element in
                        Button {
                            config.reasons.toggle(element: element)
                        } label: {
                            let isContain: Bool = config.reasons.contains(element)
                            if isContain {
                                Label(element, systemImage: "checkmark")
                            } else {
                                Text(element)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "questionmark.app.dashed")
                Label("Reason", systemImage: "questionmark.app.dashed")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
        
        var categoryButton: some View {
            Menu {
                Section("Category") {
                    ForEach(CATEGORIES, id: \.self) { element in
                        Button {
                            config.categories.toggle(element: element)
                        } label: {
                            let isContain: Bool = config.categories.contains(element)
                            if isContain {
                                Label(element, systemImage: "checkmark")
                            } else {
                                Text(element)
                            }
                        }
                    }
                }
            } label: {
//                Image(systemName: "oar.2.crossed")
                Label("Category", systemImage: "oar.2.crossed")
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .menuActionDismissBehavior(.disabled)
        }
    }
}

extension ReadMeView {
    func fetchEntriesForAllPlots() {
        Task {
            aggregatedSuicideData = await aggregateSuicideData()
            Task {
                await fetchCaseByDistrictTreeData()
            }
            Task {
                self.caseByAgeGroupAndReason = await fetchCaseByAgeGroupAndReasonData()
            }
            Task {
                self.caseByCategoryAndStatusData = await fetchCaseByCategoryAndStatusData()
            }
            Task {
                self.caseByMonthHeatmapData = await fetchCaseByMonthHeatmapData()
            }
            Task {
                self.suicideSankeyData = await fetchSuicideSankeyData()
            }
            Task {
                self.caseByAgeGroupByDistrictData = await fetchCaseByAgeGroupByDistrictData()
            }
            Task {
                self.caseByTimeChartData = await fetchCaseByTimeChartData()
            }
        }
    }
    
    func aggregateSuicideData() async -> [AggregatedSuicideData] {
        let filteredSuicideData: [SuicideData] = suicideData
            .filter({
                globalAggregationConfig.years.contains($0.year) &&
                globalAggregationConfig.months.contains($0.month) &&
                globalAggregationConfig.areas.contains($0.area) &&
                globalAggregationConfig.weekOfDays.contains($0.weekOfDay) &&
                globalAggregationConfig.districts.contains($0.district) &&
                globalAggregationConfig.ageGroups.contains($0.ageGroup) &&
                globalAggregationConfig.houseTypes.contains($0.houseType) &&
                globalAggregationConfig.genders.contains($0.gender) &&
                globalAggregationConfig.times.contains($0.time) &&
                globalAggregationConfig.statuses.contains($0.status) &&
                globalAggregationConfig.reasons.contains($0.reason) &&
                globalAggregationConfig.categories.contains($0.category)
            })
        return Dictionary(grouping: filteredSuicideData, by: { $0 }).mapValues({
            AggregatedSuicideData(data: $0.first!, value: $0.count)
        }).map({ $0.value })
    }
    
    func fetchCaseByDistrictTreeData() async {
        let filteredIncome: [DistrictIncome] = DistrictIncome
            .districtIncomes
            .filter {
                globalAggregationConfig.years.contains($0.year) &&
                globalAggregationConfig.districts.contains($0.district) &&
                globalAggregationConfig.areas.contains($0.area)
            }
        self.aggregatedDistrictIncomes = Dictionary(grouping: filteredIncome, by: { $0.district })
            .mapValues({ Double($0.reduce(0, { $0 + $1.income }))/Double($0.count) })
        
        let filteredPopulation: [Population] = Population
            .districtPopulations
            .filter {
                globalAggregationConfig.years.contains($0.year) &&
                globalAggregationConfig.districts.contains($0.district) &&
                globalAggregationConfig.areas.contains($0.area)
            }
        self.aggregatedDistrictPopulations = Dictionary(grouping: filteredPopulation, by: { $0.district })
            .mapValues({ Double($0.reduce(0, { $0 + $1.value }))/Double($0.count) })
        
        let key2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            CaseByDistrictTree.Entry.Key(
                area: data.data.area,
                district: data.data.district,
                subDistrict: data.data.subDistrict
            )
        })
        self.caseByDistrictTreeData = key2Entries.map { (key: CaseByDistrictTree.Entry.Key, value: [AggregatedSuicideData]) in
            CaseByDistrictTree.Entry(
                key: key,
                count: value.reduce(0, { $0 + $1.value })
            )
        }
    }
    
    func fetchCaseByAgeGroupAndReasonData() async -> [CaseByAgeGroupAndReason.Entry] {
        let key2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            CaseByAgeGroupAndReason.Entry.Key(
                ageGroup: data.data.ageGroup,
                reason: data.data.reason
            )
        })
        return key2Entries.map { (key: CaseByAgeGroupAndReason.Entry.Key, value: [AggregatedSuicideData]) in
            CaseByAgeGroupAndReason.Entry(
                key: key,
                count: value.reduce(0, { $0 + $1.value })
            )
        }
    }
    
    func fetchCaseByCategoryAndStatusData() async -> [CaseByCategoryAndStatus.Entry] {
        let key2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            CaseByCategoryAndStatus.Entry.Key(
                category: data.data.category,
                status: data.data.status
            )
        })
        return key2Entries.map { (key: CaseByCategoryAndStatus.Entry.Key, value: [AggregatedSuicideData]) in
            CaseByCategoryAndStatus.Entry(
                key: key,
                count: value.reduce(0, { $0 + $1.value })
            )
        }
    }
    
    func fetchCaseByMonthHeatmapData() async -> [CaseByMonthHeatmap.Entry] {
        let key2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            CaseByMonthHeatmap.Entry.Key(
                date: DateInRegion(year: data.data.year, month: data.data.month, day: 1).date
            )
        })
        return key2Entries.map { (key: CaseByMonthHeatmap.Entry.Key, value: [AggregatedSuicideData]) in
            CaseByMonthHeatmap.Entry(
                key: key,
                value: value.reduce(0, { $0 + $1.value })
            )
        }
    }
    
    func fetchSuicideSankeyData() async -> [SankeyLink] {
        let houseCatAndDistrict2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            SankeyNodePair(
                source: data.data.houseType, target: data.data.district
            )
        })
        let catAndHouseCat2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            SankeyNodePair(
                source: data.data.category, target: data.data.houseType
            )
        })
        return catAndHouseCat2Entries
            .merging(houseCatAndDistrict2Entries, uniquingKeysWith: { a, b in b })
            .mapValues({ (value: [AggregatedSuicideData]) in
                value.reduce(Double.zero, { $0 + Double($1.value) })
            })
            .map({ (key: SankeyNodePair, value: Double) in
                SankeyLink(source: key.source, target: key.target, value: value)
            })
    }
    
    func fetchCaseByAgeGroupByDistrictData() async -> [CaseByAgeGroupByDistrictChart.Entry] {
        let key2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            CaseByAgeGroupByDistrictChart.Entry.Key(
                district: data.data.district, ageGroup: data.data.ageGroup
            )
        })
        return key2Entries.map { (key: CaseByAgeGroupByDistrictChart.Entry.Key, value: [AggregatedSuicideData]) in
            CaseByAgeGroupByDistrictChart.Entry(
                key: key,
                count: value.reduce(0, { $0 + $1.value })
            )
        }
    }
    
    func fetchCaseByTimeChartData() async -> [CaseByTimeChart.Entry] {
        let key2Entries = Dictionary(grouping: aggregatedSuicideData, by: { (data: AggregatedSuicideData) in
            CaseByTimeChart.Entry.Key(
                weekOfDay: data.data.weekOfDay, hour: data.data.time
            )
        })
        return key2Entries.map { (key: CaseByTimeChart.Entry.Key, value: [AggregatedSuicideData]) in
            CaseByTimeChart.Entry(
                key: key,
                value: value.reduce(0, { $0 + $1.value })
            )
        }
    }
}

fileprivate struct ScrollViewPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#Preview {
    ReadMeView()
}
