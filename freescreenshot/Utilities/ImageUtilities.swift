//
//  ImageUtilities.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI
import Cocoa
import UniformTypeIdentifiers

/**
 * ImageUtilities: Contains utility functions for image processing
 */
class ImageUtilities {
    /**
     * Loads an image from the clipboard if available
     * Returns nil if no valid image is in the clipboard
     */
    static func loadImageFromClipboard() -> NSImage? {
        let pasteboard = NSPasteboard.general
        if let items = pasteboard.readObjects(forClasses: [NSImage.self], options: nil),
           let image = items.first as? NSImage {
            return image
        }
        return nil
    }
    
    /**
     * Saves an image to the clipboard
     */
    static func saveImageToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    /**
     * Applies a 3D perspective transform to an image
     */
    static func apply3DEffect(to image: NSImage, intensity: CGFloat = 0.2) -> NSImage? {
        let imageSize = image.size
        let resultImage = NSImage(size: CGSize(width: imageSize.width * 1.2, height: imageSize.height * 1.2))
        
        resultImage.lockFocus()
        
        // Create shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowOffset = NSSize(width: 20, height: 20)
        shadow.shadowBlurRadius = 15
        shadow.set()
        
        // Apply perspective transform
        let transform = NSAffineTransform()
        transform.translateX(by: imageSize.width * 0.1, yBy: imageSize.height * 0.1)
        
        // Perspective transform (pseudo-3D effect)
        transform.concat()
        
        // Draw the image with the transform
        let path = NSBezierPath(rect: CGRect(origin: .zero, size: imageSize))
        
        // Create perspective effect by adjusting corners
        path.removeAllPoints()
        
        // Top-left, slightly moved
        path.move(to: NSPoint(x: 0, y: imageSize.height))
        
        // Top-right, moved further in (perspective)
        path.line(to: NSPoint(x: imageSize.width, y: imageSize.height - imageSize.height * intensity * 0.5))
        
        // Bottom-right, moved further in (perspective)
        path.line(to: NSPoint(x: imageSize.width - imageSize.width * intensity * 0.2, y: 0))
        
        // Bottom-left
        path.line(to: NSPoint(x: imageSize.width * intensity * 0.2, y: imageSize.height * intensity * 0.2))
        
        path.close()
        
        // Clip to this perspective shape
        path.setClip()
        
        // Draw the image
        image.draw(in: CGRect(origin: .zero, size: imageSize), from: .zero, operation: .sourceOver, fraction: 1.0)
        
        resultImage.unlockFocus()
        
        return resultImage
    }
    
    /**
     * Converts image to data for saving
     */
    static func imageToData(_ image: NSImage, format: NSBitmapImageRep.FileType = .png) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: format, properties: [:])
    }
}

/**
 * Extension to add UTType conformance for file operations
 */
extension UTType {
    static let png = UTType(filenameExtension: "png")!
    static let jpeg = UTType(filenameExtension: "jpeg")!
    static let jpg = UTType(filenameExtension: "jpg")!
    static let tiff = UTType(filenameExtension: "tiff")!
    static let gif = UTType(filenameExtension: "gif")!
    static let bmp = UTType(filenameExtension: "bmp")!
} 