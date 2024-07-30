//
//  PseImageView.swift
//  PersonalAiAssistant
//
//  Created by Anshul Ruhil on 2024-07-29.
//

import SwiftUI

struct PoseImageView: View {
    var image: UIImage
    var overlay: UIView?

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            if let overlay = overlay {
                UIViewRepresentableView(overlay: overlay)
            }
        }
    }
}

struct UIViewRepresentableView: UIViewRepresentable {
    var overlay: UIView

    func makeUIView(context: Context) -> UIView {
        return overlay
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
