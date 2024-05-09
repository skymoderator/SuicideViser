//
//  FirstRow.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 21/3/2024.
//

import SwiftyJSON
import SwiftUI
import SwiftUIX

struct CaseByAgeGroupTree: View {
    @State private var _allDatas: [Int: [Entry]] = [:]
    
    @State var displayData: [Entry] = []
    @State var displayVector = AnimatableVector(values: [])
    
    let startYear: CGFloat
    let endYear: CGFloat
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide Age Group")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("Suicide happens on everyone")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            if !displayData.isEmpty {
                TreeLayout(vector: displayVector) {
                    ForEach(displayData, id: \.self) { (entry: Entry) in
                        Rectangle()
                            .fill(entry.color.gradient)
                            .overlay {
                                Text(verbatim: "\(Int(entry.count))")
                                    .bold()
                                    .font(.title2)
                                    .foregroundStyle(.black)
                            }
                            .overlay(alignment: .topLeading) {
                                Text(entry.ageGroup)
                                    .font(.caption)
                                    .foregroundStyle(Color.black)
                                    .padding([.top, .leading], 8)
                            }
                        //.layoutValue(key: TreeLayout.TreeValue.self, value: value)
                    }
                }
                .frame(minWidth: 100, minHeight: 100)
            }
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .task {
            await loadData()
            await updateIntervalData()
        }
        .task(id: startYear) {
            await updateIntervalData()
        }
        .task(id: endYear) {
            await updateIntervalData()
        }
        .animation(.spring, value: displayData)
        .animation(.spring, value: startYear)
        .animation(.spring, value: endYear)
    }

    func loadData() async {
        guard let json: JSON = parseJSON(for: "caseByAgeGroup"),
              let dict: [String : JSON] = json["value"].dictionary
        else {
            print("fail to parse caseByAgeGroup.json")
            return
        }
        
        let formatter = NumberFormatter()
        var allDatas: [Int: [Entry]] = [:]
        for (key, value) in dict {
            let formatted: String = key
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            let yearString = String(formatted.split(separator: ", ")[0])
            let ageGroupString = String(formatted.split(separator: ", ")[1])
            let year = Int(truncating: formatter.number(from: yearString) ?? Int(DEFAULT_START_YEAR) as NSNumber)
            let entry = Entry(year: year, ageGroup: ageGroupString, count: value.doubleValue)
            if allDatas[year] == nil {
                allDatas[year] = [entry]
            } else {
                allDatas[year]!.append(entry)
            }
        }
        self._allDatas = allDatas
    }
    
    func updateIntervalData() async {
        let range: [Int] = Array(Int(startYear)...Int(endYear))
        var matched: [Entry] = range.flatMap({ _allDatas[$0]! })
        var matchedGroupedByAge: [String: Entry] = [:]
        
        for match in matched {
            if matchedGroupedByAge[match.ageGroup] == nil {
                matchedGroupedByAge[match.ageGroup] = match
            } else {
                matchedGroupedByAge[match.ageGroup]!.count += match.count
            }
        }
        
        matched = matchedGroupedByAge.values.filter({ $0.count > 10 }).sorted(using: KeyPathComparator(\.count, order: .reverse))
        
        let counts: [Double] = matched.map(\.count)
        let max: Double = counts.max() ?? 0
        for i in matched.indices {
            matched[i].normalise(max: max)
        }
        displayData = matched
        displayVector = AnimatableVector(values: counts)
    }
}

extension CaseByAgeGroupTree {
    struct Entry: IdentifyEquateCodeHashable {
        var id = UUID()
        let year: Int
        var ageGroup: String
        var count: Double
        var red: Double = 0
        var green: Double = 0
        var blue: Double = 0
        
        var color: Color {
            Color(red: self.red, green: self.green, blue: self.blue)
        }
        
        init(year: Int, ageGroup: String, count: Double) {
            self.year = year
            self.ageGroup = ageGroup
            self.count = count
        }
        
        mutating func normalise(max: Double) {
            let ratio: Double = count/max
            self.red = 0
            self.green = ratio
            self.blue = 1
        }
    }
}
