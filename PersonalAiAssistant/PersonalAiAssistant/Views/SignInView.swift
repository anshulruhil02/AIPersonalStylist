import SwiftUI
import FirebaseAuth

enum NavigationPath: Hashable {
    case mainView
}

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var navigationPath: [NavigationPath] = []  // State variable to control navigation

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Spacer()
                
                Image("appLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .padding()
                
                Text("Sign In")
                    .font(.custom("YourCustomFont-Bold", size: 34))
                    .padding()
                
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: signIn) {
                    Text("Sign In")
                        .font(.custom("YourCustomFont-SemiBold", size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                NavigationLink("Don't have an account? Sign Up", value: NavigationPath.mainView)
                    .font(.custom("YourCustomFont-Regular", size: 18))
                    .padding(.top, 20)
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
            )
            .navigationDestination(for: NavigationPath.self) { path in
                switch path {
                case .mainView:
                    MainView()
                }
            }
        }
    }

    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.errorMessage = nil
                navigationPath.append(.mainView)  // Navigate to MainView
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
