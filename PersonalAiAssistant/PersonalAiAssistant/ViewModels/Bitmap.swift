import UIKit

class Bitmap {
    private let context: CGContext
    private let width: Int
    private let height: Int
    
    init(image: CGImage) {
        self.width = image.width
        self.height = image.height
        
        self.context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        self.context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    func predominantColor() -> UIColor {
        let pixelData = context.data!.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        var colorCount: [UInt32: Int] = [:]
        
        for x in 0..<width {
            for y in 0..<height {
                let offset = 4 * (y * width + x)
                
                let r = pixelData[offset]
                let g = pixelData[offset + 1]
                let b = pixelData[offset + 2]
                
                let color = (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
                colorCount[color, default: 0] += 1
            }
        }
        
        let predominantColor = colorCount.max { $0.value < $1.value }?.key ?? 0
        
        let r = CGFloat((predominantColor >> 16) & 0xFF) / 255.0
        let g = CGFloat((predominantColor >> 8) & 0xFF) / 255.0
        let b = CGFloat(predominantColor & 0xFF) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
