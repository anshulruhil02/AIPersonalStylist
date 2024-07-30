import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraOverlayView = createOverlay()
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func createOverlay() -> UIView {
        let overlay = UIView(frame: UIScreen.main.bounds)
        overlay.backgroundColor = UIColor.clear
        
        let faceOutline = UIView(frame: CGRect(x: overlay.bounds.midX - 75, y: overlay.bounds.midY - 100, width: 150, height: 200))
        faceOutline.layer.borderColor = UIColor.red.cgColor
        faceOutline.layer.borderWidth = 2
        faceOutline.layer.cornerRadius = 10
        
        overlay.addSubview(faceOutline)
        
        return overlay
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImagePicked(uiImage)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
