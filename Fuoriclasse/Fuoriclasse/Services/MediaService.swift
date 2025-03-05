import SwiftUI

struct MediaService {
    // MARK: - iOS & Mac Catalyst
    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Convertit un `UIImage` en `Data` (JPEG compressé).
    static func convertImageToData(_ image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.7)
    }
    
    /// Convertit un `Data` (JPEG/PNG) en `UIImage`.
    static func dataToImage(_ data: Data) -> UIImage? {
        UIImage(data: data)
    }
    // MARK: - macOS (AppKit)
    #elseif os(macOS)
    /// Convertit un `NSImage` en `Data` JPEG.
    static func convertImageToData(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .jpeg, properties: [:])
    }

    /// Convertit un `Data` (JPEG/PNG) en `NSImage`.
    static func dataToImage(_ data: Data) -> NSImage? {
        NSImage(data: data)
    }
    #endif
}
