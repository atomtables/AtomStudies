//
//  CurriculumPage.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 6/2/2025.
//

import Polygon
import SwiftUI

public struct CurriculumUnit: Identifiable {
    public let id = UUID()
    let number: Int
    let name: String
    let description: String

    let sublessons: [CurriculumBlock]
}

public struct CurriculumBlock: Identifiable {
    public enum CurriculumType {
        case lesson
        case quiz
        case test
    }

    let unit: Int
    let block: Int

    public let id = UUID()

    let topic: String
    let type: CurriculumType
    var length: Int = 0 // amount of blocks
    var image: String? = nil
}

struct CurriculumPage: View {
    let orientationInfo = OrientationInfo()

    var data: [CurriculumUnit]? { FirebaseViewData.main.previews }

    var unitCount: Int { guard let count = data?.count else {return 0}; return count; }
    var sublessonCount: Int {
        guard let data else {return 0};
        var sum = 0
        for d in data {
            sum += d.sublessons.count
        }
        return sum
    }

    var sublessonCounts: [Int] {
        guard let data else {return []};
        var sum: [Int] = []
        for (d) in data {
            sum.append(d.sublessons.count)
        }
        return sum
    }

    var pixelCount: CGFloat {
        var sum: CGFloat = 0

        sum += CGFloat(unitCount * 75)
        sum += CGFloat(sublessonCount * 50)
        sum += CGFloat((unitCount + sublessonCount - 1) * 20)

        return sum
    }

    init() {
        Firebase.main.updatePreviews()
    }

    @Environment(\.horizontalSizeClass) var h

