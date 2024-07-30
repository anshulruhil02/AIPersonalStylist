import SwiftUI
import AVFoundation
import Vision

struct CameraViewController: UIViewControllerRepresentable {
    @Binding var faceDetected: Bool
    @Binding var skinColor: UIColor
    var onSkinColorDetected: ((UIColor) -> Void)?
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraViewController
        var session: AVCaptureSession
        lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
            return VNDetectFaceRectanglesRequest(completionHandler: self.handleFaceDetection)
        }()
        
        init(parent: CameraViewController) {
            self.parent = parent
            self.session = AVCaptureSession()
            
            super.init()
            
            configureSession()
        }
        
        private func configureSession() {
            guard session.canSetSessionPreset(.high) else { return }
            session.beginConfiguration()
            session.sessionPreset = .high
            
            // Set up the video capture device
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  session.canAddInput(videoDeviceInput) else {
                session.commitConfiguration()
                return
            }
            session.addInput(videoDeviceInput)
            
            // Set up the video data output
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            guard session.canAddOutput(videoDataOutput) else {
                session.commitConfiguration()
                return
            }
            session.addOutput(videoDataOutput)
            
            session.commitConfiguration()
        }
        
        func startRunning() {
            session.startRunning()
        }
        
        func stopRunning() {
            session.stopRunning()
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try requestHandler.perform([faceDetectionRequest])
            } catch {
                print(error)
            }

            // Check if a face was detected and process the frame
            if let faceObservation = (faceDetectionRequest.results as? [VNFaceObservation])?.first {
                DispatchQueue.main.async {
                    self.parent.faceDetected = true
                    self.extractSkinColor(from: sampleBuffer, faceObservation: faceObservation)
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.faceDetected = false
                }
            }
        }
        
        private func handleFaceDetection(request: VNRequest, error: Error?) {
            guard let results = request.results as? [VNFaceObservation], let faceObservation = results.first else {
                DispatchQueue.main.async {
                    self.parent.faceDetected = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.parent.faceDetected = true
            }
        }
        
        private func extractSkinColor(from sampleBuffer: CMSampleBuffer, faceObservation: VNFaceObservation) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let width = ciImage.extent.width
            let height = ciImage.extent.height
            
            let boundingBox = faceObservation.boundingBox
            let faceRect = CGRect(
                x: boundingBox.origin.x * width,
                y: boundingBox.origin.y * height,
                width: boundingBox.size.width * width,
                height: boundingBox.size.height * height
            )
            
            let faceImage = ciImage.cropped(to: faceRect)
            detectSkinColor(in: faceImage)
        }
        
        private func detectSkinColor(in image: CIImage) {
            let context = CIContext()
            guard let cgImage = context.createCGImage(image, from: image.extent) else { return }
            
            let bitmap = Bitmap(image: cgImage)
            let skinColor = bitmap.predominantColor()
            
            DispatchQueue.main.async {
                self.parent.skinColor = skinColor
                self.parent.onSkinColorDetected?(skinColor)  // Call the closure with the detected skin color
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        // Add the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: context.coordinator.session)
        previewLayer.videoGravity = .resizeAspectFill
        controller.view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = controller.view.bounds
            context.coordinator.startRunning()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        coordinator.stopRunning()
    }
}
