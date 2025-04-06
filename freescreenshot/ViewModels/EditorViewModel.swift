//
//  EditorViewModel.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI
import Cocoa

/**
 * EditorViewModel: Manages the state and business logic for the screenshot editor
 */
class EditorViewModel: ObservableObject {
    // Image related properties
    @Published var image: NSImage?
    @Published var originalImage: NSImage?
    @Published var backgroundType: BackgroundType = .none
    @Published var backgroundColor: Color = .white
    @Published var backgroundGradient: Gradient = Gradient(colors: [.blue, .purple])
    @Published var backgroundImage: NSImage?
    @Published var is3DEffect: Bool = false
    @Published var perspective3DDirection: Perspective3DDirection = .bottomRight
    @Published var aspectRatio: AspectRatio = .square
    @Published var imagePadding: CGFloat = 20 // Percentage padding around the image (0-50)
    @Published var cornerRadius: CGFloat = 0 // Corner radius for the screenshot (0-50)
    
    // Editor state
    @Published var currentTool: EditingTool = .select
    @Published var arrowStyle: ArrowStyle = .straight
    @Published var textColor: Color = .black
    @Published var textSize: CGFloat = 16
    @Published var lineWidth: CGFloat = 2
    @Published var highlighterColor: Color = .yellow
    @Published var highlighterOpacity: Double = 0.5
    @Published var selectedElementId: UUID?
    
    // Elements
    @Published var elements: [any EditableElement] = []
    
    // For drag operations
    @Published var isDragging: Bool = false
    @Published var dragStart: CGPoint = .zero
    @Published var dragOffset: CGSize = .zero
    
    /**
     * Sets the image to edit and initializes the editor
     */
    func setImage(_ newImage: NSImage) {
        self.image = newImage
        self.originalImage = newImage
        
        // Set initial aspect ratio based on image dimensions
        let imageRatio = newImage.size.width / newImage.size.height
        
        // Choose the closest aspect ratio
        if abs(imageRatio - 1.0) < 0.1 {
            self.aspectRatio = .square
        } else if abs(imageRatio - (16.0/9.0)) < 0.1 {
            self.aspectRatio = .widescreen
        } else if abs(imageRatio - (9.0/16.0)) < 0.1 {
            self.aspectRatio = .portrait
        } else if abs(imageRatio - (4.0/3.0)) < 0.1 {
            self.aspectRatio = .traditional
        } else if abs(imageRatio - (3.0/4.0)) < 0.1 {
            self.aspectRatio = .traditionalPortrait
        } else if abs(imageRatio - (3.0/2.0)) < 0.1 {
            self.aspectRatio = .photo
        } else if abs(imageRatio - (2.0/3.0)) < 0.1 {
            self.aspectRatio = .photoPortrait
        } else if imageRatio > 1.0 {
            // Default for landscape images
            self.aspectRatio = .widescreen
        } else {
            // Default for portrait images
            self.aspectRatio = .portrait
        }
        
        // Set default padding
        self.imagePadding = 20
        
        // Reset all editing settings
        self.elements = []
        self.selectedElementId = nil
        self.currentTool = .select
        self.backgroundType = .none
        self.backgroundColor = .white
        self.backgroundGradient = Gradient(colors: [.blue, .purple])
        self.backgroundImage = nil
        self.is3DEffect = false
    }
    
    /**
     * Loads an image from file for the editor
     */
    func loadImage(from url: URL) {
        if let image = NSImage(contentsOf: url) {
            setImage(image)
        }
    }
    
