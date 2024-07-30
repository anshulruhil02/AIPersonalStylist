import Vision
import UIKit

class FaceAnalyzer {
    func detectFace(in image: UIImage, completion: @escaping (UIColor?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let faceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if let results = request.results as? [VNFaceObservation], let firstFace = results.first {
                self.extractFaceColor(from: image, boundingBox: firstFace.boundingBox, completion: completion)
            } else {
                completion(nil)
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([faceRequest])
    }
    
    private func extractFaceColor(from image: UIImage, boundingBox: CGRect, completion: @escaping (UIColor?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let boundingBoxInImageCoords = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
        
        guard let faceCgImage = cgImage.cropping(to: boundingBoxInImageCoords) else {
            completion(nil)
            return
        }
        
        let faceUIImage = UIImage(cgImage: faceCgImage)
        completion(dominantColor(from: faceUIImage))
    }
    
    private func dominantColor(from image: UIImage) -> UIColor {
        guard let inputImage = CIImage(image: image) else { return .black }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return .black }
        guard let outputImage = filter.outputImage else { return .black }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}
