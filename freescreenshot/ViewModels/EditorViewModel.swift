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
        
        // For non-background operations, just use the original image
        if backgroundType == .none {
            self.image = originalImage
            return
        }
        
        // Original image dimensions
        let imageSize = originalImage.size
        
        // Add padding around the image for the background (20% on each side)
        let padding = min(imageSize.width, imageSize.height) * 0.2
        let resultSize = CGSize(
            width: imageSize.width + padding * 2,
            height: imageSize.height + padding * 2
        )
        
        // Create a new larger image to draw on
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
        
        // Calculate where to draw the original image (centered)
        let imageRect = CGRect(
            x: padding,
            y: padding,
            width: imageSize.width,
            height: imageSize.height
        )
        
        // Draw the original image on top of the background
        originalImage.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        resultImage.unlockFocus()
        
        // If 3D effect is enabled, apply it to the combined image
        if is3DEffect {
            guard let perspectiveImage = ImageUtilities.apply3DEffect(to: resultImage, intensity: 0.2) else {
                self.image = resultImage
                objectWillChange.send()
                return
            }
            
            self.image = perspectiveImage
        } else {
            self.image = resultImage
        }
        
        objectWillChange.send()
    }
    
    /**
     * Exports the current image with all applied effects
     */
    func exportImage() -> NSImage? {
        guard let image = image else { return nil }
        
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