//
//  CaseByTimeSpiral.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 23/3/2024.
//

import SwiftUI
import SwiftyJSON
import Spiral
import SwiftDate

struct CaseByMonthSpiral: View {
    @State private var _allDatas: [Int: [HeatMapEntry]] = [:]
    
    @State var displayData: [HeatMapEntry] = []
    
    let startYear: CGFloat
    let endYear: CGFloat
    
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
            if !displayData.isEmpty {
                ZStack {
                    let smoothness: CGFloat = 75
                    let numRectPerRound: Double = smoothness*2
                    SpiralView(
                        startAt: .zero,
                        endAt: .degrees(Int(endYear - startYear + 1)*360),
                        smoothness: smoothness,
                        offsetRadius: .zero,
                        offsetAngle: .zero
                    ) { (index: Int, spiralPoint: SpiralPoint) in
                        let max = Double(endYear - startYear + 1)*numRectPerRound
                        let count = Double(displayData.count)
                        let i = Int(ceil(Double(index + 1)/max*count))
                        let data: HeatMapEntry = displayData[i-1]
                        Rectangle()
                            .fill(data.color)
                            .frame(width: CGFloat(10*((END_YEAR - START_YEAR + 1) - Int(endYear - startYear))), height: 10)
                            .rotationEffect(Angle(radians: spiralPoint.angle.degrees/Double(360)*Double.pi*Double(2)), anchor: .center)
                            .position(x: spiralPoint.point.x, y: spiralPoint.point.y)
                    }
                    Spiral(
                        startAt: .zero,
                        endAt: .degrees(Int(endYear - startYear + 1)*360),
                        offsetRadius: 5 + 5*(CGFloat(END_YEAR - START_YEAR) - (endYear - startYear))
                    )
                    .stroke(style: .init(lineWidth: 2, dash: [1, 5]))
                    Spiral(
                        pathType: .rect(width: 0.5, height: 10),
                        startAt: .zero,
                        endAt: .degrees(Int(endYear - startYear + 1)*360),
                        smoothness: 6,
                        offsetRadius: 5 + 5*(CGFloat(END_YEAR - START_YEAR) - (endYear - startYear))
                    )
                    .fill()
                    SpiralView(
                        startAt: .zero,
                        endAt: .degrees(Int(endYear - startYear + 1)*360),
                        smoothness: 6,
                        offsetRadius: 6 + 6*(CGFloat(END_YEAR - START_YEAR) - (endYear - startYear)),
                        offsetAngle: .degrees(14)
                    ) { (index: Int, spiralPoint: SpiralPoint) in
                        if 12*Int(endYear - startYear + 1)-index <= 12 {
                            let dateStr: String = "2019-\(String(format: "%02d", (index%12)+1))-01"
                            let date: DateInRegion = dateStr.toDate("yyyy-MM-dd")!
                            let monStr: String = date.toFormat("LLLL", locale: nil)
                            Text(monStr.prefix(3))
                                .position(x: spiralPoint.point.x, y: spiralPoint.point.y)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .task(id: startYear + endYear) {
            await loadData()
            await updateIntervalData()
        }
        .animation(.spring, value: displayData)
        .animation(.spring, value: startYear)
        .animation(.spring, value: endYear)
    }
    
    func loadData() async {
        guard _allDatas.isEmpty else { return }
        guard let json: JSON = parseJSON(for: "caseByMonth"),
              let dict: [String : JSON] = json["value"].dictionary
        else {
            print("fail to parse caseByMonth.json")
            return
        }
        
        let formatter = NumberFormatter()
        var allDatas: [Int: [HeatMapEntry]] = [:]
        for (key, value) in dict {
            let formatted: String = key
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            let yearString = String(formatted.split(separator: ", ")[0])
            let monthString = String(formatted.split(separator: ", ")[1])
            let year = Int(truncating: formatter.number(from: yearString) ?? Int(DEFAULT_START_YEAR) as NSNumber)
            let month = Int(truncating: formatter.number(from: monthString) ?? 1)
            let entry = HeatMapEntry(year: year, month: month, value: value.intValue)
            if allDatas[year] == nil {
                allDatas[year] = [entry]
            } else {
                allDatas[year]!.append(entry)
            }
        }
        _allDatas = allDatas
    }
    
    func updateIntervalData() async {
        guard !_allDatas.isEmpty else { return }
        let range: [Int] = Array(Int(startYear)...Int(endYear))
        var matched: [HeatMapEntry] = range.flatMap({ _allDatas[$0]! })
        let maxValue: Int = matched.map(\.value).max() ?? 0
        let minValue: Int = matched.map(\.value).min() ?? 0
        for i in matched.indices {
            matched[i].normalise(min: minValue, max: maxValue)
        }
        displayData = matched
    }
}

extension CaseByMonthSpiral {
    struct HeatMapEntry: IdentifyEquateCodeHashable {
        var id = UUID()
        var year: Int
        var month: Int
        var value: Int
        
        private var red: Double = 0
        private var green: Double = 0
        private var blue: Double = 0
        
        var color: Color {
            Color(red: red, green: green, blue: blue)
        }
        
        init(year: Int, month: Int, value: Int) {
            self.year = year
            self.month = month
            self.value = value
        }
        
        mutating func normalise(min: Int, max: Int) {
            let code: Double = Double(value - min) / Double(max - min)
//            self.red = code
            self.green = code
            self.blue = code
        }
    }
}
