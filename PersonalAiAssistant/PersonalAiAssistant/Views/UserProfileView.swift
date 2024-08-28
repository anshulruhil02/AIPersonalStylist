import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    @State private var name: String = ""
    @State private var skinColor: Color = Color.clear

    var body: some View {
        VStack(spacing: 20) {
            if name.isEmpty {
                // Loading Indicator or Placeholder while fetching data
                Text("Loading...")
                    .font(.title)
                    .padding()
            } else {
                // Display the name as the heading
                Text(name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                // Display the skin color section
                VStack {
                    Text("Your Skin Color")
                        .font(.title2)
                        .padding(.bottom, 10)

                    // Display the color box
                    Rectangle()
                        .fill(skinColor)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
        .padding()
        .onAppear {
            fetchUserProfileData()
        }
    }

    func fetchUserProfileData() {
        // Get the current user ID
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        // Get a reference to Firestore
        let db = Firestore.firestore()

        // Fetch the user document
        db.collection("UserDetails").document(userUID).getDocument { document, error in
            if let document = document, document.exists {
                // Extract name and RGB values
                self.name = document.get("name") as? String ?? "No Name"

                if let red = document.get("Red") as? CGFloat,
                   let green = document.get("Green") as? CGFloat,
                   let blue = document.get("Blue") as? CGFloat {
                    // Convert RGB to UIColor and then to SwiftUI Color
                    let uiColor = UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1.0)
                    self.skinColor = Color(uiColor)
                }
            } else {
                print("Document does not exist or there was an error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

#Preview {
    UserProfileView()
}