    /**
     * Applies the selected background type to the image
     */
    func applyBackground() {
        guard let originalImage = originalImage else { return }
        
        // For non-background operations, just use the original image with corner radius
        if backgroundType == .none {
            // Apply corner radius to the original image if needed
            if cornerRadius > 0 {
                self.image = applyCornerRadius(to: originalImage, radius: cornerRadius)
            } else {
                self.image = originalImage
            }
            return
        }
        
        // Original image dimensions
        let imageSize = originalImage.size
        let aspectRatio = self.aspectRatio.ratio
        
        // Determine the canvas size based on aspect ratio
        var canvasWidth: CGFloat
        var canvasHeight: CGFloat
        
        if aspectRatio >= 1.0 {
            // Landscape or square aspect ratio
            canvasWidth = 1000 // Base width
            canvasHeight = canvasWidth / aspectRatio
        } else {
            // Portrait aspect ratio
            canvasHeight = 1000 // Base height
            canvasWidth = canvasHeight * aspectRatio
        }
        
        let resultSize = CGSize(width: canvasWidth, height: canvasHeight)
        
        // Create a new larger image to draw on for the background
        let resultImage = NSImage(size: resultSize)
        resultImage.lockFocus()
        
        // Clear the canvas first with white
        NSColor.white.setFill()
        NSRect(origin: .zero, size: resultSize).fill()
        
        // Calculate the rectangle to fill with the background
        let backgroundRect = CGRect(origin: .zero, size: resultSize)
        
        // Draw background based on selected type
        switch backgroundType {
        case .solid:
            // Draw solid color background
            NSColor(backgroundColor).set()
            NSBezierPath.fill(backgroundRect)
            
        case .gradient:
            // Draw gradient background
            if let gradientContext = NSGraphicsContext.current?.cgContext {
                let colors = backgroundGradient.stops.map { NSColor($0.color).cgColor }
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let positions = backgroundGradient.stops.map { CGFloat($0.location) }
                
                if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: positions) {
                    gradientContext.drawLinearGradient(
                        gradient,
                        start: CGPoint(x: 0, y: 0),
                        end: CGPoint(x: resultSize.width, y: resultSize.height),
                        options: []
                    )
                }
            }
            
        case .image:
            // Draw background image scaled to fill the background
            if let bgImage = backgroundImage {
                bgImage.draw(in: backgroundRect, from: .zero, operation: .copy, fraction: 1.0)
            }
            
        case .none:
            // No background, use white for a clean slate
            NSColor.white.set()
            NSBezierPath.fill(backgroundRect)
        }
        
        // Calculate where to draw the original image (centered and with padding)
        let imageRatio = imageSize.width / imageSize.height
        let canvasRatio = resultSize.width / resultSize.height
        
        // Calculate available space after padding
        let paddingFactor = min(max(imagePadding, 0), 50) / 100 // Convert percentage to factor (0-0.5)
        let availableWidth = resultSize.width * (1 - paddingFactor * 2)
        let availableHeight = resultSize.height * (1 - paddingFactor * 2)
        
        var drawingSize = imageSize
        var drawingOrigin = CGPoint.zero
        
        if imageRatio > canvasRatio {
            // Image is wider compared to canvas, fit by width
            drawingSize.width = availableWidth
            drawingSize.height = drawingSize.width / imageRatio
        } else {
            // Image is taller compared to canvas, fit by height
            drawingSize.height = availableHeight
            drawingSize.width = drawingSize.height * imageRatio
        }
        
        // Center the image on the canvas
        drawingOrigin.x = (resultSize.width - drawingSize.width) / 2
        drawingOrigin.y = (resultSize.height - drawingSize.height) / 2
        
        let imageRect = CGRect(origin: drawingOrigin, size: drawingSize)
        
        // Draw the image with corner radius - 3D effect will be handled by SwiftUI
        drawImageWithCornerRadius(
            originalImage,
            in: imageRect,
            radius: cornerRadius
        )
        
