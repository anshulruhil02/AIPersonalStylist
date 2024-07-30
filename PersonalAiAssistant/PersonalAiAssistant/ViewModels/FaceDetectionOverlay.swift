import SwiftUI

struct FaceDetectionOverlay: View {
    @Binding var faceDetected: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(faceDetected ? Color.green : Color.red, lineWidth: 4)
                .frame(width: 300, height: 400)
        }
    }
}
