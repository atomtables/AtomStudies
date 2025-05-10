//
//  SignupScreen.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 30/1/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAuthCombineSwift

struct SignupScreen: View {
    @Binding var screen: Screen;

    @State var email: String = ""

    @State var password: String = ""
    @State var newPassword: String = ""

    @State var error: String = ""

    @State var firstName: String = ""
    @State var lastName: String = ""

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
            Text("Create an account")
                .font(.title2)
                .padding()
            TextField("First Name", text: $firstName)
                .textContentType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            TextField("Last Name", text: $lastName)
                .textContentType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            SecureField("Confirmation", text: $newPassword)
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
                Button("Sign Up") {
                    Task {
                        creating = true
                        do {
                            if (firstName == "" || lastName == "") {
                                self.error = "Please fill out all fields."
                                return;
                            }
                            if (password != newPassword) {
                                self.error = "Your passwords do not match!"
                                return;
                            }
                            try await Firebase.main.signup(email: email, password: password, user: User(firstName: firstName, lastName: lastName))
                        } catch {
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
        }
        .frame(width: 300)
    }
}
