//
//  TreeLayout.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 23/3/2024.
//

import Foundation
import SwiftUI

struct TreeLayout: Layout, Animatable {
    struct TreeValue: LayoutValueKey {
        static let defaultValue: Double = .zero
    }
    
    var vector: AnimatableVector
    var animatableData: AnimatableVector {
        get { vector }
        set { vector = newValue }
    }
    
    init(
        vector: AnimatableVector
    ) {
        self.vector = vector
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        let proposedWidth: CGFloat = proposal.width ?? 0
//        let proposedHeight: CGFloat = proposal.height ?? 0
//        let proposedBound: CGRect = CGRect(origin: .zero, size: .init(width: proposedWidth, height: proposedHeight))
//        let treeMap = YMTreeMap(withValues: vector.values)
//        let treeMapRects: [CGRect] = treeMap.tessellate(inRect: proposedBound)
//        let mergedRect: CGRect = treeMapRects.reduce(.zero) { (partialResult: CGRect, next: CGRect) in
//            partialResult.union(next)
//        }
//        return mergedRect.size
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        let treeMap = YMTreeMap(withValues: vector.values)
        let values: [Double] = subviews.map({ $0[TreeValue.self] })
        let treeMap = YMTreeMap(withValues: values)
        let treeMapRects: [CGRect] = treeMap.tessellate(inRect: bounds)
        
        for i in subviews.indices {
            guard treeMapRects[i].width.isNormal,
                  treeMapRects[i].height.isNormal
            else { continue }
            subviews[i].place(
                /// Note: the `treeMap.tessellate` function already handle the case where the origin of `bounds` is not zero,
                /// by passing the `bounds` as argument in the function, so the returned `treeMapRects` will be positions
                /// that relative to the whatever the origin of  `bounds` is, so there is no need to do the following:
                /// at: CGPoint(x: bounds.minX + treeMapRects[i].minX, y: bounds.minY + treeMapRects[i].minY)
                at: treeMapRects[i].origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(treeMapRects[i].size)
            )
        }
    }
}
