import SwiftUI
import AVFoundation
import Vision

struct CameraViewController: UIViewControllerRepresentable {
    @Binding var faceDetected: Bool
    @Binding var faceBoundaries: CGRect?
    @Binding var skinColor: UIColor
    var overlayLayer: CALayer? = CALayer()
    var onSkinColorDetected: ((UIColor) -> Void)?
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraViewController
        var session: AVCaptureSession
        var previewLayer: AVCaptureVideoPreviewLayer!
        var overlayLayer: CALayer!
        var capturedColors: [UIColor] = []
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
            capturedColors.removeAll()
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        }
        
        func stopRunning() {
            session.stopRunning()
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Get the pixel buffer from the video frame
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            // Create a Vision request handler
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

            // Perform the body pose request
            let bodyPoseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
                if let error = error {
                    print("Body pose detection error: \(error)")
                    return
                }

                // Check for detected body pose results
                if let results = request.results as? [VNHumanBodyPoseObservation], let firstBodyPose = results.first {
                    DispatchQueue.main.async {
                        print("Body detected!")
                        // Clear the previous overlay dots
                        self?.parent.overlayLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }

                        // Draw dots for all landmarks
                        self?.drawBodyLandmarks(for: firstBodyPose)
                    }
                } else {
                    DispatchQueue.main.async {
                        print("No body detected.")
                    }
                }
            }

            // Perform the Vision request
            do {
                try requestHandler.perform([bodyPoseRequest])
            } catch {
                print("Failed to perform body pose request: \(error)")
            }
        }
        
        private func drawBodyLandmarks(for bodyPose: VNHumanBodyPoseObservation) {
            // Clear previous lines and dots
            overlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            // Retrieve all joint names and positions
            let jointNames: [VNHumanBodyPoseObservation.JointName] = [
                .neck,
                .leftShoulder, .rightShoulder,
                .leftElbow, .rightElbow,
                .leftWrist, .rightWrist,
                .leftHip, .rightHip,
                .leftKnee, .rightKnee,
                .leftAnkle, .rightAnkle
            ]
            
            var jointPoints = [VNHumanBodyPoseObservation.JointName: CGPoint]()

            // Extract points for each joint
            for jointName in jointNames {
                if let point = try? bodyPose.recognizedPoint(jointName), point.confidence > 0.3 { // Lowered threshold
                    let normalizedPoint = CGPoint(x: point.location.x, y: 1 - point.location.y) // Flip vertically
                    print("\(jointName): \(point.confidence)")
                    if let previewLayer = self.previewLayer {
                        let screenPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
                        jointPoints[jointName] = screenPoint
                        drawDot(at: screenPoint)
                    }
                }

            }


            // Define skeletal connections
            let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                (.neck, .leftShoulder), (.neck, .rightShoulder),
                (.leftShoulder, .leftElbow), (.rightShoulder, .rightElbow),
                (.leftElbow, .leftWrist), (.rightElbow, .rightWrist),
                (.leftShoulder,.leftHip), (.rightShoulder, .rightHip),
                (.leftHip, .rightHip), // Add this connection between left and right hips
                (.leftHip, .leftKnee), (.rightHip, .rightKnee),
                (.leftKnee, .leftAnkle), (.rightKnee, .rightAnkle),
            ]

            
            // Draw lines for connections
            for (startJoint, endJoint) in connections {
                if let start = jointPoints[startJoint], let end = jointPoints[endJoint] {
                    drawLine(from: start, to: end)
                }
            }
            
            
        }

        
        private func drawLine(from start: CGPoint, to end: CGPoint) {
            let lineLayer = CAShapeLayer()
            let linePath = UIBezierPath()
            linePath.move(to: start)
            linePath.addLine(to: end)
            
            lineLayer.path = linePath.cgPath
            lineLayer.strokeColor = UIColor.green.cgColor // Line color
            lineLayer.lineWidth = 2.0
            lineLayer.fillColor = UIColor.clear.cgColor
            
            // Add the line layer to the overlay
            overlayLayer.addSublayer(lineLayer)
        }


        
        private func drawDot(at point: CGPoint) {
            // Create a dot shape layer
            let dotLayer = CAShapeLayer()
            let dotSize: CGFloat = 6.0
            let dotRect = CGRect(x: point.x - dotSize / 2, y: point.y - dotSize / 2, width: dotSize, height: dotSize)
            
            dotLayer.path = UIBezierPath(ovalIn: dotRect).cgPath
            dotLayer.fillColor = UIColor.red.cgColor
            
            // Add the dot layer to the overlay
            overlayLayer.addSublayer(dotLayer)
        }


        
        private func handleFaceDetection(request: VNRequest, error: Error?) {
            guard let results = request.results as? [VNFaceObservation], let faceObservation = results.first else {
                DispatchQueue.main.async {
                    self.parent.faceDetected = false
                    self.parent.faceBoundaries = nil
                }
                return
            }
            
            DispatchQueue.main.async {
                self.parent.faceDetected = true
                if let previewLayer = self.previewLayer {
                    self.parent.faceBoundaries = self.convertBoundingBox(faceObservation.boundingBox, to: previewLayer.bounds.size)
                }
            }
        }
        
        private func delayExtractSkinColor(_ sampleBuffer: CMSampleBuffer, faceObservation: VNFaceObservation) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.extractSkinColor(from: sampleBuffer, faceObservation: faceObservation)
            }
        }
        
        private func extractSkinColor(from sampleBuffer: CMSampleBuffer, faceObservation: VNFaceObservation) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let width = ciImage.extent.width
            let height = ciImage.extent.height
            
            let boundingBox = faceObservation.boundingBox
            let centerPoint = CGPoint(
                x: boundingBox.midX * width,
                y: boundingBox.midY * height
            )
            
            let color = getColorFromCIImage(ciImage, at: centerPoint)
            capturedColors.append(color)
            
            // Capture colors for 3 seconds and then calculate the average color
            if capturedColors.count >= 10 {  // Assuming we capture 10 frames within 3 seconds
                let averageColor = averageColor(from: capturedColors)
                DispatchQueue.main.async {
                    self.parent.skinColor = averageColor
                    self.parent.onSkinColorDetected?(averageColor)
                    self.stopRunning()  // Stop the session to prevent further updates
                }
            }
        }
        
        private func getColorFromCIImage(_ image: CIImage, at point: CGPoint) -> UIColor {
            let context = CIContext()
            let pixel = context.createCGImage(image, from: CGRect(origin: point, size: CGSize(width: 1, height: 1)))
            guard let data = pixel?.dataProvider?.data,
                  let ptr = CFDataGetBytePtr(data) else {
                return UIColor.clear
            }
            
            let r = CGFloat(ptr[0]) / 255.0
            let g = CGFloat(ptr[1]) / 255.0
            let b = CGFloat(ptr[2]) / 255.0
            let a = CGFloat(ptr[3]) / 255.0
            
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        
        private func averageColor(from colors: [UIColor]) -> UIColor {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            
            for color in colors {
                var r: CGFloat = 0
                var g: CGFloat = 0
                var b: CGFloat = 0
                var a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                
                red += r
                green += g
                blue += b
                alpha += a
            }
            
            let count = CGFloat(colors.count)
            return UIColor(red: red / count, green: green / count, blue: blue / count, alpha: alpha / count)
        }
        
        private func convertBoundingBox(_ boundingBox: CGRect, to size: CGSize) -> CGRect {
            let width = boundingBox.width * size.width
            let height = boundingBox.height * size.height
            let x = boundingBox.origin.x * size.width
            let y = (1 - boundingBox.origin.y - boundingBox.height) * size.height
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        // Add the camera preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: context.coordinator.session)
        previewLayer.videoGravity = .resizeAspectFill
        context.coordinator.previewLayer = previewLayer
        controller.view.layer.addSublayer(previewLayer)
        
        // Add the overlay layer on top of the camera preview
        let overlayLayer = CALayer()
        overlayLayer.frame = controller.view.bounds
        overlayLayer.backgroundColor = UIColor.clear.cgColor // Transparent background
        controller.view.layer.addSublayer(overlayLayer)
        
        // Pass the overlayLayer to the coordinator
        context.coordinator.overlayLayer = overlayLayer

        DispatchQueue.main.async {
            previewLayer.frame = controller.view.bounds
            overlayLayer.frame = controller.view.bounds
            context.coordinator.startRunning()
        }
        
        return controller
    }

    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        coordinator.stopRunning()
    }
}
