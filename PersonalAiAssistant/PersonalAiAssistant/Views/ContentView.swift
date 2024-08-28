import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var email: String = ""

    var body: some View {
        VStack {
            if isSignedIn {
                MainView(email: email) // Pass the email to MainView
            } else {
                SignInView()
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { auth, user in
                if let user = user {
                    self.isSignedIn = true
                    self.email = user.email ?? "" // Fetch the user's email
                } else {
                    self.isSignedIn = false
                }
            }
        }
    }
}
