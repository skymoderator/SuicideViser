//
//  SuicideSankey.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 23/3/2024.
//

import SwiftUI
import Sankey
import SwiftyJSON

struct SuicideSankey: View {
    let allDatas: [SankeyLink]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            SankeyDiagram(
                allDatas,
                nodePadding: 24,
                nodeLabelColor: colorScheme == .light ? "#000000" : "#ffffff",
                nodeLabelFontSize: 20,
                nodeInteractivity: true,
                linkColorMode: .gradient
            )
            HStack {
                Text("Category").foregroundStyle(.secondary)
                Spacer()
                Text("House Type").foregroundStyle(.secondary)
                Spacer()
                Text("District").foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading) {
                Text("Geometrical Factors")
                    .foregroundStyle(.primary)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding([.top, .leading], 8)
                Text("How does the location of the accident affect the forms of suicide?")
                    .foregroundStyle(.secondary)
                    .font(.body)
                    .fontWeight(.regular)
                    .lineLimit(nil)
                    .padding([.horizontal, .bottom], 8)
            }
        }
        .padding()
        .background(Color.tertiarySystemGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
    }
}
