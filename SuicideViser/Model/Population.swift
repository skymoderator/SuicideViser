//
//  Population.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 29/4/2024.
//

import Foundation

struct Population: Identifiable, Hashable, Equatable {
    let id = UUID()
    
    let year: Int
    let district: String
    let value: Int
    
    init(year: Int, district: String, value: Int) {
        self.year = year
        self.district = district
        self.value = value
    }
    
    init(text: String) {
        let columns = text.components(separatedBy: ",")
        self.year = Int(columns[0]) ?? 0
        self.district = columns[1]
        self.value = Int(Double(columns[2].replacingOccurrences(of: "\r", with: "")) ?? 0 )
    }
    
    var area: String {
        DISTRICT2AREA[district]!
    }
    
    static let districtPopulations: [Population] = parseCSV(for: "population").map({ Population(text: $0) })
}

