//
//  SankeyUtil.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 23/3/2024.
//

import Sankey

struct SankeyNodePair: Hashable {
    let source: SankeyNode
    let target: SankeyNode
}

//extension SankeyLink: Hashable {
//    public static func == (lhs: SankeyLink, rhs: SankeyLink) -> Bool {
//        lhs.hashValue == rhs.hashValue
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.source)
//        hasher.combine(self.target)
//    }
//}
