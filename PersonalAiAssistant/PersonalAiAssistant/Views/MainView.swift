import SwiftUI

struct MainView: View {
    @State private var showCameraView = false
    @State private var detectedSkinColor: UIColor = .clear

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
                    .background(detectedSkinColor == .clear ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
            .padding(.horizontal)
            .disabled(detectedSkinColor != .clear)
            .sheet(isPresented: $showCameraView) {
                CameraView(onSkinColorDetected: { color in
                    self.detectedSkinColor = color
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
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
