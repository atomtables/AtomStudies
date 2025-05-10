//
//  ContentView.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 2/12/2024.
//

import SwiftUI
import Polygon

enum Screen {
    case Welcome;
    case Login;
    case Create;
}

struct ContentView: View {
    @State var screen: Screen = .Welcome;

    @Binding var renderedBackground: Bool;
    @Binding var renderBackground: Bool;

    var body: some View {
        VStack {
            VStack {
                if FirebaseViewData.main.initialised {
                    if (FirebaseViewData.main.loggingIn || FirebaseViewData.main.loggedIn) {
                        AppIcon()
                            .frame(width: 80, height: 80)
                        Text("AtomStudies")
                            .font(.largeTitle)
                        Text("Learn the basics of Chemistry from anywhere!")
                            .font(.subheadline)
                        HStack{}.padding()
                        HStack {
                            ProgressView()
                            Text("Logging you in...")
                        }
                        .padding()
                    } else {
                        switch screen {
                        case .Welcome:
                            WelcomeScreen(renderedBackground: $renderedBackground, screen: $screen)
                        case .Login:
                            LoginScreen(screen: $screen)
                        case .Create:
                            SignupScreen(screen: $screen)
                        }
                    }
                } else {
                    AppIcon()
                        .frame(width: 80, height: 80)
                    Text("AtomStudies")
                        .font(.largeTitle)
                    Text("Learn the basics of Chemistry from anywhere!")
                        .font(.subheadline)
                    HStack{}.padding()
                    HStack {
                        ProgressView()
                        Text("Initialising application...")
                    }
                    .padding()
                    .onFirstAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            print("initiailised")
                            Firebase.main = Firebase()
                        }
                    }
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .frame(
                maxWidth: renderedBackground ? 1500 : 0,
                maxHeight: renderedBackground ? 1500 : 0,
                alignment: .center
            )
            .animation(.easeInOut, value: renderedBackground)
            .opacity(renderedBackground ? 1 : 0)
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .center
        )
        
    }
}
