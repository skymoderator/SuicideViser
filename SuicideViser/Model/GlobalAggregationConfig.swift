//
//  GlobalAggregation.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 14/4/2024.
//

import Foundation

struct GlobalAggregationConfig: Equatable {
    var years: [Int]
    var months: [Int]
    var weekOfDays: [String]
    var areas: [String]
    var districts: [String]
    var ageGroups: [String]
    var houseTypes: [String]
    var genders: [String]
    var times: [Int]
    var statuses: [String]
    var reasons: [String]
    var categories: [String]

    public static let defaultValue = GlobalAggregationConfig(
        years: Array(DEFAULT_START_YEAR...DEFAULT_END_YEAR),
        months: Array(1...12),
        weekOfDays: WEEK_OF_DAYS,
        areas: AREAS,
        districts: DISTRICTS,
        ageGroups: AGE_GROUPS,
        houseTypes: HOUSE_TYPES,
        genders: GENDERS,
        times: TIMES,
        statuses: STATUS,
        reasons: REASONS,
        categories: CATEGORIES
    )
    
    public static let emptyValue = GlobalAggregationConfig(
        years: [],
        months: [],
        weekOfDays: [],
        areas: [],
        districts: [],
        ageGroups: [],
        houseTypes: [],
        genders: [],
        times: [],
        statuses: [],
        reasons: [],
        categories: []
    )
}
