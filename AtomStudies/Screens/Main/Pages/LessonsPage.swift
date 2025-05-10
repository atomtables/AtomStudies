//
//  LessonsPage.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 6/2/2025.
//

import SwiftUI

struct LessonsPage: View {
    @State var curriculum: [CurriculumUnit]?
    @State var nextInSection: [Lesson]?
    @State var awards: [Award]?

    @Environment(\.horizontalSizeClass) var h

    var body: some View {
        if let progress = FirebaseViewData.main.progress, let curriculum {
            VStack(alignment: .leading) {
                if h != .compact {
                    VStack(alignment: .leading) {
                        Spacer()
                        if let block = curriculum[0].sublessons.first(where: {progress[0].currentBlock.block == $0.block}), let section = Optional(progress[0].currentBlock.currentSection) {
                            ZStack(alignment: .bottomLeading) {
                                Image(block.image!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: 400
                                    )
                                    .clipped()

                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black.opacity(0.6), location: 0.4),
                                        .init(color: .black, location: 1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: 400
                                )

                                // Content
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Continue Learning")
                                        .bold()
                                    Text("\(block.unit).\(block.block).\(section) \(block.topic)")
                                        .font(.largeTitle)
                                        .bold()
                                    Text("\(block.length) pages")
                                        .font(.title2)
                                    Button("Start Lesson") {
                                        withAnimation {
                                            FirebaseViewData.main.unit = block.unit
                                            FirebaseViewData.main.block = block.block
                                            FirebaseViewData.main.section = section
                                            FirebaseViewData.main.isLessonShown = true
                                        }
                                    }
                                    .padding(.vertical)
                                    .buttonStyle(BorderedProminentButtonStyle())
                                }
                                .padding()
                            }
                        }

                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 400
                    )
                    .padding(.vertical)
                } else {
                    VStack(alignment: .leading) {
                        Spacer()
                        if let block = curriculum[0].sublessons.first(where: {progress[0].currentBlock.block == $0.block}), let section = Optional(progress[0].currentBlock.currentSection) {
                            ZStack(alignment: .bottom) {
                                Image(block.image!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        // maxWidth: .infinity,
                                        maxHeight: 400
                                    )
                                    .clipped()

                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black.opacity(0.6), location: 0.4),
                                        .init(color: .black, location: 1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(
                                   //  maxWidth: .infinity,
                                    maxHeight: 400
                                )

                                // Content
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Continue Learning")
                                        .bold()
                                    Text("\(block.unit).\(block.block).\(section) \(block.topic)")
                                        .font(.largeTitle)
                                        .bold()
                                    Text("\(block.length) pages")
                                        .font(.title2)
                                    Button("Start Lesson") {
                                        withAnimation {
                                            FirebaseViewData.main.unit = block.unit
                                            FirebaseViewData.main.block = block.block
                                            FirebaseViewData.main.section = section
                                            FirebaseViewData.main.isLessonShown = true
                                        }
                                    }
                                    .padding(.vertical)
                                    .buttonStyle(BorderedProminentButtonStyle())
                                }
                                .padding()
                                .frame(
                                    maxWidth: 400
                                )
                            }
                        }

                    }
                    .frame(
                        minHeight: 400
                    )
                    .padding(.vertical)
                }

