import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isSignedIn = false

    var body: some View {
        VStack {
            if isSignedIn {
                MainView() // Your main app view after signing in
            } else {
                SignInView()
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { auth, user in
                self.isSignedIn = user != nil
            }
        }
    }
}
