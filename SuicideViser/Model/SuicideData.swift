//
//  SuicideData.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 15/4/2024.
//

import Foundation
import SwiftyJSON

struct SuicideData: Hashable {
    let time: Int
    let year: Int
    let month: Int
    let ageGroup: String
    let gender: String
    let houseType: String
    let area: String
    let district: String
    let subDistrict: String
    let status: String
    let reason: String
    let category: String
    let weekOfDay: String

    init(json: JSON) {
        self.time = json["Time"].intValue
        self.year = json["Year"].intValue
        self.month = json["Month"].intValue
        self.ageGroup = json["AgeGroup"].stringValue
        self.gender = json["Gender"].stringValue
        self.houseType = json["HouseType"].stringValue
        self.area = json["Area"].stringValue
        self.district = json["District"].stringValue
        self.subDistrict = json["SubDistrict"].stringValue
        self.status = json["Status"].stringValue
        self.reason = json["Reason"].stringValue
        self.category = json["Category"].stringValue
        self.weekOfDay = json["WeekOfDay"].stringValue
    }

    static func fetchData() async -> [SuicideData] {
        guard let json: JSON = parseJSON(for: "suicide"),
              let array: [JSON] = json.array
        else {
            print("fail to parse suicide.json")
            return []
        }
        return array.map({ SuicideData(json: $0) })
    }
}

struct AggregatedSuicideData {
    let data: SuicideData
    let value: Int

    init(data: SuicideData, value: Int = 0) {
        self.data = data
        self.value = value
    }
}
