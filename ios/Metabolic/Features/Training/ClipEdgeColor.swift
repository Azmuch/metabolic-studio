import AVFoundation
import UIKit

/// Samples the average color of a clip's bottom edge (first frame, central 80% of the width) so
/// the screen region below a top-pinned 9:16 hero card can continue the clip's studio floor
/// without a visible seam. The accent-tinted scrim renders on top, so the sampled color stays
/// valid across every UI theme; results are cached per URL for the app's lifetime.
@MainActor
enum ClipEdgeColor {
    private static var cache: [URL: UIColor] = [:]

    static func sample(url: URL) async -> UIColor? {
        if let cached = cache[url] { return cached }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        guard let result = try? await generator.image(at: .zero),
              let color = averageBottomColor(of: result.image) else { return nil }
        cache[url] = color
        return color
    }

    /// Average of the bottom ~3% rows, corners inset in case the clip vignettes. Drawing the
    /// crop into a 1×1 context lets CoreGraphics do the averaging.
    private static func averageBottomColor(of image: CGImage) -> UIColor? {
        let width = image.width, height = image.height
        guard width > 0, height > 0 else { return nil }
        let sampleHeight = max(height / 33, 1)
        let insetX = width / 10
        let rect = CGRect(x: insetX, y: height - sampleHeight,
                          width: width - insetX * 2, height: sampleHeight)
        guard let cropped = image.cropping(to: rect),
              let context = CGContext(
                data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.interpolationQuality = .medium
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let data = context.data else { return nil }
        let p = data.bindMemory(to: UInt8.self, capacity: 4)
        return UIColor(red: CGFloat(p[0]) / 255, green: CGFloat(p[1]) / 255,
                       blue: CGFloat(p[2]) / 255, alpha: 1)
    }
}
