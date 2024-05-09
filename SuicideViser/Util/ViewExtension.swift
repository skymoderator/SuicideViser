//
//  ViewExtension.swift
//  MCKing
//
//  Created by Choi Wai Lap on 5/2/2024.
//

import SwiftUI

extension View {
    @ViewBuilder
    func offset<PK: PreferenceKey>(
        preferenceKey: PK.Type = PK.self,
        coordinateSpace: AnyHashable,
        completion: @escaping (CGRect) -> ()
    ) -> some View where PK.Value == CGRect {
        self
            .overlay {
                GeometryReader {
                    let rect = $0.frame(in: .named(coordinateSpace))
                    
                    Color.clear
                        .preference(key: PK.self, value: rect)
                        .onPreferenceChange(PK.self, perform: completion)
                }
            }
    }
}
