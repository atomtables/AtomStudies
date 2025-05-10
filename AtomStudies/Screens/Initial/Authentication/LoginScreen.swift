//
//  LoginScreen.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 2/12/2024.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAuthCombineSwift

struct LoginScreen: View {
    @Binding var screen: Screen;

    @State var email: String = ""
    @State var password: String = ""
    @State var error: String = ""

    @State var creating = false;

    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation { screen = .Welcome }
                } label: {
                    Image(systemName: "chevron.backward")
                }
                Spacer()
            }
            AppIcon()
                .frame(width: 80, height: 80)
            Text("AtomStudies")
                .font(.largeTitle)
            Text("Login")
                .font(.title2)
                .padding()
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            if error != "" {
                Label(title: {Text(error)}, icon: {Image(systemName: "exclamationmark.circle.fill")})
                    .foregroundStyle(.red)
                    .padding()
            }
            HStack {
                if (creating) { ProgressView() }
                Button("Log In") {
                    Task {
                        creating = true
                        do {
                            try await Firebase.main.login(email: email, password: password)
                        } catch {
                            print(error)
                            switch (error as NSError).code {
                            case 17009: self.error = "Invalid password";
                            case 17008: self.error = "Invalid email";
                            case 17004: self.error = "Invalid credentials";
                            default: self.error = "Unknown error: \(error.localizedDescription)"
                            }
                        }
                        creating = false
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .disabled(creating)
            }
            Button("Log in with Google+") {

            }
            Button("Log in with Facebook") {

            }
        }
        .frame(width: 300)
    }
}
