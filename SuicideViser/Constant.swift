//
//  Constant.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 21/3/2024.
//

import Foundation
import SwiftUI
import CoreLocation

let START_YEAR: Int = 2019
let END_YEAR: Int = 2024
let DEFAULT_START_YEAR: Int = 2019
let DEFAULT_END_YEAR: Int = 2024
let BUBBLE_SIZE_BASE: CGFloat = 0
let DISTRICTS: [String] = 
"中西區 東區 灣仔區 南區 黃大仙區 深水埗區 九龍城區 觀塘區 油尖旺區 北區 元朗區 大埔區 屯門區 荃灣區 沙田區 葵青區 西貢區 離島區"
    .split(separator: " ").map(String.init)
let DISTRICT2AREA: [String: String] = [
    "中西區": "港島",
    "東區": "港島",
    "灣仔區": "港島",
    "南區": "港島",
    "黃大仙區": "九龍",
    "深水埗區": "九龍",
    "九龍城區": "九龍",
    "觀塘區": "九龍",
    "油尖旺區": "九龍",
    "北區": "新界",
    "元朗區": "新界",
    "大埔區": "新界",
    "屯門區": "新界",
    "荃灣區": "新界",
    "沙田區": "新界",
    "葵青區": "新界",
    "西貢區": "新界",
    "離島區": "新界"
]
let AREA2DISTRICTS: [String: [String]] = [
    "港島": "中西區 東區 灣仔區 南區".split(separator: " ").map(String.init),
    "九龍": "黃大仙區 深水埗區 九龍城區 觀塘區 油尖旺區".split(separator: " ").map(String.init),
    "新界": "北區 元朗區 大埔區 屯門區 荃灣區 沙田區 葵青區 西貢區 離島區".split(separator: " ").map(String.init),
]
let WEEK_OF_DAYS: [String] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
let CATEGORIES: [String] = ["不詳", "交通", "出血", "槍械", "氣體", "液體", "淹溺", "燒炭", "窒息", "自焚", "自縊", "藥品", "跳落"]
let STATUS: [String] = "不詳 昏迷 清醒 紊亂 身亡 迷糊".split(separator: " ").map(String.init)
let REASONS: [String] = ["家庭", "健康", "財政", "不詳", "工作", "學業", "感情", "生活", "畏罪", "酒精", "藥品", "要脅"]
let COORDINATES: [(Double, Double)] = [
    (22.28219, 114.14486),
    (22.27722, 114.22519),
    (22.27702, 114.17232),
    (22.25801, 114.15308),
    (22.34299, 114.19302),
    (22.32989, 114.1625),
    (22.32866, 114.19121),
    (22.31326, 114.22581),
    (22.32105, 114.17261),
    (22.49471, 114.13812),
    (22.41667, 114.05),
    (22.43995, 114.1654),
    (22.39161, 113.96792),
    (22.37908, 114.10598),
    (22.38715, 114.19534),
    (22.35288, 114.10004),
    (22.38198, 114.27017),
    (22.26382, 113.96038)
]
let AGE_GROUPS: [String] = ["0-20", "21-40", "41-60", "61-80", "81-100+", "不詳"]
let AGE_GROUP2COLOR: [String: Color] = [
    "0-20": Color(red: 1, green: 0, blue: 0),
    "21-40": Color(red: 0.8, green: 0, blue: 0),
    "41-60": Color(red: 0.6, green: 0, blue: 0),
    "61-80": Color(red: 0.4, green: 0, blue: 0),
    "81-100+": Color(red: 0.2, green: 0, blue: 0),
    "不詳": Color.darkGray
]
//let AGE_GROUP2COLOR: [String: Color] = Dictionary(
//    zip(AGE_GROUPS, stride(from: 0, to: 1, by: 1/Double(AGE_GROUPS.count)).map({ Color(hue: $0, saturation: 1, brightness: 1) })),
//    uniquingKeysWith: { _, _ in Color.clear }
//)
let HOUSE_TYPES: [String] = ["公共屋邨", "唐樓", "居屋", "洋樓", "私人屋苑", "豪宅", "非住宅", "服務式住宅", "村屋"]
let TIMES: [Int] = Array(0...23)
let GENDERS: [String] = ["男", "女"]
let AREAS: [String] = ["港島", "九龍", "新界"]
