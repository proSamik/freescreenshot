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
        
        // Clear the canvas first with white/transparent background
        if backgroundType == .none {
            NSColor.white.setFill()
        } else {
            NSColor.clear.setFill()
        }
        NSRect(origin: .zero, size: resultSize).fill()
        
        // Calculate the rectangle to fill with the background
        let backgroundRect = CGRect(origin: .zero, size: resultSize)
        
        // Draw background based on selected type
        switch backgroundType {
        case .solid:
            // Draw solid color background
            NSColor(backgroundColor).setFill()
            NSRect(origin: .zero, size: resultSize).fill()
            
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
            // No background, just white canvas
            NSColor.white.setFill()
            NSRect(origin: .zero, size: resultSize).fill()
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
        
        // Important: We don't apply 3D effects here - they'll be handled by SwiftUI
        // Only draw the image with corner radius if needed
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
        guard let originalImage = originalImage else { return nil }
        
        // For non-3D effects, we can just return the current image
        if !is3DEffect {
            return image
        }
        
        // For 3D effect, we need to completely rebuild the image
        
        // 1. Get the proper image size based on aspect ratio - increase base resolution for higher quality
        var canvasWidth: CGFloat
        var canvasHeight: CGFloat
        
        if aspectRatio.ratio >= 1.0 {
            // Landscape or square aspect ratio
            canvasWidth = 2000 // Doubled base width for better quality
            canvasHeight = canvasWidth / aspectRatio.ratio
        } else {
            // Portrait aspect ratio
            canvasHeight = 2000 // Doubled base height for better quality
            canvasWidth = canvasHeight * aspectRatio.ratio
        }
        
        let baseSize = CGSize(width: canvasWidth, height: canvasHeight)
        
        // 2. Create a larger canvas to accommodate the 3D transformation
        let exportSize = CGSize(width: baseSize.width * 1.8, height: baseSize.height * 1.8)
        let exportImage = NSImage(size: exportSize)
        
        // Enable high quality rendering
        exportImage.lockFocusFlipped(false)
        
        // Enable higher quality image interpolation
        if let context = NSGraphicsContext.current {
            context.imageInterpolation = .high
            context.shouldAntialias = true
            context.compositingOperation = .copy
        }
        
        // 3. Clear background
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: exportSize).fill()
        
        // 4. Calculate the translation to center everything
        let translateX = (exportSize.width - baseSize.width) / 2
        let translateY = (exportSize.height - baseSize.height) / 2
        
        // 5. First draw ONLY the background without the screenshot
        if backgroundType != .none {
            // Create a canvas just for the background
            let bgImage = NSImage(size: baseSize)
            bgImage.lockFocusFlipped(false)
            
            // Set high quality for background rendering
            if let context = NSGraphicsContext.current {
                context.imageInterpolation = .high
                context.shouldAntialias = true
            }
            
            // Clear first
            NSColor.clear.setFill()
            NSRect(origin: .zero, size: baseSize).fill()
            
            // Draw background based on selected type
            switch backgroundType {
            case .solid:
                NSColor(backgroundColor).setFill()
                NSRect(origin: .zero, size: baseSize).fill()
                
            case .gradient:
                if let gradientContext = NSGraphicsContext.current?.cgContext {
                    let colors = backgroundGradient.stops.map { NSColor($0.color).cgColor }
                    let colorSpace = CGColorSpaceCreateDeviceRGB()
                    let positions = backgroundGradient.stops.map { CGFloat($0.location) }
                    
                    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: positions) {
                        gradientContext.drawLinearGradient(
                            gradient,
                            start: CGPoint(x: 0, y: 0),
                            end: CGPoint(x: baseSize.width, y: baseSize.height),
                            options: []
                        )
                    }
                }
                
            case .image:
                if let bgImage = backgroundImage {
                    // Draw background image at high quality
                    let drawRect = CGRect(origin: .zero, size: baseSize)
                    bgImage.draw(in: drawRect, from: .zero, operation: .copy, fraction: 1.0, respectFlipped: true, hints: [
                        NSImageRep.HintKey.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)
                    ])
                }
                
            case .none:
                break
            }
            
            bgImage.unlockFocus()
            
            // Draw the background at the center without any transformation - high quality
            bgImage.draw(in: CGRect(x: translateX, y: translateY, width: baseSize.width, height: baseSize.height),
                         from: .zero,
                         operation: .copy,
                         fraction: 1.0,
                         respectFlipped: true,
                         hints: [NSImageRep.HintKey.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)])
        }
        
        // 6. Calculate the padding for the screenshot content
        let paddingFactor = min(max(imagePadding, 0), 50) / 100 // Convert percentage to factor (0-0.5)
        
        // Add extra padding for 3D effect to ensure it stays within bounds
        let extraPadding = 0.1 // Additional 10% padding for 3D effect
        let paddingX = baseSize.width * (paddingFactor + extraPadding)
        let paddingY = baseSize.height * (paddingFactor + extraPadding)
        
        let contentRect = CGRect(
            x: paddingX,
            y: paddingY,
            width: baseSize.width - (paddingX * 2),
            height: baseSize.height - (paddingY * 2)
        )
        
        // 7. Create an image with ONLY the screenshot content (no background) at high quality
        let screenshotImage = NSImage(size: baseSize)
        screenshotImage.lockFocusFlipped(false)
        
        // Set high quality rendering for the screenshot
        if let context = NSGraphicsContext.current {
            context.imageInterpolation = .high
            context.shouldAntialias = true
        }
        
        // Clear to transparent
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: baseSize).fill()
        
        // Draw the screenshot with corner radius if needed
        if cornerRadius > 0 {
            let path = NSBezierPath(roundedRect: contentRect, xRadius: cornerRadius, yRadius: cornerRadius)
            path.lineWidth = 0 // Ensure no border is drawn
            NSGraphicsContext.current?.saveGraphicsState()
            path.setClip()
            
            // Draw original image at high quality
            originalImage.draw(in: contentRect,
                              from: .zero,
                              operation: .copy,
                              fraction: 1.0,
                              respectFlipped: true,
                              hints: [NSImageRep.HintKey.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)])
            
            NSGraphicsContext.current?.restoreGraphicsState()
        } else {
            // Just draw the content at high quality
            originalImage.draw(in: contentRect,
                              from: .zero,
                              operation: .copy,
                              fraction: 1.0,
                              respectFlipped: true,
                              hints: [NSImageRep.HintKey.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)])
        }
        
        screenshotImage.unlockFocus()
        
        // 8. Add the 3D transformed screenshot
        NSGraphicsContext.current?.saveGraphicsState()
        
        // Get perspective transform parameters
        let transform = getPerspectiveTransform(for: perspective3DDirection, size: baseSize)
        
        // Softer shadow for cleaner look
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowOffset = NSSize(width: transform.shadowOffsetX, height: transform.shadowOffsetY)
        shadow.shadowBlurRadius = 15
        shadow.set()
        
        // Apply 3D transform to the screenshot
        if let context = NSGraphicsContext.current?.cgContext {
            // Create a 3D transform
            var transform3D = CATransform3DIdentity
            transform3D.m34 = -1.0 / 800.0  // Less aggressive perspective for cleaner rendering
            
            // Apply rotation based on direction
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
            
            // Scale slightly less to ensure content stays within bounds
            transform3D = CATransform3DScale(transform3D, 1.05, 1.05, 1.0)
            
            // Apply 3D transform to context
            context.saveGState()
            context.setShouldAntialias(true)
            context.setAllowsAntialiasing(true)
            context.interpolationQuality = .high
            
            context.translateBy(x: translateX, y: translateY)
            context.concatenate(CATransform3DGetAffineTransform(transform3D))
            
            // Draw the screenshot with 3D effect at high quality
            screenshotImage.draw(in: CGRect(origin: .zero, size: baseSize),
                                from: .zero,
                                operation: .copy,
                                fraction: 1.0,
                                respectFlipped: true,
                                hints: [NSImageRep.HintKey.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)])
            
            context.restoreGState()
        }
        
        NSGraphicsContext.current?.restoreGraphicsState()
        
        exportImage.unlockFocus()
        
        // Trim excess transparent areas
        return trimTransparentPadding(exportImage)
    }
    
    /**
     * Draw background in the specified rectangle
     */
    private func drawBackground(in rect: NSRect) {
        // Clear the background first
        NSColor.clear.setFill()
        rect.fill()
        
        switch backgroundType {
        case .solid:
            // Draw solid color background
            NSColor(backgroundColor).setFill()
            rect.fill()
            
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
                        end: CGPoint(x: rect.width, y: rect.height),
                        options: []
                    )
                }
            }
            
        case .image:
            // Draw background image scaled to fill
            if let bgImage = backgroundImage {
                bgImage.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
            }
            
        case .none:
            // No background
            break
        }
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