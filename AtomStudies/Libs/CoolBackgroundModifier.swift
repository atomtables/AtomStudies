//
//  CoolBackgroundModifier.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 5/2/2025.
//

import Polygon
import SwiftUI

struct CoolBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    let blurRadius: CGFloat;

    init() { blurRadius = 5; }
    init(blurRadius: CGFloat) { self.blurRadius = blurRadius; }

    func body(content: Content) -> some View {
        content.frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity
        )
        .background {
            TiledPolygon()
                .kind(Hexagon())
                .interTileSpacing(2) // space between adjacent tiles
                .fillColorPattern(colorScheme == .dark ? [Color.init(hex: "06420B")]: [Color.init(hex: "14db24")]) //apply multi color
                .polygonSize(TileablePolygonSize(fixedWidth: 64)) //size of each tile
                .blur(radius: blurRadius)
                .ignoresSafeArea()
                .background(.background)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity
                )
        }
    }
}
