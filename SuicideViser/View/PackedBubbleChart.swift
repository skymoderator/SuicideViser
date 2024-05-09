//
//  PackedBubbleChart.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 21/3/2024.
//

import SwiftUI

extension PackedBubbleChart {
    struct DataPoint: Identifiable, Equatable {
        var id = UUID()
        var title: String
        var value: CGFloat
        var color: Color = .random
        var offset = CGSize.zero
        var opacity = 1.0
    }
}

struct PackedBubbleChart: View {
    
    @Binding var data: [DataPoint]
    // space between bubbles
    var spacing: CGFloat
    // Angle in degrees -360 to 360
    var startAngle: Int
    var clockwise: Bool
    
    struct BubbleSize {
        var xMin: CGFloat = 0
        var xMax: CGFloat = 0
        var yMin: CGFloat = 0
        var yMax: CGFloat = 0
    }
    
    @State var bubbleSize = BubbleSize()
    
    var body: some View {
        
        let xSize = (bubbleSize.xMax - bubbleSize.xMin) == 0 ? 1 : (bubbleSize.xMax - bubbleSize.xMin)
        let ySize = (bubbleSize.yMax - bubbleSize.yMin) == 0 ? 1 : (bubbleSize.yMax - bubbleSize.yMin)
        
        GeometryReader { geo in
            
            let width = geo.size.width
            let height = geo.size.height
            let xScale = width / xSize
            let yScale = height / ySize
            let scale = min(xScale, yScale)
            
            ZStack(alignment: .center) {
                ForEach(data, id: \.id) { item in
                    bubble(item: item, scale: scale)
                        .offset(x: item.offset.width * scale, y: item.offset.height * scale)
                }
            }
            .frame(width: width, height: height)
            .offset(x: xOffset() * scale, y: yOffset() * scale)
//            .offset(
//                x: (width - (bubbleSize.xMax - bubbleSize.xMin) * scale)/2,
//                y: (height - (bubbleSize.yMax - bubbleSize.yMin) * scale)/2
//            )
            .border(.red)
//            .overlay(alignment: .bottomTrailing) {
//                Text("xMin: \(Int(bubbleSize.xMin)), xMax: \(Int(bubbleSize.xMax)), yMin: \(Int(bubbleSize.yMin)), yMax: \(Int(bubbleSize.yMax))")
//                    .font(.caption)
//            }
        }
        .onAppear {
            setOffets()
            bubbleSize = absoluteSize(data: data)
        }
        .onChange(of: data) { (_, newValue: [DataPoint]) in
            setOffets()
            bubbleSize = absoluteSize(data: newValue)
        }
    }
    
    func bubble(item: DataPoint, scale: CGFloat) -> some View {
        ZStack {
            let size = CGFloat(item.value) * scale
            Circle()
                .frame(
                    width: CGFloat(item.value) * scale,
                    height: CGFloat(item.value) * scale
                )
                .foregroundStyle(item.color.gradient)
                .opacity(item.opacity)
                .overlay {
                    if size >= 30 {
                        VStack {
                            Text(item.title)
                                .bold()
                            Text((item.value - BUBBLE_SIZE_BASE).formatted())
                        }
                    }
                }
        }
    }
    
    // X-Axis offset
    func xOffset() -> CGFloat {
        if data.isEmpty { return 0.0 }
        let size = data.max{$0.value < $1.value}?.value ?? data[0].value
        let xOffset = bubbleSize.xMin + size / 2
        return -xOffset
    }
    
    // Y-Axis offset
    func yOffset() -> CGFloat {
        if data.isEmpty { return 0.0 }
        let size = data.max{$0.value < $1.value}?.value ?? data[0].value
        let yOffset = bubbleSize.yMin + size / 2
        return -yOffset
    }
    
    
    // calculate and set the offsets
    func setOffets() {
        if data.isEmpty { return }
        // first circle
        data[0].offset = CGSize.zero
        
        if data.count < 2 { return }
        // second circle
        let b = (data[0].value + data[1].value) / 2 + spacing
        
        // start Angle
        var alpha: CGFloat = CGFloat(startAngle) / 180 * CGFloat.pi
        
        data[1].offset = CGSize(width:  cos(alpha) * b,
                                height: sin(alpha) * b)
        
        // other circles
        for i in 2..<data.count {
            
            // sides of the triangle from circle center points
            let c = (data[0].value + data[i-1].value) / 2 + spacing
            let b = (data[0].value + data[i].value) / 2 + spacing
            let a = (data[i-1].value + data[i].value) / 2 + spacing
            
            alpha += calculateAlpha(a, b, c) * (clockwise ? 1 : -1)
            
            let x = cos(alpha) * b
            let y = sin(alpha) * b
            
            data[i].offset = CGSize(width: x, height: y )
        }
    }
    
    // Calculate alpha from sides - 1. Cosine theorem
    func calculateAlpha(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat) -> CGFloat {
        return acos(
            ( pow(a, 2) - pow(b, 2) - pow(c, 2) )
            /
            ( -2 * b * c ) )
        
    }
    
    // calculate max dimensions of offset view
    func absoluteSize(data: [DataPoint]) -> BubbleSize {
        let radius = data[0].value / 2
        let initialSize = BubbleSize(xMin: -radius, xMax: radius, yMin: -radius, yMax: radius)
        
        let maxSize = data.reduce(initialSize, { partialResult, item in
            let xMin = min(
                partialResult.xMin,
                item.offset.width - item.value / 2 - spacing
            )
            let xMax = max(
                partialResult.xMax,
                item.offset.width + item.value / 2 + spacing
            )
            let yMin = min(
                partialResult.yMin,
                item.offset.height - item.value / 2 - spacing
            )
            let yMax = max(
                partialResult.yMax,
                item.offset.height + item.value / 2 + spacing
            )
            return BubbleSize(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)
        })
        return maxSize
    }
    
}
