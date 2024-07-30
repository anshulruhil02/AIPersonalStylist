import AVFoundation

class CameraCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var session: AVCaptureSession? // This property holds the AVCaptureSession, which manages the flow of data from the camera to the app.

    override init() {
        super.init()
        self.session = AVCaptureSession() // Initialize the AVCaptureSession.
        configureSession() // Configure the session.
    }

    private func configureSession() {
        guard let session = self.session else { return }

        session.beginConfiguration() // Begin configuring the session.

        // Set up the video capture device.
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) // Select the front camera.
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), // Create an input from the camera.
              session.canAddInput(videoDeviceInput) else {
            session.commitConfiguration() // Commit the configuration if the input can't be added.
            return
        }
        session.addInput(videoDeviceInput) // Add the camera input to the session.

        // Set up the video data output.
        let videoDataOutput = AVCaptureVideoDataOutput() // Create a video data output.
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue")) // Set the sample buffer delegate to self.
        guard session.canAddOutput(videoDataOutput) else { // Check if the output can be added to the session.
            session.commitConfiguration() // Commit the configuration if the output can't be added.
            return
        }
        session.addOutput(videoDataOutput) // Add the video data output to the session.

        session.commitConfiguration() // Commit the session configuration.
    }

    func startRunning() {
        session?.startRunning() // Start the session.
    }

    func stopRunning() {
        session?.stopRunning() // Stop the session.
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Handle the captured sample buffer here.
        // This is where you'll add code to process the video frames.
    }
}