    var body: some View {
        if h == .compact {
            ScrollView {
                VStack {
                    if (orientationInfo.orientation == .portrait) {
                        CurrentlyOnView()
                            .padding(10)
                    }
                    HStack(alignment: .top) {
                        if let data {
                            HStack(alignment: .top) {
                                ZStack(alignment: .center) {
                                    Rectangle()
                                        .frame(width: 4, height: pixelCount)
                                    VStack(spacing: 20) {
                                        ForEach(data, id: \.id) { unit in
                                            Text("U\(unit.number): \(unit.name)")
                                                .bold()
                                                .font(.title3)
                                                .padding(.horizontal)
                                                .frame(height: 75)
                                                .background {
                                                    Capsule()
                                                        .fill(.background)
                                                        .frame(height: 75)
                                                }
                                                .clipShape(Capsule())
                                            ForEach(unit.sublessons, id: \.id) { lesson in
                                                CurriculumShape(lesson: lesson)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            if !FirebaseViewData.main.errorFetchingPreviews {
                                HStack {
                                    ProgressView().padding()
                                    Text("Loading...")
                                }
                            } else {
                                VStack {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red).padding()
                                        Text("There was an error.")
                                    }
                                    Button("Try again") {
                                        Firebase.main.updatePreviews()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        } else {
            VStack {
                if (orientationInfo.orientation == .portrait) {
                    CurrentlyOnView()
                        .padding(10)
                }
                HStack(alignment: .top) {
                    if let data {
                        ScrollView {
                            HStack(alignment: .top) {
                                ZStack {
                                    ForEach(data.getSubarray(by: 2), id: \.id) { unit in
                                        CurriculumUnitInfo(unit: unit, sublessonCounts: sublessonCounts)
                                    }
                                }
                                ZStack(alignment: .center) {
                                    Rectangle()
                                        .frame(width: 4, height: pixelCount)
                                    VStack(spacing: 20) {
                                        ForEach(data, id: \.id) { unit in
                                            Text("U\(unit.number)")
                                                .bold()
                                                .font(.title3)
                                                .frame(width: 75, height: 75)
                                                .background {
                                                    Circle()
                                                        .fill(.background)
                                                        .frame(width: 75, height: 75)
                                                }
                                                .clipShape(Circle())
                                            ForEach(unit.sublessons, id: \.id) { lesson in
                                                CurriculumShape(lesson: lesson)
                                            }
                                        }
                                    }
                                }
                                ZStack {
                                    ForEach(data.getSubarray(start: 1, by: 2), id: \.id) { unit in
                                        CurriculumUnitInfo(unit: unit, sublessonCounts: sublessonCounts)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        if (orientationInfo.orientation == .landscape) {
                            CurrentlyOnView()
                                .frame(width: 350, alignment: .leading)
                        }
                    } else {
                        if !FirebaseViewData.main.errorFetchingPreviews {
                            HStack {
                                ProgressView().padding()
                                Text("Loading...")
                            }
                        } else {
                            VStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red).padding()
                                    Text("There was an error.")
                                }
                                Button("Try again") {
                                    Firebase.main.updatePreviews()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CircularProgressView: View {
    var progress: Double // Value between 0.0 and 1.0
    var lineWidth: CGFloat = 10
    var color: Color = .accentColor

    var body: some View {
        ZStack {
            // Background Circle (Gray Track)
            Circle()
                .stroke(Color.gray.opacity(0.6), lineWidth: lineWidth)

            // Progress Circle (Trimmed)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
        }
    }
}

struct CurriculumShape: View {
    @State var opened: Bool = false
    @State var invalid = false
    let lesson: CurriculumBlock
    var isCompleted: Bool { Firebase.main.progress?[lesson.unit-1].blocks[lesson.block-1].isCompleted ?? false }
    var completed: Int {
        Firebase.main.progress?[lesson.unit-1]
            .blocks[lesson.block-1].currentSection ?? 0
    }

    var body: some View {
        Container {
            if (lesson.type == .lesson) {
                ZStack {
                    Circle()
                        .fill(
                             isCompleted ? Color.accentColor : Color.blue
                        )
                        .frame(width: 50, height: 50)
                    CircularProgressView(
                        progress: Double(completed)/Double(lesson.length)
                    )
                        .frame(width: 50, height: 50)
                }
            } else if (lesson.type == .quiz) {
                Polygon(numberOfSides: 3)
                    .rotationAngle(Angle(degrees: 270))
                    .fill(isCompleted ? Color.accentColor : Color.blue)
                    .frame(width: 50, height: 50)
            } else if (lesson.type == .test) {
                Rectangle()
                    .fill(isCompleted ? Color.accentColor : Color.blue)
                    .frame(width: 50, height: 50)
            }
        }
        .popover(isPresented: $opened, arrowEdge: .leading) {
            VStack(alignment: .leading) {
                Text("Block \(lesson.unit).\(lesson.block)")
                    .font(.title3)
                Text("\(lesson.topic)")
                    .font(.title)
                    .bold()
                Text("Currently on section 1")
                    .font(.subheadline)
                HStack {
                    Button("Open Section") {
                        withAnimation {
                            opened = !opened
                            print(FirebaseViewData.main)
                            FirebaseViewData.main.unit = lesson.unit
                            FirebaseViewData.main.block = lesson.block
                            FirebaseViewData.main.section = lesson.type == .lesson ? 1 : nil
                            FirebaseViewData.main.isLessonShown = true
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .padding(.vertical, 10)
                }
            }
            .padding()
        }
        .onTapGesture {
            if (lesson.unit == 1) {
                opened = !opened
            } else {
                invalid = !invalid
            }
        }
        .alert("You must finish Unit 1 to continue with this unit!", isPresented: $invalid) {
            Button("OK") {
                invalid = !invalid
            }
        }
    }
}

struct CurriculumUnitInfo: View {
    let unit: CurriculumUnit;
    let sublessonCounts: [Int]

    var units: Int {
        (unit.number - 1) * 75
    }
    var sublessons: Int {
        self.sublessonCounts.getSubarray(start: 0, end: unit.number - 1).sum() * 50
    }
    var spacing: Int {
        (self.addNums((unit.number - 1), self.sublessonCounts.getSubarray(start: 0, end: unit.number - 1).sum()) - 1) * 20 + 20
    }

    var body: some View {
        if let progress = FirebaseViewData.main.progress {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Unit \(unit.number): \(unit.name)")
                        .font(.title)
                        .bold()
                    Text(unit.description)
                        .lineLimit(3, reservesSpace: true)
                        .padding(.bottom, 5)
                    Text(unit.number == 1 ? "\((progress[0].currentBlock.block * 100)/progress[0].blocks.count)% completed": "0% completed")
                        .font(.subheadline)
                    Text(unit.number == 1 ? "\(progress[0].currentBlock.block)/\(progress[0].blocks.count) blocks completed" : "0/\(unit.sublessons.count) blocks completed")
                        .font(.subheadline)
                }
                .padding()
            }
            .frame(width: 350, alignment: .leading)
            .background(.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .offset(
                y: self.addNums(units, sublessons, spacing)
            )
        }
    }

    func addNums(_ args: Int...) -> Int {
        var i = 0
        for j in args {
            i += j
        }
        return (i)
    }

    func addNums(_ args: Int...) -> CGFloat {
        var i = 0
        for j in args {
            i += j
        }
        return CGFloat(i)
    }
}

struct CurrentlyOnView: View {
    @State var curriculum: [CurriculumUnit]?
    @State var lesson: Lesson?

    var body: some View {
        if let progress = FirebaseViewData.main.progress, let curriculum, let lesson {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Current Progress")
                        .font(.title)
                        .bold()
                    Divider()
                    HStack(alignment: .top) {
                        Image(systemName: "star.fill")
                        VStack(alignment: .leading) {
                            Text("Currently on")
                            Text("Unit 1: \(curriculum[0].name)")
                                .font(.title3)
                                .bold()
                        }
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Image(systemName: "book.fill")
                        VStack(alignment: .leading) {
                            Text("Block:")
                            Text("1.\(progress[0].currentBlock.block): \(curriculum[0].sublessons[progress[0].currentBlock.block-1].topic)")
                                .font(.title3)
                                .bold()
                        }
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Image(systemName: "book.fill")
                        VStack(alignment: .leading) {
                            Text("Continue Learning")
                            Text("1.\(progress[0].currentBlock.block).\(lesson.section ?? 0): \(lesson.name)")
                                .font(.title3)
                                .bold()
                        }
                    }
                }
                .padding()
            }
            .background(.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            HStack {
                ProgressView().padding()
                Text("Loading...")
            }
            .onAppear {
                Task {
                    Firebase.main.progress = try! await Firebase.main.fetch()
                    curriculum = try! await Firebase.main.fetch()
                    lesson = try! await Firebase.main
                        .fetch(
                            unit: 1,
                            block: Firebase.main.progress![0].currentBlock.block,
                            section: Firebase.main.progress![0].currentBlock.currentSection
                        )
                }
            }
        }
    }
}
