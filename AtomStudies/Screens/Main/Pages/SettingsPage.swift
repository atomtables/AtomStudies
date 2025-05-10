//
//  SettingsPage.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 5/2/2025.
//

import SwiftUI

enum CurrentSettingsPages {
    case user
}

struct SettingsPage: View {
    @State var page: CurrentSettingsPages! = .user
    @State var showSignOutPrompt: Bool = false

    var body: some View {
        VStack {
            NavigationSplitView(
                columnVisibility: .constant(.all),
                preferredCompactColumn: .constant(.sidebar)
            ) {
                List(selection: $page) {
                    NavigationLink(value: CurrentSettingsPages.user) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text("\(Firebase.main.user.firstName) \(Firebase.main.user.lastName)")
                                    .font(.title3)
                                Text(Firebase.main.email)
                            }
                        }
                    }
                    Divider()
                    Button("Sign Out") {
                        showSignOutPrompt = true
                    }
                    .alert(isPresented: $showSignOutPrompt) {
                        let alert = Alert(
                            title: Text("Sign Out"),
                            message: Text("Are you sure you want to sign out?"),
                            primaryButton: Alert.Button
                                .cancel(Text("Cancel")) { showSignOutPrompt = false },
                            secondaryButton: Alert.Button
                                .destructive(Text("Sign Out")) {
                                    try? Firebase.main.logout()
                                }
                        )
                        return alert
                    }
                }
                .listStyle(SidebarListStyle())
                .modifier(CoolBackgroundModifier(blurRadius: 5))
                .scrollContentBackground(.hidden)
            } detail: {
                VStack {
                    Text(Firebase.main.email)
                    Button("Sign out") {
                        do {
                            try Firebase.main.logout()
                        } catch {}
                    }
                }
                .modifier(CoolBackgroundModifier(blurRadius: 20))
                .scrollContentBackground(.hidden)
            }
        }
    }
}
