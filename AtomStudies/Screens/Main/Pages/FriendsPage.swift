//
//  FriendsPage.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 8/3/2025.
//

import SwiftUI

struct FriendsPage: View {
    let orientationInfo = OrientationInfo()
    @State var leaderboard: [String]?

    var middleIndex: Int { (leaderboard?.firstIndex(of: Firebase.main.email))! }

    @Environment(\.horizontalSizeClass) var h

    var body: some View {
        if let leaderboard {
            VStack {
                if (orientationInfo.orientation == .portrait) {
                    FriendsInfo()
                }
                HStack {
                    ScrollViewReader { reader in
                        ScrollView {
                            VStack {
                                ForEach(Array(leaderboard.getSubarray(start: 0, end: middleIndex).enumerated()), id: \.element) { i, user in
                                    Friend(i: i, user: user, isSelf: false)
                                }
                                Friend(
                                    i: middleIndex,
                                    user: "\(Firebase.main.user.firstName) \(Firebase.main.user.lastName)",
                                    isSelf: true
                                )
                                ForEach(Array(leaderboard.getSubarray(start: middleIndex + 1).enumerated()), id: \.element) { i, user in
                                    Friend(i: middleIndex + i, user: user, isSelf: false)
                                        .id(i == 2 ? "self" : "\(i)")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .onAppear { withAnimation(.easeInOut(duration: 2.5).delay(2.5)) { reader.scrollTo("self") } }
                    }
                    .frame(maxWidth: .infinity)
                    if (orientationInfo.orientation == .landscape) {
                        FriendsInfo()
                    }
                }
            }
            .padding()
        } else {
            HStack {
                ProgressView()
                Text("Loading...")
            }
            .onAppear {
                Task {
                    leaderboard = try! await Firebase.main.fetch();
                    print(leaderboard, middleIndex)
                }
            }
        }
    }
}

struct Friend: View {
    let i: Int
    let user: String
    let isSelf: Bool

    var color: Color {
        let colors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .blue,
            .indigo,
            .pink,
            .brown,
            .gray,
            .background,
            .teal,
            .purple
        ]
        let indice = Int.random(in: 0..<colors.count)
        return colors[indice]
    }

    func matchesGroup(_ text: String) -> [String] {
        let pattern = #"(?:(?<=^)|(?<=\s))([\P{Cc}\P{Cs}\P{Cn}])"#

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            var matches: [String] = []

            regex.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
                if let match = result?.range(at: 1), let range = Range(match, in: text) {
                    matches.append(String(text[range]))
                }
            }
            return matches
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    var body: some View {
        HStack {
            Text("\(i+1)")
                .bold()
                .foregroundStyle(.secondary)

            Text("\(matchesGroup(user).joined())")
                .bold()
                .font(.system(size: 18))
                .frame(width: 45, height: 45, alignment: .center)
                .background(color)
                .clipShape(Circle())
                .minimumScaleFactor(0.5)
                .padding(.horizontal)

            Text(user)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isSelf ? .quaternary : .quinary)
        .scaleEffect(isSelf ? 1 : 0.8)
        .clipShape(RoundedRectangle(cornerRadius: 15))

    }
}

struct FriendsInfo: View {
    @State var error: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text("Amt. Friends")
                    Spacer()
                    Text("67 friends")
                }
                Divider()
                HStack {
                    Text("Amt. Incoming Friend Requests")
                    Spacer()
                    Text("3 people")
                }
                Divider()
                HStack {
                    Text("Amt. Outgoing Friend Requests")
                    Spacer()
                    Text("2 people")
                }
                Divider()
                HStack {
                    Button("View Friends") {
                        error = true
                    }
                    .alert(isPresented: $error) {
                        Alert(title: Text("You must connect to the internet in order to access this feature."))
                    }
                    Spacer()
                }
                Divider()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
