//
//  AtomStudiesApp.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 2/12/2024.
//

import SwiftUI
import Polygon

@main
struct AtomStudiesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let viewModel = FirebaseViewData.main;

    @State var renderBackground = false;
    @State var renderedBackground = false;

    var body: some Scene {
        WindowGroup {
            VStack {
                if FirebaseViewData.main.loggedIn {
                    if FirebaseViewData.main.isLessonShown {
                        LessonScreen()
                            .transition(
                                .slide.animation(.easeInOut(duration: 2))
                            )
                            .modifier(CoolBackgroundModifier())
                    } else {
                        TabbedView()
                            .transition(
                                .slide.animation(.easeInOut(duration: 2))
                            )
                    }
                } else {
                    ContentView(
                        renderedBackground: $renderedBackground,
                        renderBackground: $renderBackground
                    )
                }
            }
            .background {
                TiledPolygon()
                    .kind(Hexagon())
                    .interTileSpacing(2) // space between adjacent tiles
                    .fillColorPattern([Color.green]) //apply multi color
                    .polygonSize(TileablePolygonSize(fixedWidth: 64)) //size of each tile
                    .background(.background)
                    .frame(
                        width: renderBackground ? 1500 : 0,
                        height: renderBackground ? 1500 : 0
                    )
                    .animation(
                        .easeInOut(duration: 2),
                        value: renderBackground
                    )
                    .mask(
                        alignment: .center,
                        {
                            Circle()
                                .frame(
                                    width: renderBackground ? 1500 : 0,
                                    height: renderBackground ? 1500 : 0
                                )
                                .animation(
                                    .easeInOut(duration: 2),
                                    value: renderBackground
                                )
                        }
                    )
            }
            .onFirstAppear({
                renderBackground = true;
                DispatchQueue.main.asyncAfter(deadline:.now() + 2) {
                    renderedBackground = true;
                }
            })
        }
    }
}
