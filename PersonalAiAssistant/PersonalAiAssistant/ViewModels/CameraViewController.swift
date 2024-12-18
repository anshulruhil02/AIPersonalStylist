import SwiftUI
import AVFoundation
import Vision

struct CameraViewController: UIViewControllerRepresentable {
    var overlayLayer: CALayer? = CALayer()
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraViewController
        var session: AVCaptureSession
        var previewLayer: AVCaptureVideoPreviewLayer!
        var overlayLayer: CALayer!
        var previousJointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        var lastPoseChangeTime: Date = Date()
        let poseStabilityThreshold: TimeInterval = 2.0
        let maxFramesForSmoothing = 5
        
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
                        //print("Body detected!")
                        // Clear the previous overlay dots
                        self?.parent.overlayLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }
                        
                        // Draw dots for all landmarks
                        self?.drawBodyLandmarks(for: firstBodyPose)
                    }
                } else {
                    DispatchQueue.main.async {
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
                if let point = try? bodyPose.recognizedPoint(jointName), point.confidence > 0.3 {
                    let normalizedPoint = CGPoint(x: point.location.x, y: 1 - point.location.y)
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
                (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
                (.leftHip, .rightHip),
                (.leftHip, .leftKnee), (.rightHip, .rightKnee),
                (.leftKnee, .leftAnkle), (.rightKnee, .rightAnkle),
            ]
            
            var allConnectionsExist = true
            
            // Draw lines for connections with explicit checks
            for (startJoint, endJoint) in connections {
                if let start = jointPoints[startJoint], let end = jointPoints[endJoint] {
                    drawLine(from: start, to: end)
                } else {
                    //print("Missing joint(s): \(startJoint) or \(endJoint)")
                    allConnectionsExist = false
                }
            }
            
            // Check pose stability only if all connections exist
            if allConnectionsExist {
                checkPoseStability(currentJointPoints: jointPoints)
            } else {
                //print("Skipping pose stability check due to missing connections.")
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
        
        private func checkPoseStability(currentJointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
            let poseChanged = hasPoseChanged(currentJointPoints: currentJointPoints)
            
            if poseChanged {
                lastPoseChangeTime = Date()  // Reset the timer
                previousJointPoints = currentJointPoints
            } else if Date().timeIntervalSince(lastPoseChangeTime) > poseStabilityThreshold {
                print("Pose has remained unchanged for more than 5 seconds.")
                print(currentJointPoints)
                exportJointCoordinatesToFile(jointPoints: currentJointPoints)
            }
        }

        private func exportJointCoordinatesToFile(jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
            print("Pose Joint Coordinates:")
            for (jointName, point) in jointPoints {
                let coordinateLine = "\(jointName.rawValue): (\(String(format: "%.2f", point.x)), \(String(format: "%.2f", point.y)))"
                print(coordinateLine)
            }
            print("---------------------------")
        }


        
        private func hasPoseChanged(currentJointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> Bool {
            guard !previousJointPoints.isEmpty else {
                previousJointPoints = currentJointPoints
                return true
            }
            
            for (jointName, currentPoint) in currentJointPoints {
                if let previousPoint = previousJointPoints[jointName] {
                    let deltaX = abs(currentPoint.x - previousPoint.x)
                    let deltaY = abs(currentPoint.y - previousPoint.y)
                    
                    if deltaX > 5 || deltaY > 5 {  // Threshold for "significant movement"
                        return true  // Pose has changed
                    }
                }
            }
            return false  // Pose is unchanged
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