                Text(
                    "Up Next in \"\(curriculum[0].sublessons.first(where: {progress[0].currentBlock.block == $0.block})!.topic)\""
                )
                .font(.title2)
                .bold()
                .padding(.horizontal).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    if let nextInSection {
                        HStack {
                            ForEach(
                                nextInSection,
                                id: \.name
                            ) { i in
                                LessonCard(title: "1.\(i.block).\(i.section ?? 0)", subtitle: i.name, detail: "\(i.length) pages", image: i.image)
                            }
                        }
                        .padding(.horizontal).padding(.horizontal)
                    } else {
                        HStack {
                            ProgressView().padding()
                            Text("loading")
                        }
                        .onAppear {
                            Task { [self] in
                                var lessons: [Lesson] = []
                                let lesson = curriculum[0].sublessons.first(where: {progress[0].currentBlock.block == $0.block})!
                                for i in progress[0].currentBlock.currentSection..<lesson.length {
                                    lessons
                                        .append(
                                            try! await Firebase.main
                                                .fetch(
                                                    unit: 1,
                                                    block: lesson.block,
                                                    section: i + 1
                                                )
                                        )
                                }
                                nextInSection = lessons
                            }
                        }
                    }

                }
                .padding(.bottom)

                if let previews = FirebaseViewData.main.previews {
                    Text("Next topics in Unit \(progress[0].unit)")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal).padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(
                                previews[0].sublessons.getSubarray(start: progress[0].currentBlock.block),
                                id: \.topic
                            ) { i in
                                LessonCard(
                                    title: "1.\(i.block)",
                                    subtitle: i.topic,
                                    detail: i.type == .lesson ? "\(i.length) lessons" : "10 Questions",
                                    image: i.image
                                )
                            }
                        }
                        .padding(.horizontal).padding(.horizontal)
                    }
                    .padding(.bottom)
                } else {
                    HStack {
                        ProgressView().padding()
                        Text("Loading...")
                    }
                    .onAppear { Task { Firebase.main.updatePreviews() } }
                }

                if let awards {
                    Text("Awards")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(awards, id: \.name) { i in
                                ZStack(alignment: .topTrailing) {
                                    LessonCard(
                                        vertical: true,
                                        title: i.name,
                                        subtitle: i.desc,
                                        detail: nil,
                                        image: i.image
                                    )

                                    Button(action: {
                                        let text = "I won the \(i.name) award on AtomStudies! Come join AtomStudies today!"
                                        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

                                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let window = scene.windows.first,
                                           let rootVC = window.rootViewController {
                                            rootVC.present(activityVC, animated: true)
                                        }
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.title2)
                                            .padding(8)
                                            .background(.tertiary)
                                            .clipShape(Circle())
                                    }
                                    .padding(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                } else {
                    HStack {
                        ProgressView().padding()
                        Text("Loading...")
                    }
                    .onAppear {
                        Task {
                            awards = try! await Firebase.main.fetch()
                        }
                    }
                }
            }
        } else {
            HStack {
                ProgressView()
                    .padding()
                Text("Loading...")
            }
            .onAppear {
                Task {
                    Firebase.main.progress = try! await Firebase.main.fetch()
                    curriculum = try! await Firebase.main.fetch()
                }
            }
        }
    }
}

struct LessonCard: View {
    var vertical: Bool = false

    let title, subtitle: String
    let detail: String?
    let image: String?

    @Environment(\.horizontalSizeClass) var h

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            if let image {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: vertical ? h == .compact ? 150 : 200 : h == .compact ? 225 : 300, height: vertical ? h == .compact ? 225 : 300 : h == .compact ? 135 : 160)
                    .clipped()
            }

            // Gradient overlay for better readability
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.6), location: 0.4),
                    .init(color: .black, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: vertical ? h == .compact ? 150 : 200 : h == .compact ? 225 : 300, height: vertical ? h == .compact ? 225 : 300 : h == .compact ? 135 : 160)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text(subtitle)
                    .foregroundColor(.white)
                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .frame(width: vertical ? h == .compact ? 150 : 200 : h == .compact ? 225 : 300, height: vertical ? h == .compact ? 225 : 300 : h == .compact ? 135 : 160)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


//struct LessonCard: View {
//
//    var vertical: Bool = false;
//
//    let title, subtitle: String;
//    let detail: String?;
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Spacer()
//            ZStack {
//                VStack(alignment: .leading) {
//                    Text(title)
//                        .font(.title2)
//                        .bold()
//                    Text(subtitle)
//                    if let detail {
//                        Text(detail)
//                            .font(.subheadline)
//                    }
//                }
//                .padding()
//                overlay.frame(width: vertical ? 200 : 300, height: vertical ? 300 : 160)
//            }
//        }
//        .frame(width: vertical ? 200 : 300, height: 100, alignment: .leading)
//        .background(Color.background)
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//    }
//
//    var overlay: some View {
//        Rectangle()
//            .overlay(
//                GeometryReader { g in
//                    LinearGradient(
//                        gradient: Gradient(colors: [.clear, .black]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(width: g.size.width, height: g.size.width)
//                    .scaleEffect(x: 1.0, y: g.size.height / g.size.width, anchor: .top)
//                }
//            )
//    }
//}
