import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @State private var showCameraView = false
    @State private var detectedSkinColor: UIColor = .clear
    var email: String

    var body: some View {
        VStack {
            Spacer()
            
            Image("appLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .padding()
            
            Text("Welcome to Face Color Detector")
                .font(.custom("YourCustomFont-Bold", size: 34))
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Press the button below to detect your skin color.")
                .font(.custom("YourCustomFont-Regular", size: 18))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                showCameraView.toggle()
            }) {
                Text("Show us your face")
                    .font(.custom("YourCustomFont-SemiBold", size: 20))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showCameraView) {
                CameraView(onSkinColorDetected: { color in
                    self.detectedSkinColor = color
                    self.storeSkinColor(color)  // Store the detected color
                    self.showCameraView = false
                })
            }
            
            Spacer()
            
            if detectedSkinColor != .clear {
                Text("Detected Skin Color")
                    .font(.custom("YourCustomFont-Medium", size: 22))
                    .padding()
                    .background(Color(detectedSkinColor))
                    .foregroundColor(Color.black)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal)
            }

            Spacer()

            // Footer Navigation Area
            HStack {
                Spacer()
                
                NavigationLink(destination: UserProfileView()) {
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                        Text("Profile")
                    }
                    .padding()
                }
                
                Spacer()
            }
            .frame(height: 50)
            .background(Color.white.shadow(radius: 5))
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        )
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // Navigate to SignInView
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: SignInView())
                    window.makeKeyAndVisible()
                }
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    func storeSkinColor(_ color: UIColor) {
        // Extract RGB components from UIColor
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Normalize the RGB values to 0-255 range
        let rgbValues = [
            "Red": Int(red * 255.0),
            "Green": Int(green * 255.0),
            "Blue": Int(blue * 255.0)
        ]
        
        // Get the current user ID
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        
        // Get a reference to Firestore
        let db = Firestore.firestore()
        
        // Update the existing user document with RGB values
        db.collection("UserDetails").document(userUID).updateData([
            "Red": rgbValues["Red"] ?? 0,
            "Green": rgbValues["Green"] ?? 0,
            "Blue": rgbValues["Blue"] ?? 0
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(email: "example@example.com")
    }
}
