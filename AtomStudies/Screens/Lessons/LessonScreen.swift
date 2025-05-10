//
//  LessonScreen.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 26/2/2025.
//

import SwiftUI

struct LessonScreen: View {
    @State var lesson: Lesson?;

    @State var currentScreen: Int = 0
    var currentContent: LessonContent! { lesson?.content[currentScreen] }

    var necessaryWidth: CGFloat {
        guard let lesson else {return 0};
        return (UIScreen.main.bounds.width / 2) / CGFloat(lesson.length)
    }

    @State var errorOccured = false

    @State var readyToGoNext: Bool? = false

    func loadLesson() {
        Task { [self] in
            do {
                self.lesson = try await Firebase.main
                    .fetch(
                        unit: FirebaseViewData.main.unit,
                        block: FirebaseViewData.main.block,
                        section: FirebaseViewData.main.section
                    )
            } catch {
                errorOccured = true
            }
        }
    }

    var body: some View {
        if let lesson {
            if lesson.type == .lesson {
                VStack {
                    HStack {
                        ForEach(0..<lesson.length, id: \.self) { i in
                            Capsule()
                                .frame(width: necessaryWidth, height: 5)
                                .padding(.horizontal, 2)
                                .foregroundStyle(currentScreen == i ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                        }
                    }
                    .padding()
                    VStack {
                        if let image = currentContent.image {
                            Image(image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 380)
                                .padding(20)
                        }
                        if currentContent.type == .question {
                            LessonQuestionView(currentContent: currentContent, readyToGo: .constant(true))
                                .id(currentScreen)
                                .frame(maxWidth: 380)
                        } else {
                            ScrollView {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(currentContent.title!)
                                            .font(.title3)
                                            .bold()
                                            .padding(.vertical, 5)
                                        Divider()
                                        Text(currentContent.content ?? "")
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(minWidth: 400)
                    Spacer()
                    HStack {
                        if currentScreen > 0 {
                            Button("Previous") {
                                withAnimation { currentScreen -= 1; }
                            }
                            .buttonStyle(BorderedButtonStyle())
                        } else {
                            Button("Exit") {
                                withAnimation { FirebaseViewData.main.isLessonShown = false }
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                        Spacer()
                        Button(currentScreen + 1 == lesson.length ? "Finish" : "Next") {
                            if currentScreen + 1 == lesson.length {
                                // completed
                                withAnimation {
                                    FirebaseViewData.main.isLessonShown = false
                                }
                            } else {
                                withAnimation { currentScreen += 1; }
                            }
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width / 2)
                .padding()
            } else {
                // is a quiz or a test
                VStack {
                    HStack {
                        ForEach(0..<lesson.length, id: \.self) { i in
                            Capsule()
                                .frame(width: necessaryWidth, height: 5)
                                .padding(.horizontal, 2)
                                .foregroundStyle(currentScreen == i ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                        }
                    }
                    .padding()
                    VStack {
                        if let image = currentContent.image {
                            Image(image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 380)
                            .padding(20)
                        }
                        LessonQuestionView(
                            currentContent: currentContent,
                            readyToGo: $readyToGoNext
                        )
                            .id(currentScreen)
                    }
                    .frame(minWidth: 380)
                    Spacer()
                    HStack {
                        Spacer()
                        Button(currentScreen + 1 == lesson.length ? "Finish" : "Next") {
                            if currentScreen + 1 == lesson.length {
                                // completed
                                withAnimation {
                                    FirebaseViewData.main.isLessonShown = false
                                }
                            } else {
                                withAnimation { currentScreen += 1; }
                            }
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(!(readyToGoNext ?? true))
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width / 2)
                .padding()
            }
        } else {
            if !errorOccured {
                HStack {
                    ProgressView()
                    Text("Loading lesson...")
                }
                .onAppear {
                    if FirebaseViewData.main.isLessonShown { loadLesson() }
                }
            } else {
                VStack {
                    HStack {
                        Text("An error occured...")
                    }
                    HStack {
                        Button("Retry") {
                            loadLesson()
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        Button("Quit") {
                            withAnimation { FirebaseViewData.main.isLessonShown = false }
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                }
            }
        }
    }
}

struct LessonQuestionView: View {
    let currentContent: LessonContent

    @Binding var readyToGo: Bool?
    @State var selectedAnswer: Int?

    @Environment(\.horizontalSizeClass) var h

    var body: some View {
        VStack(alignment: .leading) {
            if h == .compact {
                Text(currentContent.title!)
                    .font(.subheadline).bold()
            } else {
                Text(currentContent.title!)
                    .font(.title2).bold()
            }
            VStack {
                ForEach(Array((currentContent.choices?.enumerated())!), id: \.element) { i, choice in
                    LessonQuestionOptionView(
                        i: i,
                        choice: choice,
                        isCorrectAnswer: currentContent.correct == i,
                        readyToGo: $readyToGo,
                        selectedAnswer: $selectedAnswer
                    )
                }
            }

        }
    }
}

struct LessonQuestionOptionView: View {
    let i: Int
    let choice: String
    let isCorrectAnswer: Bool
    @Binding var readyToGo: Bool?
    @Binding var selectedAnswer: Int?

    @State var isHovering: Bool = false
    @State var isPressed: Bool = false

    var backgroundState: AnyShapeStyle {
        if let selectedAnswer, selectedAnswer == i, isCorrectAnswer {
            return AnyShapeStyle(Color.green)
        } else if let selectedAnswer, selectedAnswer == i, !isCorrectAnswer {
            return AnyShapeStyle(Color.red)
        } else if isHovering {
            return AnyShapeStyle(.tertiary)
        }
        return AnyShapeStyle(.quinary)
    }

    var body: some View {
        HStack {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.background)
                    .border(.secondary, width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(width: 40, height: 40)
                Text("\(i + 1)")
            }
            .padding()
            Text(choice)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(backgroundState)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .onHover { hover in isHovering = hover; }
        .onTapGesture {
            withAnimation {
                selectedAnswer = i
                if isCorrectAnswer { readyToGo = true }
            }
        }
        .scaleEffect(isHovering ? 0.9 : 1.0) // Shrinks while held
        .animation(.spring(), value: isHovering)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.1) // Triggers instantly
                .onChanged { _ in withAnimation { isPressed = true; isHovering = true; } } // Shrink when touched
                .onEnded { _ in withAnimation { isPressed = false; isHovering = false; } } // Restore on release
        )
    }
}
