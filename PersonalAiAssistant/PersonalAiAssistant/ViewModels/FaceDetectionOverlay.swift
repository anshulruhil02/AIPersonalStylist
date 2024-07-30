import SwiftUI

struct FaceDetectionOverlay: View {
    var faceBoundaries: CGRect?

    var body: some View {
        ZStack {
            if let faceBoundaries = faceBoundaries {
                Rectangle()
                    .stroke(Color.green, lineWidth: 4)
                    .frame(width: faceBoundaries.width, height: faceBoundaries.height)
                    .position(x: faceBoundaries.midX, y: faceBoundaries.midY)
            } else {
                Rectangle()
                    .stroke(Color.red, lineWidth: 4)
                    .frame(width: 300, height: 400)
            }
        }
    }
}

