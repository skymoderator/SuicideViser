//
//  IdentifyEquateCodeHashable.swift
//  FoodAssistant
//
//  Created by Choi Wai Lap on 12/1/2023.
//

import Foundation

protocol IdentifyEquateCodeHashable: Identifiable, Equatable, Codable, Hashable {
    var id: ID { get }
    static func == (lhs: Self, rhs: Self) -> Bool
}

extension IdentifyEquateCodeHashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
