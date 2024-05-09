//
//  CaseByDistrictTree.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 25/3/2024.
//

import SwiftUI
import SwiftyJSON
import SwiftUIX
import CoreLocation
import MapKit

struct CaseByDistrictTree: View {
    typealias Division = PlotConfiguration.RegionDivision
    let _allDatas: [Entry]
    let aggregatedDistrictIncomes: [String: Double]
    let aggregatedDistrictPopulations: [String: Double]
    @Binding var globalAggregationConfig: GlobalAggregationConfig
    @State private var _area2district2subDistrict2Entry: [String: [String: [String: Entry]]] = [:]
    @State private var showPopover: Bool = false
    @State private var config: PlotConfiguration = .init()
    @State private var displayData: [String: [Entry]] = [:]
    @State private var displayVector: [String: AnimatableVector] = [:]
    @State private var polygons: [MKPolygon] = []
    @State private var districtEntries: [Entry] = Array(repeating: Entry(), count: 18)
    @Namespace var namespace
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide District")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("Suicide happens anywhere")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            TabView(selection: $config.showMapView) {
                NestedTree(
                    globalAggregationConfig: $globalAggregationConfig,
                    displayData: $displayData,
                    displayVector: $displayVector,
                    config: $config,
                    aggregatedDistrictIncomes: aggregatedDistrictIncomes,
                    aggregatedDistrictPopulations: aggregatedDistrictPopulations
                )
                .tag(false)
                CaseByDistrictMap(
                    polygons: polygons,
                    showPercentage: config.showPercentage,
                    entries: districtEntries
                )
                .tag(true)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                MagnifyGesture()
                    .onEnded { (v: MagnifyGesture.Value) in
                        if v.magnification > 1 {
                            config.division = config.division.zoomIn()
                        } else {
                            config.division = config.division.zoomOut()
                        }
                    }
            )
            .task(id: config) {
                await reorderDisplayData()
            }
            .padding(.bottom, 8)
            HStack {
                ForEach(Division.allCases, id: \.self) {
                    Legend(
                        allDatas: _allDatas,
                        division: $0,
                        districtDisplayOption: config.districtDisplayOption,
                        aggregatedDistrictPopulations: aggregatedDistrictPopulations
                    )
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showPopover = true
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .padding(8)
            .onTapGesture {
                print("tapped")
            }
            .contentShape(Circle())
            .hoverEffect()
            .popover(isPresented: $showPopover) {
                PopOverView(config: $config, namespace: namespace)
            }
            .padding(8)
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .task(id: _allDatas) {
            await updateIntervalData()
            await updateGranularity()
        }
        .task {
            await loadGeoData()
        }
//        .animation(.smooth, value: config)
        /// Note: Cannot chnage to .smooth or .spring because the animation in`displayData` will yield negative value
        .animation(.easeInOut, value: displayData)
        .animation(.smooth, value: _allDatas)
    }
    
    func loadGeoData() async {
        let file: String = "hksar_18_district_boundary.json"
        guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }
        
        guard let geoJsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        
        if let features = try? MKGeoJSONDecoder().decode(geoJsonData) as? [MKGeoJSONFeature] {
            // print(features[0].geometry[0])
            self.polygons = features.compactMap({ $0.geometry.first as? MKPolygon })
        } else {
            print("Failed to parse to [MKGeoJSONFeature]")
        }
    }
    
    func updateIntervalData() async {
        var area2district2subDistrict2Entry: [String: [String: [String: Entry]]] = [:]
        
        for match in _allDatas {
            let area: String = match.area
            let district: String = match.district
            let subDistrict: String = match.subDistrict
            let count: Int = match.count
            
            if let existingDistrict2Subdistrict2Entry: [String: [String: Entry]] = area2district2subDistrict2Entry[area] {
                if let existingSubdistrict2Entry: [String: Entry] = existingDistrict2Subdistrict2Entry[district] {
                    if existingSubdistrict2Entry[subDistrict] != nil {
                        area2district2subDistrict2Entry[area]![district]![subDistrict]!.count += count
                    } else {
                        area2district2subDistrict2Entry[area]![district]![subDistrict] = match
                    }
                } else {
                    area2district2subDistrict2Entry[area]![district] = [subDistrict: match]
                }
            } else {
                area2district2subDistrict2Entry[area] = [district: [subDistrict: match]]
            }
        }
        self._area2district2subDistrict2Entry = area2district2subDistrict2Entry
    }
    
    func districtSuicideRate(for entry: CaseByDistrictTree.Entry) -> Double {
        Double(entry.count) / aggregatedDistrictPopulations[entry.district, default: 1] * 100
    }
    
    fileprivate func normaliseEntries<Entries>(entries: Entries, granularity: Division) -> [Entry] where Entries: Collection<Entry> {
        if granularity == .district && config.districtDisplayOption == .rate {
            let rates = entries.map({ districtSuicideRate(for: $0) })
            let max = rates.max() ?? 0
            let sum = rates.reduce(0, {$0 + $1})
            return entries.map({ entry in
                let rate = districtSuicideRate(for: entry)
                return Entry(
                    key: entry.key,
                    count: entry.count,
                    percentage: rate/sum * 100,
                    red: 0,
                    green: 1,
                    blue: rate/max
                ) })
        } else {
            let counts: [Int] = entries.map(\.count)
            let max: Int = counts.max() ?? 0
            let sum: Int = counts.reduce(0, {$0 + $1})
            return entries.map({ Entry(copee: $0, max: max, sum: sum, granularity: granularity) })
        }
    }
    
    fileprivate func updateDisplayData<Entries>(
        key: String,
        entries: Entries,
        granularity: Division,
        displayData: inout [String: [Entry]],
        displayVector: inout [String: AnimatableVector]
    ) where Entries: Collection<Entry> {
        var normalised: [Entry] = normaliseEntries(entries: entries, granularity: granularity)
        if granularity == .district {
            for entry in normalised {
                if let districtIndex: Int = DISTRICTS.firstIndex(of: entry.district) {
                    self.districtEntries[districtIndex] = entry
                }
            }
        }
        if granularity == .district && config.sortingOption == .income {
            normalised = normalised.sorted(by: { a, b in
                if config.isSortDescendingly {
                    aggregatedDistrictIncomes[a.district]! > aggregatedDistrictIncomes[b.district]!
                } else {
                    aggregatedDistrictIncomes[a.district]! < aggregatedDistrictIncomes[b.district]!
                }
            })
            displayData[key] = normalised
            displayVector[key] = AnimatableVector(
                values: normalised
                    .map({ entry in
                        switch config.districtDisplayOption {
                        case .rate:
                            districtSuicideRate(for: entry)
                        case .count:
                            Double(entry.count)
                        }
                    })
            )
        } else if granularity == .district && config.sortingOption == .rate {
            normalised = normalised.sorted(by: { (a: Entry, b: Entry) in
                let aRate = districtSuicideRate(for: a)
                let bRate = districtSuicideRate(for: b)
                if config.isSortDescendingly {
                    return aRate > bRate
                } else {
                    return aRate < bRate
                }
            })
            displayData[key] = normalised
            displayVector[key] = AnimatableVector(
                values: normalised
                    .map({ entry in
                        switch config.districtDisplayOption {
                        case .rate:
                            districtSuicideRate(for: entry)
                        case .count:
                            Double(entry.count)
                        }
                    })
            )
        } else {
            let sortedEntries = normalised.sorted(using: KeyPathComparator(\.count, order: config.isSortDescendingly ? .reverse : .forward))
            let values: [Double] = sortedEntries.map({ Double($0.count) })
            if granularity == .district {
                displayVector[key] = AnimatableVector(
                    values: sortedEntries
                        .map({ entry in
                            switch config.districtDisplayOption {
                            case .rate:
                                districtSuicideRate(for: entry)
                            case .count:
                                Double(entry.count)
                            }
                        })
                )
            } else {
                displayVector[key] = AnimatableVector(values: values)
            }
            displayData[key] = sortedEntries
        }
    }
    
    fileprivate func updateGranularity() async {
        var aggregatedAreas: [Entry] = []
        var _displayData: [String: [Entry]] = [:]
        var _displayVector: [String: AnimatableVector] = [:]
        if _area2district2subDistrict2Entry.isEmpty {
            self.districtEntries = Array(repeating: Entry(), count: 18)
        }
        for (area, district2subdistrict2entry) in _area2district2subDistrict2Entry {
            var aggregatedDistricts: [Entry] = []
            var aggregatedArea = Entry()
            for (district, subdistrict2entry) in district2subdistrict2entry {
                var aggregatedDistrict = Entry()
                for (subdistrict, entry) in subdistrict2entry {
                    
                    aggregatedArea = Entry(
                        area: entry.area,
                        district: entry.district,
                        subDistrict: entry.subDistrict,
                        count: aggregatedArea.count + entry.count
                    )
                    aggregatedDistrict = Entry(
                        area: entry.area,
                        district: entry.district,
                        subDistrict: entry.subDistrict,
                        count: aggregatedDistrict.count + entry.count
                    )
                }
                updateDisplayData(
                    key: district,
                    entries: subdistrict2entry.values,
                    granularity: .subDistrict,
                    displayData: &_displayData,
                    displayVector: &_displayVector
                )
                aggregatedDistricts += [aggregatedDistrict]
            }
            updateDisplayData(
                key: area,
                entries: aggregatedDistricts,
                granularity: .district,
                displayData: &_displayData,
                displayVector: &_displayVector
            )
            aggregatedAreas += [aggregatedArea]
        }
        updateDisplayData(
            key: "",
            entries: aggregatedAreas,
            granularity: .area,
            displayData: &_displayData,
            displayVector: &_displayVector
        )
        self.displayData = _displayData
        self.displayVector = _displayVector
    }
    
    fileprivate func reorderDisplayData() async {
        withAnimation {
            for (key, entries) in displayData {
                let entries = if AREAS.contains(key) {
                    normaliseEntries(entries: entries, granularity: .district)
                } else {
                    entries
                }
                if config.division == .district && config.sortingOption == .income && AREAS.contains(key) {
                    let sortedEntries = entries.sorted(by: { a, b in
                        if config.isSortDescendingly {
                            aggregatedDistrictIncomes[a.district, default: 0] > aggregatedDistrictIncomes[b.district, default: 0]
                        } else {
                            aggregatedDistrictIncomes[a.district, default: 0] < aggregatedDistrictIncomes[b.district, default: 0]
                        }
                    })
                    displayData[key] = sortedEntries
                    displayVector[key] = AnimatableVector(
                        values: sortedEntries
                            .map({ entry in
                                switch config.districtDisplayOption {
                                case .rate:
                                    districtSuicideRate(for: entry)
                                case .count:
                                    Double(entry.count)
                                }
                            })
                    )
                    
                } else if config.division == .district && (config.sortingOption == .rate || !AREAS.contains(key)) {
                    let sortedEntries = entries.sorted { (a: Entry, b: Entry) in
                        let aRate = districtSuicideRate(for: a)
                        let bRate = districtSuicideRate(for: b)
                        if config.isSortDescendingly {
                            return aRate > bRate
                        } else {
                            return aRate < bRate
                        }
                    }
                    let values: [Double] = sortedEntries.map({ districtSuicideRate(for: $0) })
                    /// Note: Always assign layer-relevant data before display-relevant data so that the layout could work properly
                    displayVector[key] = AnimatableVector(
                        values: sortedEntries
                            .map({ entry in
                                switch config.districtDisplayOption {
                                case .rate:
                                    districtSuicideRate(for: entry)
                                case .count:
                                    Double(entry.count)
                                }
                            })
                    )
                    displayData[key] = sortedEntries
                } else {
                    let sortedEntries = entries.sorted(using: KeyPathComparator(\.count, order: config.isSortDescendingly ? .reverse : .forward))
                    let values: [Double] = sortedEntries.map({ Double($0.count) })
                    displayVector[key] = AnimatableVector(
                        values: sortedEntries
                            .map({ entry in
                                switch config.districtDisplayOption {
                                case .rate:
                                    districtSuicideRate(for: entry)
                                case .count:
                                    Double(entry.count)
                                }
                            })
                    )
                    displayData[key] = sortedEntries
                }
            }
        }
    }
}

