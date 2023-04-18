import UIKit
import SwiftUI
import AVFoundation
import Vision

// This class sets up the AV (Audio Video) capture session and manages video data output
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var bufferSize : CGSize = .zero
    var rootLayer: CALayer! = nil
    private var previewView = UIView(frame: UIScreen.main.bounds)
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    // DispatchQueue to handle video data output on a background thread to prevent blocking of the UI thread and keep the app responsive
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    
    override func viewDidLoad() {
        // Prevent device from going to sleep
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.addSubview(previewView)
        
        setupAVCapture()
    }
    
    // Capture output delegate method, called for each frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    // Set up the AV capture session and configure the video input and output
    // the session connects the input device with the output view
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Select a video device and create an input, here you can switch between
        // devices. Look at documentation of AVCaptureDevice.DeviceType for options
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        // Begin session configuration
        session.beginConfiguration()
        
        // Add video input to the session
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            
            // Configure video data output settings
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true
        
        do {
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        
        // Commit session configuration
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    // Start the capture session on a background thread
    func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    // Remove the AVCapture preview layer
    func tearDownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    // Convert device orientation to an appropriate exif orientation
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
            // Device oriented vertically, home button on the top
        case UIDeviceOrientation.portraitUpsideDown:
            exifOrientation = .left
            // Device oriented horizontally, home button on the right
        case UIDeviceOrientation.landscapeLeft:
            exifOrientation = .upMirrored
            // Device oriented horizontally, home button on the left
        case UIDeviceOrientation.landscapeRight:
            exifOrientation = .down
            // Device oriented vertically, home button on the bottom
        case UIDeviceOrientation.portrait:
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

// Convert UIKit's UIViewController to a SwiftUI view. For more info, refer to UIViewRepresentable and UIViewControllerRepresentable documentation
struct DetectorViewControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var recognizedObject: RecognizedObject
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = DetectorViewController()
        viewController.recognizedObject = recognizedObject
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}



