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
        
        let imageSize = originalImage.size
        let backgroundRect = CGRect(origin: .zero, size: imageSize)
        
        // Create a new image to draw on
        let resultImage = NSImage(size: imageSize)
        resultImage.lockFocus()
        
        // Clear the canvas first
        NSColor.clear.setFill()
        NSBezierPath.fill(backgroundRect)
        
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
                        end: CGPoint(x: imageSize.width, y: imageSize.height),
                        options: []
                    )
                }
            }
            
        case .image:
            // Draw background image
            if let bgImage = backgroundImage {
                // Scale background image to fill the area
                let bgSize = bgImage.size
                let xScale = imageSize.width / bgSize.width
                let yScale = imageSize.height / bgSize.height
                let scale = max(xScale, yScale) // Use max to ensure image fills the area
                
                let scaledWidth = bgSize.width * scale
                let scaledHeight = bgSize.height * scale
                
                // Center the background image
                let xOffset = (imageSize.width - scaledWidth) / 2
                let yOffset = (imageSize.height - scaledHeight) / 2
                
                let destRect = NSRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)
                bgImage.draw(in: destRect, from: .zero, operation: .copy, fraction: 1.0)
            }
            
        case .none:
            // No background, use white for a clean slate
            NSColor.white.set()
            NSBezierPath.fill(backgroundRect)
        }
        
        // CRITICAL: Apply the 3D effect BEFORE drawing the image content if needed
        if is3DEffect {
            // Get the screenshot with transparent areas preserved
            let screenshotWithTransparency = removeWhiteBackground(from: originalImage)
            
            // Draw the screenshot on top of the background
            screenshotWithTransparency.draw(in: backgroundRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            resultImage.unlockFocus()
            
            // Convert the result to a 3D image
            guard let perspectiveImage = ImageUtilities.apply3DEffect(to: resultImage, intensity: 0.2) else {
                // If 3D effect fails, use the non-3D result
                self.image = resultImage
                objectWillChange.send()
                return
            }
            
            // Use the 3D transformed image as our result
            self.image = perspectiveImage
            objectWillChange.send()
            return
        }
        
        // For 2D rendering, create a screenshot with transparent areas
        let screenshotWithTransparency = removeWhiteBackground(from: originalImage)
        
        // Draw the screenshot on top of the background
        screenshotWithTransparency.draw(in: backgroundRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        resultImage.unlockFocus()
        
        // Update the main image and force a UI update
        self.image = resultImage
        objectWillChange.send()
    }
    
    /**
     * Removes the white/light background from an image to allow transparency
     */
    private func removeWhiteBackground(from image: NSImage) -> NSImage {
        let size = image.size
        let result = NSImage(size: size)
        
        // Get the bitmap representation of the image
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return image
        }
        
        // Create an image with RGBA components
        result.lockFocus()
        
        // Get bitmap data
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        
        // Draw the image but preserve transparency
        if let ctx = NSGraphicsContext.current?.cgContext {
            if let cgImage = bitmap.cgImage {
                ctx.draw(cgImage, in: CGRect(origin: .zero, size: size))
            }
        }
        
        result.unlockFocus()
        return result
    }
    
    /**
     * Adds a text element at the specified position
     */
    func addText(at position: CGPoint, text: String = "Text") {
        let textElement = TextElement(
            position: position,
            text: text,
            fontSize: textSize,
            fontColor: textColor
        )
        elements.append(textElement)
        selectedElementId = textElement.id
    }
    
    /**
     * Adds an arrow element from start to end point
     */
    func addArrow(from startPoint: CGPoint, to endPoint: CGPoint) {
        let midPoint = CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: (startPoint.y + endPoint.y) / 2
        )
        
        let arrowElement = ArrowElement(
            position: midPoint,
            startPoint: CGPoint(
                x: startPoint.x - midPoint.x,
                y: startPoint.y - midPoint.y
            ),
            endPoint: CGPoint(
                x: endPoint.x - midPoint.x,
                y: endPoint.y - midPoint.y
            ),
            style: arrowStyle,
            strokeWidth: lineWidth,
            color: textColor
        )
        
        elements.append(arrowElement)
        selectedElementId = arrowElement.id
    }
    
    /**
     * Adds a highlighter element at the specified points
     */
    func addHighlighter(points: [CGPoint]) {
        guard !points.isEmpty else { return }
        
        // Calculate center of the points
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let centerX = sumX / CGFloat(points.count)
        let centerY = sumY / CGFloat(points.count)
        let centerPoint = CGPoint(x: centerX, y: centerY)
        
        // Adjust points relative to the center
        let adjustedPoints = points.map { CGPoint(x: $0.x - centerX, y: $0.y - centerY) }
        
        let highlighter = HighlighterElement(
            position: centerPoint,
            points: adjustedPoints,
            color: highlighterColor,
            opacity: highlighterOpacity,
            lineWidth: lineWidth * 5
        )
        
        elements.append(highlighter)
        selectedElementId = highlighter.id
    }
    
    /**
     * Adds a box shadow element at the specified rect
     */
    func addBoxShadow(rect: CGRect) {
        let boxShadow = BoxShadowElement(
            position: CGPoint(x: rect.midX, y: rect.midY),
            rect: CGRect(
                x: -rect.width / 2,
                y: -rect.height / 2,
                width: rect.width,
                height: rect.height
            )
        )
        
        elements.append(boxShadow)
        selectedElementId = boxShadow.id
    }
    
    /**
     * Adds a glass effect element at the specified rect
     */
    func addGlassEffect(rect: CGRect) {
        let glassEffect = GlassEffectElement(
            position: CGPoint(x: rect.midX, y: rect.midY),
            rect: CGRect(
                x: -rect.width / 2,
                y: -rect.height / 2,
                width: rect.width,
                height: rect.height
            )
        )
        
        elements.append(glassEffect)
        selectedElementId = glassEffect.id
    }
    
    /**
     * Removes the currently selected element
     */
    func removeSelectedElement() {
        guard let selectedId = selectedElementId else { return }
        elements.removeAll { 
            if let element = $0 as? TextElement { return element.id == selectedId }
            if let element = $0 as? ArrowElement { return element.id == selectedId }
            if let element = $0 as? HighlighterElement { return element.id == selectedId }
            if let element = $0 as? BoxShadowElement { return element.id == selectedId }
            if let element = $0 as? GlassEffectElement { return element.id == selectedId }
            return false
        }
        selectedElementId = nil
    }
    
    /**
     * Begins dragging the selected element
     */
    func startDrag(at position: CGPoint) {
        isDragging = true
        dragStart = position
        dragOffset = .zero
    }
    
    /**
     * Updates the position of the dragged element
     */
    func updateDrag(to position: CGPoint) {
        guard isDragging else { return }
        dragOffset = CGSize(
            width: position.x - dragStart.x,
            height: position.y - dragStart.y
        )
        
        // Update position of the selected element
        guard let selectedId = selectedElementId else { return }
        for i in 0..<elements.count {
            var element = elements[i]
            if element.id == selectedId {
                var newPosition = element.position
                newPosition.x += dragOffset.width
                newPosition.y += dragOffset.height
                element.position = newPosition
                elements[i] = element
                break
            }
        }
        
        // Reset for next drag update
        dragStart = position
    }
    
    /**
     * Ends dragging the selected element
     */
    func endDrag() {
        isDragging = false
        dragOffset = .zero
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