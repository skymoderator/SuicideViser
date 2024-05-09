//
//  DistrictIncome.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 28/4/2024.
//

import Foundation

struct DistrictIncome: Identifiable, Hashable, Equatable {
    let id = UUID()
    
    let year: Int
    let district: String
    let income: Int
    
    init(year: Int, district: String, income: Int) {
        self.year = year
        self.district = district
        self.income = income
    }
    
    init(text: String) {
        let columns = text.components(separatedBy: ",")
        self.year = Int(columns[0]) ?? 0
        self.district = columns[1]
        self.income = Int(columns[3]) ?? 0
    }
    
    var area: String {
        DISTRICT2AREA[district]!
    }
    
    static let districtIncomes: [DistrictIncome] = parseCSV(for: "income").map({ DistrictIncome(text: $0) })
}
