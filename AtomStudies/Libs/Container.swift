//
//  Container.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 8/2/2025.
//

import SwiftUI

struct Container<Content>: View where Content: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
    }
}
