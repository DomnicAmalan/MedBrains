import MedBrainsKit
import MedBrainsUI
import SwiftUI

/// Sign-in the HIG way: a form with labelled fields, the keyboard's return
/// key advancing username → password → submit, an inline error that says
/// what to do, and a single prominent action.
struct LoginView: View {
    @Environment(AuthStore.self) private var auth
    @State private var username = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @FocusState private var focus: Field?

    private enum Field { case username, password }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username or email", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .submitLabel(.next)
                        .focused($focus, equals: .username)
                        .onSubmit { focus = .password }
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .focused($focus, equals: .password)
                        .onSubmit { Task { await submit() } }
                } header: {
                    Text("Sign in")
                } footer: {
                    if let error = auth.lastError {
                        Label(error, systemImage: "exclamationmark.circle")
                            .foregroundStyle(MedBrainsTheme.danger)
                            .accessibilityLabel("Sign-in failed: \(error)")
                    }
                }
                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isSigningIn {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Sign in").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(username.isEmpty || password.isEmpty || isSigningIn)
                    .accessibilityIdentifier("signIn")
                }
            }
            .navigationTitle("MedBrains")
            .onAppear { focus = .username }
        }
    }

    private func submit() async {
        guard !username.isEmpty, !password.isEmpty else { return }
        isSigningIn = true
        defer { isSigningIn = false }
        _ = await auth.signIn(username: username, password: password)
    }
}
