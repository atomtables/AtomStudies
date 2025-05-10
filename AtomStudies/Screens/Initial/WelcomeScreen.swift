//
//  WelcomeScreen.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 3/12/2024.
//

import SwiftUI

struct WelcomeScreen: View {
    @Binding var renderedBackground: Bool;
    @Binding var screen: Screen;

    var body: some View {
        VStack {
            if renderedBackground {
                VStack {
                    AppIcon()
                        .frame(width: 80, height: 80)
                    Text("AtomStudies")
                        .font(.largeTitle)
                    Text("Learn the basics of Chemistry from anywhere!")
                        .font(.subheadline)
                    HStack {
                        Image(systemName: "book.pages")
                            .foregroundStyle(.green)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("Structured Curriculum")
                                .bold()
                                .multilineTextAlignment(.leading)
                            Text("A curriculum specialised to teach the reigns of Chemistry.")
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()
                    HStack {
                        Image(systemName: "apps.iphone")
                            .foregroundStyle(.green)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("Combination of the best")
                                .bold()
                                .multilineTextAlignment(.leading)
                            Text("Combines the best aspects of other applications in its league")
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()
                    HStack {
                        Image(systemName: "graduationcap")
                            .foregroundStyle(.green)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("Designed for students")
                                .bold()
                                .multilineTextAlignment(.leading)
                            Text("Helps students study and stay ahead in topics like AP Chemistry.")
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()

                    HStack {
                        Button {
                            withAnimation {
                                screen = .Login
                            }
                        } label: {
                            Text("Log In")
                        }
                        .opacity(renderedBackground ? 1 : 0)
                        .animation(
                            .easeInOut(duration: 1).delay(5),
                            value: renderedBackground
                        )
                        .buttonStyle(BorderedProminentButtonStyle())

                        Button {
                            withAnimation {
                                screen = .Create
                            }
                        } label: {
                            Text("Create an account")
                        }
                        .opacity(renderedBackground ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(6), value: renderedBackground)
                        .buttonStyle(BorderedButtonStyle())
                    }
                }
                .padding(40)
            }
        }
    }
}
