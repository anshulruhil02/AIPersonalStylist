import SwiftUI

struct CameraView: View {
    @State private var faceDetected = false
    @State private var faceBoundaries: CGRect? = nil
    @State private var skinColor = UIColor.clear
    var onSkinColorDetected: ((UIColor) -> Void)?

    var body: some View {
        ZStack {
            CameraViewController()
                .edgesIgnoringSafeArea(.all)
        }
    }
}


struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
