import SwiftUI

struct CameraView: View {
    var onSkinColorDetected: ((UIColor) -> Void)?

    @State private var faceDetected = false
    @State private var skinColor = UIColor.clear
    
    var body: some View {
        VStack {
            ZStack {
                CameraViewController(faceDetected: $faceDetected, skinColor: $skinColor, onSkinColorDetected: onSkinColorDetected)
                    .edgesIgnoringSafeArea(.all)
                FaceDetectionOverlay(faceDetected: $faceDetected)
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
