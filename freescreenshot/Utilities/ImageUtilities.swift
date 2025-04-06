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
        // Create a larger result image to accommodate the transformed content
        let imageSize = image.size
        let padding = CGFloat(100) // Increase padding to prevent clipping
        let resultSize = CGSize(width: imageSize.width + padding*2, height: imageSize.height + padding*2)
        let resultImage = NSImage(size: resultSize)
        
        resultImage.lockFocus()
        
        // Clear the background
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: resultSize).fill()
        
        // Create shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowOffset = NSSize(width: 20, height: 20)
        shadow.shadowBlurRadius = 15
        shadow.set()
        
        // Center the transform
        let transform = NSAffineTransform()
        transform.translateX(by: padding, yBy: padding)
        transform.concat()
        
        // Draw the image with perspective effect
        let path = NSBezierPath()
        
        // Define the perspective corners with less extreme values to avoid truncation
        // Top-left
        path.move(to: NSPoint(x: 0, y: imageSize.height))
        
        // Top-right - reduce the perspective effect to prevent truncation
        path.line(to: NSPoint(x: imageSize.width, y: imageSize.height - imageSize.height * intensity * 0.2))
        
        // Bottom-right
        path.line(to: NSPoint(x: imageSize.width, y: 0))
        
        // Bottom-left
        path.line(to: NSPoint(x: 0, y: 0))
        
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