extension CaseByDistrictTree {
    fileprivate struct Legend: View {
        let minValue: Int
        let maxValue: Int
        let division: Division
        let districtDisplayOption: PlotConfiguration.DistrictDisplayOption
        init(
            allDatas: [Entry],
            division: Division,
            districtDisplayOption: CaseByDistrictTree.PlotConfiguration.DistrictDisplayOption,
            aggregatedDistrictPopulations: [String: Double]
        ) {
            self.division = division
            self.districtDisplayOption = districtDisplayOption
            let grouping: [Int] = Dictionary(grouping: allDatas) {
                switch division {
                case .area: $0.area
                case .district: $0.district
                case .subDistrict: $0.subDistrict
                }
            }
            .mapValues { $0.reduce(0) { $0 + $1.count } }
            .map {
                if division == .district && districtDisplayOption == .rate {
                    Int(Double($1) / aggregatedDistrictPopulations[$0, default: 1] * 100)
                } else {
                    $1
                }
            }
            self.minValue = grouping.min() ?? 0
            self.maxValue = grouping.max() ?? 0
        }
        var body: some View {
            VStack(spacing: 8) {
                let colors: [Color] = switch division {
                case .area:  [
                    Color(red: 1, green: 0, blue: 0),
                    Color(red: 1, green: 1, blue: 0)
                ]
                case .district: [
                    Color(red: 0, green: 1, blue: 0),
                    Color(red: 0, green: 1, blue: 1)
                ]
                case .subDistrict: [
                    Color(red: 0, green: 1, blue: 1),
                    Color(red: 1, green: 0, blue: 1)
                ]
                }
                let isDistrictCount: Bool = districtDisplayOption == .count
                HStack {
                    Spacer()
                    switch division {
                    case .area, .subDistrict: Text("Suicide Count")
                            .foregroundStyle(.primary)
                    case .district: (
                        Text("Suicide Rate")
                            .foregroundStyle(isDistrictCount ? .secondary : .primary)
                            .bold(!isDistrictCount)
                        +
                        Text(" / ")
                            .foregroundStyle(.primary)
                        +
                        Text("Suicide Count")
                            .foregroundStyle(isDistrictCount ? .primary : .secondary)
                            .bold(isDistrictCount)
                        )
                    }
                    Spacer()
                }
                .animation(.smooth, value: isDistrictCount)
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 5)
                HStack {
                    Text("\(minValue)")
                        .foregroundStyle(.primary)
                        .bold()
                    Spacer()
                    Text(division.name)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(maxValue)")
                        .foregroundStyle(.primary)
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

}

extension CaseByDistrictTree {
    fileprivate struct CaseByDistrictMap: View {
        let polygons: [MKPolygon]
        let strokeColor: Color
        let lineWidth: CGFloat
        let entries: [Entry]
        let showPercentage: Bool
        
        init(
            polygons: [MKPolygon] = [],
            strokeColor: Color = .primary,
            lineWidth: CGFloat = 1,
            showPercentage: Bool = false,
            entries: [Entry]
        ) {
            self.polygons = polygons
            self.strokeColor = strokeColor
            self.lineWidth = lineWidth
            self.showPercentage = showPercentage
            self.entries = entries
        }
        
        var body: some View {
            Map(
                bounds: MapCameraBounds(
                    centerCoordinateBounds: MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: 22.37908,
                            longitude: 114.10598
                        ),
                        latitudinalMeters: 100000,
                        longitudinalMeters: 100000
                    ),
                    minimumDistance: 50000)
            ) {
                if polygons.count == entries.count {
                    ForEach(0...(polygons.count-1), id: \.self) { (index: Int) in
                        let polygon: MKPolygon = self.polygons[index]
                        let color: Color = entries[index].color
                        MapPolygon(polygon)
                            .mapOverlayLevel(level: .aboveLabels)
                            .foregroundStyle(color.opacity(0.6))
                            .stroke(strokeColor, lineWidth: lineWidth)
                    }
                }
                ForEach(0...17, id: \.self) { (index: Int) in
                    let coor: (Double, Double) = COORDINATES[index]
                    let latitude: Double = coor.0
                    let longitude: Double = coor.1
                    let district: String = DISTRICTS[index]
                    Annotation(
                        showPercentage ? String(format: "%.2f", entries[index].percentage) + "%" : "\(entries[index].count)",
                        coordinate: CLLocationCoordinate2D(
                            latitude: latitude,
                            longitude: longitude
                        )) {
                        Text(district)
                            .bold()
                            .foregroundStyle(.black)
                    }
//                        .annotationTitles(.hidden)
                }
            }
        }
        
        func getCoordinatesInEPSG3857(coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
            let longitudeInEPSG4326: Double = coordinate.longitude
            let latitudeInEPSG4326: Double = coordinate.latitude
            let longitudeInEPSG3857 = (longitudeInEPSG4326 * 20037508.34 / 180)
            let latitudeInEPSG3857 = (log(tan((90 + latitudeInEPSG4326) * Double.pi / 360)) / (Double.pi / 180)) * (20037508.34 / 180)

            return CLLocationCoordinate2D(latitude: latitudeInEPSG3857, longitude: longitudeInEPSG3857)
        }
    }
    fileprivate struct NestedTree: View {
        @Binding var globalAggregationConfig: GlobalAggregationConfig
        @Binding var displayData: [String: [Entry]]
        @Binding var displayVector: [String: AnimatableVector]
        @Binding var config: PlotConfiguration
        let data: [Entry]
        let vector: AnimatableVector
        let indexKey: String
        let level: Division
        let aggregatedDistrictIncomes: [String: Double]
        let aggregatedDistrictPopulations: [String: Double]
        
        init(
            globalAggregationConfig: Binding<GlobalAggregationConfig>,
            displayData: Binding<[String : [Entry]]>,
            displayVector: Binding<[String : AnimatableVector]>,
            config: Binding<PlotConfiguration>,
            indexKey: String = "",
            level: Division = .area,
            aggregatedDistrictIncomes: [String: Double] = [:],
            aggregatedDistrictPopulations: [String: Double]
        ) {
            self._globalAggregationConfig = globalAggregationConfig
            self._displayData = displayData
            self._displayVector = displayVector
            self._config = config
            self.data = displayData.wrappedValue[indexKey] ?? []
            self.vector = displayVector.wrappedValue[indexKey] ?? AnimatableVector(values: [])
            self.indexKey = indexKey
            self.level = level
            self.aggregatedDistrictIncomes = aggregatedDistrictIncomes
            self.aggregatedDistrictPopulations = aggregatedDistrictPopulations
        }
        
        var body: some View {
            if self.vector.values.reduce(0, { $0 + $1 }) != 0 {
                if indexKey == "九龍" {
                    
                }
                TreeLayout(vector: vector) {
                    ForEach(data) { (entry: Entry) in
                        GeometryReader { (proxy: GeometryProxy) in
                            let nextLevel: Division = level.zoomIn()
                            let nextIndexKey: String = nextLevel.indexKey(entry: entry)
                            TreeRectangle(
                                entry: entry,
                                config: config,
                                aggregatedDistrictIncomes: aggregatedDistrictIncomes,
                                aggregatedDistrictPopulations: aggregatedDistrictPopulations
                            )
                            .layoutValue(key: TreeLayout.TreeValue.self, value: Double(entry.count))
                            .overlay {
                                if config.division != level,
                                   config.division <= nextLevel,
                                   displayData[nextIndexKey] != nil,
                                   displayVector[nextIndexKey] != nil{
                                    NestedTree(
                                        globalAggregationConfig: $globalAggregationConfig,
                                        displayData: $displayData,
                                        displayVector: $displayVector,
                                        config: $config,
                                        indexKey: nextIndexKey,
                                        level: nextLevel,
                                        aggregatedDistrictIncomes: aggregatedDistrictIncomes,
                                        aggregatedDistrictPopulations: aggregatedDistrictPopulations
                                    )
                                    .padding()
                                }
                            }
//                            .contextMenu {
//                                let previousLevel: Division = level.zoomOut()
//                                let previousIndexKey: String = previousLevel.indexKey(entry: entry)
//                                let canGoDeep = nextLevel != level && displayData[nextIndexKey] != nil && displayVector[nextIndexKey] != nil
//                                let canGoUp = previousLevel != level && displayData[previousIndexKey] != nil && displayVector[previousIndexKey] != nil
//                                let notSubDistrict: Bool = level != .subDistrict
//                                if canGoUp {
//                                    Button {
//                                        config.division = previousLevel
//                                    } label: {
//                                        Label("Zoom Out", systemImage: "minus.magnifyingglass")
//                                    }
//                                }
//                                if canGoDeep {
//                                    Button {
//                                        config.division = nextLevel
//                                    } label: {
//                                        Label("Zoom In", systemImage: "plus.magnifyingglass")
//                                    }
//                                }
//                                if notSubDistrict {
//                                    Button {
//                                        if level == .area {
//                                            globalAggregationConfig.areas = [entry.area]
//                                        } else if level == .district {
//                                            globalAggregationConfig.districts = [entry.district]
//                                        }
//                                    } label: {
//                                        Label("Only Focus on \(level == .area ? entry.area : entry.district)", systemImage: "magnifyingglass")
//                                    }
//                                }
//                            } preview: {
//                                if nextLevel != level, displayData[nextIndexKey] != nil, displayVector[nextIndexKey] != nil{
//                                    NestedTree(
//                                        globalAggregationConfig: $globalAggregationConfig,
//                                        displayData: $displayData,
//                                        displayVector: $displayVector,
//                                        config: $config,
//                                        indexKey: nextIndexKey,
//                                        level: nextLevel,
//                                        aggregatedDistrictIncomes: aggregatedDistrictIncomes
//                                    )
//                                    .frame(idealWidth: proxy.size.width, idealHeight: proxy.size.height)
//                                } else {
//                                    TreeRectangle(entry: entry, config: config, aggregatedDistrictIncomes: aggregatedDistrictIncomes)
//                                        .frame(idealWidth: 300, idealHeight: 300)
//                                }
//                            }
                        }
                        .layoutValue(key: TreeLayout.TreeValue.self, value: config.sortingOption == .income && level == .district && AREAS.contains(indexKey) ? aggregatedDistrictIncomes[entry.district, default: 0] : Double(entry.count))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

extension CaseByDistrictTree {
    fileprivate struct TreeRectangle: View {
        let entry: Entry
        let config: PlotConfiguration
        let aggregatedDistrictIncomes: [String: Double]
        let aggregatedDistrictPopulations: [String: Double]
        static private let spacings: [CGFloat] = [8, 4, 2, 0]
        static private let granularities: [String] = ["2", "1", "0"]
        var body: some View {
            Rectangle()
                .fill(entry.color)
                .border(Color.primary)
                .overlay {
                    ViewThatFits {
                        ForEach(TreeRectangle.spacings, id: \.self) { (spacing: CGFloat) in
                            label(with: spacing)
                        }
                        regionText
                        Text(config.showPercentage ? "\(String(format: "%.02f", entry.percentage))%" : "\(entry.count)")
                            .bold()
                            .font(.title2)
                            .foregroundStyle(.black)
                        Text("")
                    }
                }
        }
        
        var regionText: some View {
            Text(config.division == .area ? entry.area : config.division == .district ? entry.district : entry.subDistrict)
                .font(config.division.font)
                .foregroundStyle(Color.black)
        }
        
        @ViewBuilder
        func label(with granularity: String, spacing: CGFloat) -> some View {
            VStack(alignment: .center, spacing: spacing) {
                VStack(alignment: .center, spacing: 0) {
                    regionText
                    if config.division == .district, config.sortingOption == .income {
                        Text("$\(Int(aggregatedDistrictIncomes[entry.district] ?? 0))")
                            .foregroundStyle(.black)
                    }
                }
                if config.division == .district && config.districtDisplayOption == .rate {
                    let rate = Int(Double(entry.count) / aggregatedDistrictPopulations[entry.district, default: 1] * 100)
                    Text("\(rate)")
                        .bold()
                        .font(.title2)
                        .foregroundStyle(.black)
                } else {
                    Text(config.showPercentage ? "\(String(format: "%.0\(granularity)f", entry.percentage))%" : "\(entry.count)")
                        .bold()
                        .font(.title2)
                        .foregroundStyle(.black)
                }
            }
        }
        
        @ViewBuilder
        func label(with spacing: CGFloat) -> some View {
            ForEach(TreeRectangle.granularities) { (granularity: String) in
                "\(granularity)-\(spacing)"
            } content: { (granularity: String) in
                label(with: granularity, spacing: spacing)
            }
            .padding(8)
        }
    }
}

extension CaseByDistrictTree {
    struct PlotConfiguration: Equatable {
        enum RegionDivision: CaseIterable, Comparable {
            case area
            case district
            case subDistrict
            
            var name: String {
                switch self {
                case .area:
                    "Area"
                case .district:
                    "District"
                case .subDistrict:
                    "Sub District"
                }
            }
            
            var systemName: String {
                switch self {
                case .area:
                    "map.fill"
                case .district:
                    "house.lodge.fill"
                case .subDistrict:
                    "house.fill"
                }
            }
            
            var font: Font {
                switch self {
                case .area:
                        .title2
                case .district:
                        .body
                case .subDistrict:
                        .caption
                }
            }
            
            func zoomIn() -> RegionDivision {
                switch self {
                case .area:
                        .district
                case .district:
                        .subDistrict
                case .subDistrict:
                        .subDistrict
                }
            }
            
            func zoomOut() -> RegionDivision {
                switch self {
                case .area:
                        .area
                case .district:
                        .area
                case .subDistrict:
                        .district
                }
            }
            
            func indexKey(entry: Entry) -> String {
                switch self {
                case .area:
                    ""
                case .district:
                    entry.area
                case .subDistrict:
                    entry.district
                }
            }
            
            static func >(lhs: Division, rhs: Division) -> Bool {
                switch lhs {
                case .area:
                    switch rhs {
                    case .area: return false
                    case .district, .subDistrict: return true
                    }
                case .district:
                    switch rhs {
                    case .area, .district: return false
                    case .subDistrict: return true
                    }
                case .subDistrict:
                    return false
                }
            }
            
            static func <(lhs: Division, rhs: Division) -> Bool {
                switch rhs {
                case .area:
                    switch lhs {
                    case .area: return false
                    case .district, .subDistrict: return true
                    }
                case .district:
                    switch lhs {
                    case .area, .district: return false
                    case .subDistrict: return true
                    }
                case .subDistrict:
                    return false
                }
            }
            
            static func <=(lhs: Division, rhs: Division) -> Bool {
                switch rhs {
                case .area:
                    return true
                case .district:
                    switch lhs {
                    case .area: return false
                    case .district, .subDistrict: return true
                    }
                case .subDistrict:
                    switch lhs {
                    case .area, .district: return false
                    case .subDistrict: return true
                    }
                }
            }
        }
        enum SortingOption: String, CaseIterable {
            case rate = "Rate"
            case income = "Income"
            case count = "Count"
        }
        enum DistrictDisplayOption: String, CaseIterable {
            case rate = "Rate"
            case count = "Count"
        }
        var isSortDescendingly: Bool = true
        var showPercentage: Bool = false
        var division: RegionDivision = .area
        var showMapView: Bool = false
        var sortingOption: SortingOption = .income
        var districtDisplayOption: DistrictDisplayOption = .count
    }
}

extension CaseByDistrictTree {
    fileprivate struct PopOverView: View {
        @Binding var config: PlotConfiguration
        let namespace: Namespace.ID
        
        private static let width: CGFloat = 400
        private var height: CGFloat { config.division == .district ? 550 : 400 }
        
        var body: some View {
            List {
                Section(header: Text("Tree Granularity")) {
                    HStack(spacing: 16) {
                        ForEach(Division.allCases, id: \.self) { (d: Division) in
                            let isActive: Bool = config.division == d
                            Button {
                                config.division = d
                            } label: {
                                VStack(alignment: .center, spacing: 0) {
                                    Image(systemName: d.systemName)
                                        .frame(height: 90-8)
                                        .frame(maxWidth: .infinity)
                                    Text(d.name)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(height: 60-8)
                                }
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .padding()
                            .frame(height: 150)
                            .hoverEffect()
                            .background {
                                if isActive {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.systemGroupedBackground)
                                        .matchedGeometryEffect(id: "selected", in: namespace)
                                }
                            }
                            .hoverEffect()
                            .animation(.spring, value: config.division)
                        }
                    }
                }
                
                Section(
                    footer: Text(config.division == .district ? "Suicide Rate = suicide count divided by the population and multiplied by 100,000." : "")
                ) {
                    Toggle("Sort Descendingly", isOn: $config.isSortDescendingly)
                    if config.division != .district {
                        Toggle("Show Percentage", isOn: $config.showPercentage)
                    }
                    if config.division == .district {
                        Toggle("Show Map View", isOn: $config.showMapView)
                        HStack {
                            Text("Show Suicide")
                            Spacer()
                            Picker(selection: $config.districtDisplayOption) {
                                ForEach(PlotConfiguration.DistrictDisplayOption.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        HStack {
                            Text("Sort By")
                            Spacer()
                            Picker(selection: $config.sortingOption) {
                                ForEach(PlotConfiguration.SortingOption.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
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
            .cornerRadius(20, style: .continuous)
//            .frame(height: height)
            .animation(.smooth) {
                $0.frame(height: height)
            }
        }
    }
}

extension CaseByDistrictTree {
    struct Entry: Identifiable, Hashable, Equatable, Codable {
        struct Key: Hashable, Codable {
            var area: String
            var district: String
            var subDistrict: String
        }
        var id: Key { key }
        var key: Key
        var count: Int
        
        var percentage: Double = 0
        var red: Double = 0
        var green: Double = 0
        var blue: Double = 0
        
        var color: Color {
            Color(red: self.red, green: self.green, blue: self.blue)
        }
        
        var area: String {
            self.key.area
        }
        
        var district: String {
            self.key.district
        }
        
        var subDistrict: String {
            self.key.subDistrict
        }
        
        init() {
            self.key = Key(
                area: "",
                district: "",
                subDistrict: ""
            )
            self.count = 0
        }
        
        init(key: Key, count: Int) {
            self.key = key
            self.count = count
        }
        
        init(area: String, district: String, subDistrict: String, count: Int) {
            self.key = Key(
                area: area,
                district: district,
                subDistrict: subDistrict
            )
            self.count = count
        }
        
        init(key: Key, count: Int, percentage: Double, red: Double, green: Double, blue: Double) {
            self.key = key
            self.count = count
            self.percentage = percentage
            self.red = red
            self.green = green
            self.blue = blue
        }
        
        init(copee: Entry, max: Int, sum: Int, granularity: Division) {
            self.init(key: copee.key, count: copee.count)
            self.normalise(max: max, sum: sum, granularity: granularity)
        }
        
        mutating func normalise(max: Int, sum: Int, granularity: Division) {
            let ratio: Double = Double(count)/Double(max)
            self.percentage = Double(count)/Double(sum)*100
            switch granularity {
            case .area:
                self.red = 1
                self.green = ratio
                self.blue = 0
            case .district:
                self.red = 0
                self.green = 1
                self.blue = ratio
            case .subDistrict:
                self.red = ratio
                self.green = 0
                self.blue = 1
            }
        }
        
        mutating func setColor(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
}
