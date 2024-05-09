//
//  ListUtil.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 15/4/2024.
//

import Foundation

extension Array where Self.Element: Equatable {
    mutating func toggle(element: Self.Element) {
        if let index = self.firstIndex(of: element) {
            self.remove(at: index)
        } else {
            self.append(element)
        }
    }
}
