//
//  SuicideBubble.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 23/3/2024.
//

import SwiftUI
import SwiftyJSON

struct SuicideBubble: View {
    typealias DataPoint = PackedBubbleChart.DataPoint
    
    @State private var _bubbleData: [Int : [String: CGFloat]] = [:]
    
    @State var intervalBubbleData: [DataPoint] = []
    
    let startYear: CGFloat
    let endYear: CGFloat
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suicide Forms")
                .foregroundStyle(.primary)
                .font(.title2)
                .fontWeight(.bold)
                .padding([.top, .leading], 8)
            Text("Some forms of suicide were more common than the others")
                .foregroundStyle(.secondary)
                .font(.body)
                .fontWeight(.regular)
                .lineLimit(nil)
                .padding([.horizontal, .bottom], 8)
            if !intervalBubbleData.isEmpty {
                PackedBubbleChart(
                    data: $intervalBubbleData,
                    spacing: 32,
                    startAngle: 180,
                    clockwise: true
                )
                .onRotate { (o: UIDeviceOrientation) in
                    /// A trick to update the size of Bubble Plot
                    updateIntervalBubbleData()
                }
                .animation(.spring, value: intervalBubbleData)
            }
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
//            loadSuicidecatData()
            updateIntervalBubbleData()
        }
        .onChange(of: startYear) { _, _ in
            updateIntervalBubbleData()
        }
        .onChange(of: endYear) { _, _ in
            updateIntervalBubbleData()
        }
    }
    
    
//    func loadSuicidecatData() {
//        let formatter = NumberFormatter()
//        let keys: ClosedRange<Int> = START_YEAR...END_YEAR
//        let values: [[String: CGFloat]] = Array(repeating: [:], count: keys.count)
//        var localData: [Int : [String: CGFloat]] = Dictionary(uniqueKeysWithValues: zip(keys, values))
//        if let json: JSON = parseJSON(for: "suicidecat"),
//           let dict: [String : JSON] = json["count"].dictionary {
//            for (key, value) in dict {
//                let formatted: String = key
//                    .replacingOccurrences(of: "'", with: "")
//                    .replacingOccurrences(of: "(", with: "")
//                    .replacingOccurrences(of: ")", with: "")
//                let number: NSNumber = formatter.number(from: String(formatted.split(separator: ", ")[0])) ?? DEFAULT_START_YEAR
//                let year: Int = Int(truncating: number)
//                let suicidecat: String = String(formatted.split(separator: ", ")[1])
//                localData[year]?[suicidecat] = CGFloat(value.intValue) + BUBBLE_SIZE_BASE
//            }
//        } else {
//            print("fail to parse suicidecat.json")
//        }
//        self._bubbleData = localData
//    }
    
    func updateIntervalBubbleData() {
        let range: [Int] = Array(Int(startYear)...Int(endYear))
        let datass: [[String: CGFloat]] = range.map({ _bubbleData[$0] ?? [:] })
        let datas: [String: CGFloat] = datass.reduce([:]) { (partialResult: [String: CGFloat], next: [String: CGFloat]) in
            partialResult.merging(next) { (old: CGFloat, new: CGFloat) in
                old + new
            }
        }
        var points: [DataPoint] = datas.map({ DataPoint(title: $0.key, value: $0.value )})
        let max: CGFloat = points.max(by: { $0.value < $1.value })?.value ?? 0
        if let largestElementIdx: Int = points.firstIndex(where: { $0.value == max }) {
            points.swapAt(largestElementIdx, 0)
        }
        intervalBubbleData = points
    }
}

