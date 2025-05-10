//
//  TabbedView.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 3/2/2025.
//

import SwiftUIIntrospect
import SwiftUI
import Polygon

struct TabbedView: View {

    var body: some View {
        TabView() {
            Tab("Lessons", systemImage: "text.book.closed.fill") {
                ScrollView {
                    LessonsPage()
                }
                .modifier(CoolBackgroundModifier())
                .scrollContentBackground(.hidden)
                .frame(minHeight: 0, maxHeight: .infinity)
            }
            Tab("Curriculum", systemImage: "books.vertical") {
                CurriculumPage().modifier(CoolBackgroundModifier())
            }
            Tab("Friends", systemImage: "person.2.fill") {
                FriendsPage().modifier(CoolBackgroundModifier())
            }
            Tab("Settings", systemImage: "gear") {
                SettingsPage()
            }
        }
        
    }
}