        resultImage.unlockFocus()
        self.image = resultImage
        objectWillChange.send()
    }
    
    /**
     * Draws an image with optional corner radius
     */
    private func drawImageWithCornerRadius(_ image: NSImage, in rect: CGRect, radius: CGFloat) {
        if radius > 0 {
            let cornerRadiusScaled = min(radius, min(rect.width, rect.height) / 2)
            
            let path = NSBezierPath(roundedRect: NSRect(
                x: rect.origin.x,
                y: rect.origin.y,
                width: rect.width,
                height: rect.height
            ), xRadius: cornerRadiusScaled, yRadius: cornerRadiusScaled)
            
            // Save the current graphics state
            NSGraphicsContext.current?.saveGraphicsState()
            
            // Set the path as clipping path
            path.setClip()
            
            // Draw the image within the clipping path
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            
            // Restore the graphics state
            NSGraphicsContext.current?.restoreGraphicsState()
        } else {
            // Draw without rounded corners
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }
    
    /**
     * Creates a new image with corner radius applied
     */
    private func applyCornerRadius(to image: NSImage, radius: CGFloat) -> NSImage {
        let size = image.size
        let scaledRadius = min(radius, min(size.width, size.height) / 2)
        
        // Create a new image with the same size
        let result = NSImage(size: size)
        
        result.lockFocus()
        
        // Create a rounded rectangle path
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), 
                               xRadius: scaledRadius, yRadius: scaledRadius)
        
        // Set the path as clipping path
        path.setClip()
        
        // Draw the image within the clipping path
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0)
        
        result.unlockFocus()
        
        return result
    }
    
    /**
     * Exports the current image with all applied effects
     */
    func exportImage() -> NSImage? {
        guard let image = image else { return nil }
        
        // For non-3D effects, we can just return the current image
        if !is3DEffect {
            let imageSize = image.size
            let exportImage = NSImage(size: imageSize)
            
            exportImage.lockFocus()
            
            // Draw the base image with background
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            
            // Render all elements on top
            let context = NSGraphicsContext.current
            for element in elements {
                if let textElement = element as? TextElement {
                    let attributedString = NSAttributedString(
                        string: textElement.text,
                        attributes: [
                            .font: NSFont.systemFont(ofSize: textElement.fontSize),
                            .foregroundColor: NSColor(textElement.fontColor)
                        ]
                    )
                    
                    context?.saveGraphicsState()
                    let transform = NSAffineTransform()
                    transform.translateX(by: textElement.position.x, yBy: textElement.position.y)
                    transform.rotate(byRadians: textElement.rotation.radians)
                    transform.scale(by: textElement.scale)
                    transform.concat()
                    
                    let textSize = attributedString.size()
                    attributedString.draw(at: NSPoint(x: -textSize.width / 2, y: -textSize.height / 2))
                    
                    context?.restoreGraphicsState()
                }
                
                // Render other element types as needed
            }
            
            exportImage.unlockFocus()
            return exportImage
        }
        
        // For 3D effect, create a larger canvas to handle the transformation
        let imageSize = image.size
        let exportSize = CGSize(width: imageSize.width * 1.5, height: imageSize.height * 1.5)
        let exportImage = NSImage(size: exportSize)
        
        exportImage.lockFocus()
        
        // Clear background with transparency
        NSColor.clear.set()
        NSRect(origin: .zero, size: exportSize).fill()
        
        // Get perspective transform parameters for the current direction
        let transform = getPerspectiveTransform(for: perspective3DDirection, size: imageSize)
        
        // Center the image on the larger canvas
        let translateX = (exportSize.width - imageSize.width) / 2
        let translateY = (exportSize.height - imageSize.height) / 2
        
        NSGraphicsContext.current?.saveGraphicsState()
        
        // Center the image first
        let affineTransform = NSAffineTransform()
        affineTransform.translateX(by: translateX, yBy: translateY)
        affineTransform.concat()
        
        // Apply shadow for 3D effect
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowOffset = NSSize(width: transform.shadowOffsetX, height: transform.shadowOffsetY)
        shadow.shadowBlurRadius = 20
        shadow.set()
        
        // Apply 3D transform using Core Graphics
        if let context = NSGraphicsContext.current?.cgContext {
            // Create a 3D transform with perspective
            var transform3D = CATransform3DIdentity
            transform3D.m34 = -1.0 / 300.0  // Perspective depth
            
            // Apply rotation based on selected direction
            transform3D = CATransform3DRotate(
                transform3D,
                transform.rotationX,
                1, 0, 0
            )
            transform3D = CATransform3DRotate(
                transform3D,
                transform.rotationY,
                0, 1, 0
            )
            
            // Apply slight scale to enhance the perspective effect
            transform3D = CATransform3DScale(transform3D, 1.1, 1.1, 1.0)
            
            // Apply the 3D transform to the Core Graphics context
            context.concatenate(CATransform3DGetAffineTransform(transform3D))
            
            // Draw the image with the 3D transform applied
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            
            // Draw any additional elements on top
            for element in elements {
                if let textElement = element as? TextElement {
                    let attributedString = NSAttributedString(
                        string: textElement.text,
                        attributes: [
                            .font: NSFont.systemFont(ofSize: textElement.fontSize),
                            .foregroundColor: NSColor(textElement.fontColor)
                        ]
                    )
                    
                    NSGraphicsContext.current?.saveGraphicsState()
                    let elementTransform = NSAffineTransform()
                    elementTransform.translateX(by: textElement.position.x, yBy: textElement.position.y)
                    elementTransform.rotate(byRadians: textElement.rotation.radians)
                    elementTransform.scale(by: textElement.scale)
                    elementTransform.concat()
                    
                    let textSize = attributedString.size()
                    attributedString.draw(at: NSPoint(x: -textSize.width / 2, y: -textSize.height / 2))
                    
                    NSGraphicsContext.current?.restoreGraphicsState()
                }
                
                // Render other element types as needed
            }
        } else {
            // Fallback if context is not available
            image.draw(in: CGRect(origin: CGPoint(x: translateX, y: translateY), size: imageSize))
        }
        
        NSGraphicsContext.current?.restoreGraphicsState()
        
        exportImage.unlockFocus()
        
        // Trim excess transparent areas
        return trimTransparentPadding(exportImage)
    }
    
    /**
     * Helper to get perspective transform parameters based on direction
     */
    private func getPerspectiveTransform(for direction: Perspective3DDirection, size: CGSize) -> (rotationX: CGFloat, rotationY: CGFloat, shadowOffsetX: CGFloat, shadowOffsetY: CGFloat) {
        // Convert degrees to radians - increase from 10 to 15 degrees for more visible effect
        let angleInRadians = CGFloat.pi / 12  // 15 degrees
        
        switch direction {
        case .topLeft:
            return (rotationX: angleInRadians, rotationY: -angleInRadians, shadowOffsetX: -20, shadowOffsetY: 20)
        case .top:
            return (rotationX: angleInRadians, rotationY: 0, shadowOffsetX: 0, shadowOffsetY: 20)
        case .topRight:
            return (rotationX: angleInRadians, rotationY: angleInRadians, shadowOffsetX: 20, shadowOffsetY: 20)
        case .bottomLeft:
            return (rotationX: -angleInRadians, rotationY: -angleInRadians, shadowOffsetX: -20, shadowOffsetY: -20)
        case .bottom:
            return (rotationX: -angleInRadians, rotationY: 0, shadowOffsetX: 0, shadowOffsetY: -20)
        case .bottomRight:
            return (rotationX: -angleInRadians, rotationY: angleInRadians, shadowOffsetX: 20, shadowOffsetY: -20)
        }
    }
    
    /**
     * Trims transparent padding around an image
     */
    private func trimTransparentPadding(_ image: NSImage) -> NSImage {
        guard let bitmap = image.representations.first as? NSBitmapImageRep else {
            return image
        }
        
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        
        // Find bounds of non-transparent pixels
        for y in 0..<height {
            for x in 0..<width {
                let alpha = bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0
                if alpha > 0.05 { // Consider anything barely visible
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // Add small padding
        let padding = 20
        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(width - 1, maxX + padding)
        maxY = min(height - 1, maxY + padding)
        
        // If no non-transparent pixels found, return original
        if minX >= maxX || minY >= maxY {
            return image
        }
        
        let croppedWidth = maxX - minX + 1
        let croppedHeight = maxY - minY + 1
        
        guard let cgImage = bitmap.cgImage else {
            return image
        }
        
        // Crop the image
        if let croppedCGImage = cgImage.cropping(to: CGRect(x: minX, y: height - maxY - 1, width: croppedWidth, height: croppedHeight)) {
            return NSImage(cgImage: croppedCGImage, size: NSSize(width: croppedWidth, height: croppedHeight))
        }
        
        return image
    }
    
    /**
     * Saves the image to a file
     */
    func saveImage(to url: URL) {
        guard let image = exportImage(),
              let data = ImageUtilities.imageToData(image) else {
            return
        }
        
        try? data.write(to: url)
    }
    
    /**
     * Selects an element by ID
     */
    func selectElement(id: UUID?) {
        selectedElementId = id
    }
}

// Extension to convert CGPath to NSBezierPath
extension CGPath {
    func toBezierPath() -> NSBezierPath {
        let path = NSBezierPath()
        var _ = [CGPoint](repeating: .zero, count: 3)
        
        self.applyWithBlock { (elementPtr: UnsafePointer<CGPathElement>) in
            let element = elementPtr.pointee
            
            switch element.type {
            case .moveToPoint:
                let point = element.points[0]
                path.move(to: point)
            case .addLineToPoint:
                let point = element.points[0]
                path.line(to: point)
            case .addQuadCurveToPoint:
                // Convert quadratic curve to cubic curve
                let currentPoint = path.currentPoint
                let point1 = element.points[0]
                let point2 = element.points[1]
                
                path.curve(to: point2,
                           controlPoint1: CGPoint(
                            x: currentPoint.x + 2/3 * (point1.x - currentPoint.x),
                            y: currentPoint.y + 2/3 * (point1.y - currentPoint.y)
                           ),
                           controlPoint2: CGPoint(
                            x: point2.x + 2/3 * (point1.x - point2.x),
                            y: point2.y + 2/3 * (point1.y - point2.y)
                           ))
            case .addCurveToPoint:
                let point1 = element.points[0]
                let point2 = element.points[1]
                let point3 = element.points[2]
                path.curve(to: point3, controlPoint1: point1, controlPoint2: point2)
            case .closeSubpath:
                path.close()
            @unknown default:
                break
            }
        }
        
        return path
    }
}

/**
 * Enum defining perspective 3D viewing angles
 */
enum Perspective3DDirection: String, CaseIterable, Identifiable {
    case topLeft
    case top
    case topRight
    case bottomLeft
    case bottom
    case bottomRight
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .top: return "Top"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottom: return "Bottom"
        case .bottomRight: return "Bottom Right"
        }
    }
}

/**
 * Enum defining common aspect ratios for the canvas
 */
enum AspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case widescreen = "16:9"
    case portrait = "9:16"
    case traditional = "4:3"
    case traditionalPortrait = "3:4"
    case photo = "3:2"
    case photoPortrait = "2:3"
    
    var id: String { self.rawValue }
    
    var ratio: CGFloat {
        switch self {
        case .square: return 1.0
        case .widescreen: return 16.0 / 9.0
        case .portrait: return 9.0 / 16.0
        case .traditional: return 4.0 / 3.0
        case .traditionalPortrait: return 3.0 / 4.0
        case .photo: return 3.0 / 2.0
        case .photoPortrait: return 2.0 / 3.0
        }
    }
    
    var displayName: String { rawValue }
} 