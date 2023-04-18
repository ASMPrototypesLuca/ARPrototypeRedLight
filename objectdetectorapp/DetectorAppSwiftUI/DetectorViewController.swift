import Vision
import AVFoundation
import UIKit

// DetectorViewController inherits from ViewController and is responsible for detecting objects in a video stream
// using a Core ML model.
class DetectorViewController: ViewController {
    
    var recognizedObject: RecognizedObject?
    
    // CALayer that will store the visualizations of detected objects
    private var detectionOverlay: CALayer! = nil
    
    // Array of VNRequest objects to perform image analysis tasks
    private var requests = [VNRequest]()
    
    // Sets up the Vision framework to use the provided Core ML model for object detection.
    // Returns an NSError object if there's an issue setting up Vision, otherwise returns nil.
    @discardableResult
    func setupVision() -> NSError? {
        let error: NSError! = nil
        
        // Get a reference to the model file. Change the string name here if you want to change the model.
        guard let modelURL = Bundle.main.url(forResource: "RedTrafficLightDetector 1", withExtension: "mlmodelc") else {
            return NSError(domain: "DetectorViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        
        do {
            // Load the model
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            // Instantiate the image analysis request with a completion handler that processes the results
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { request, error in
                // Process the recognition results and draw them on the UI in the main thread
                DispatchQueue.main.async(execute: {
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    // Draws the results of the object recognition request on the detectionOverlay layer
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil //remove all the old recognized objects
        self.recognizedObject?.recognized = false
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence
            let topLabelObservation = objectObservation.labels[0]
            // Print the result to the console for debugging purposes
            print("Top results: \(topLabelObservation.identifier) with confidence: \(topLabelObservation.confidence)")
            
            // Update the recognizedObject instance
            recognizedObject?.recognized = true
            recognizedObject?.objectName = topLabelObservation.identifier
            recognizedObject?.confidence = Double(topLabelObservation.confidence.magnitude)
            
            // Match the view and image coordinate systems
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            // Draw the bounding box on the screen
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            detectionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }

    
    // This method is called every time a new frame of the video is recorded
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        // Perform image analysis on the current frame using the requests array
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    // Set up AVCapture, detectionOverlay layer, and Vision framework, and then start the capture session
    override func setupAVCapture() {
        super.setupAVCapture()
        
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        startCaptureSession()
    }
    
    // Initializes the detectionOverlay layer and adds it to the rootLayer
    func setupLayers() {
        detectionOverlay = CALayer()
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    // Updates the geometry of the detectionOverlay layer to match the rootLayer's bounds
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // Rotate, scale, and mirror the detectionOverlay layer to match the screen orientation
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // Center the detectionOverlay layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
    }
    
    // Creates a rounded rectangle layer with the specified bounds, which will be used as the bounding box for detected objects
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let boxLayer = CAShapeLayer()
        boxLayer.bounds = bounds
        boxLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        boxLayer.cornerRadius = 15.0
        boxLayer.borderWidth = 20.0
        
        boxLayer.borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 0.2, 0.6, 0.9])

        
        return boxLayer
    }
}

