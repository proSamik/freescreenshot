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
        self.elements = []
        self.selectedElementId = nil
        self.currentTool = .select
        self.backgroundType = .none
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
        
        let imageSize = originalImage.size
        let backgroundRect = CGRect(origin: .zero, size: imageSize)
        
        let resultImage = NSImage(size: imageSize)
        
        resultImage.lockFocus()
        
        // Draw background based on selected type
        switch backgroundType {
        case .solid:
            // Draw solid color background
            NSColor(backgroundColor).set()
            backgroundRect.fill()
            
        case .gradient:
            // Draw gradient background
            if let gradientContext = NSGraphicsContext.current?.cgContext {
                let colors = backgroundGradient.stops.map { NSColor($0.color).cgColor }
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let positions = backgroundGradient.stops.map { $0.location }
                
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
                bgImage.draw(in: backgroundRect, from: .zero, operation: .copy, fraction: 1.0)
            }
            
        case .none:
            // No background, just clear
            NSColor.clear.set()
            backgroundRect.fill()
        }
        
        // Apply 3D effect if enabled
        if is3DEffect {
            // Draw with perspective transform
            let perspectiveTransform = NSAffineTransform()
            perspectiveTransform.translateX(by: imageSize.width * 0.1, yBy: imageSize.height * 0.1)
            perspectiveTransform.scale(by: 0.9)
            perspectiveTransform.rotate(byDegrees: -10)
            perspectiveTransform.concat()
            
            // Add shadow
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
            shadow.shadowOffset = NSSize(width: 10, height: 10)
            shadow.shadowBlurRadius = 15
            shadow.set()
        }
        
        // Draw the original image on top
        originalImage.draw(in: backgroundRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        resultImage.unlockFocus()
        self.image = resultImage
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
                
                let size = attributedString.size()
                attributedString.draw(at: CGPoint(x: -size.width / 2, y: -size.height / 2))
                context?.restoreGraphicsState()
            } else if let arrowElement = element as? ArrowElement {
                context?.saveGraphicsState()
                let transform = NSAffineTransform()
                transform.translateX(by: arrowElement.position.x, yBy: arrowElement.position.y)
                transform.rotate(byRadians: arrowElement.rotation.radians)
                transform.scale(by: arrowElement.scale)
                transform.concat()
                
                NSColor(arrowElement.color).set()
                let bezierPath = NSBezierPath()
                
                let arrow = ArrowShape(
                    start: arrowElement.startPoint,
                    end: arrowElement.endPoint,
                    style: arrowElement.style
                ).path(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
                
                let cgPath = arrow.cgPath
                bezierPath.append(cgPath.toBezierPath())
                bezierPath.lineWidth = arrowElement.strokeWidth
                bezierPath.stroke()
                
                context?.restoreGraphicsState()
            }
            // Additional elements would be rendered here with similar pattern
        }
        
        exportImage.unlockFocus()
        return exportImage
    }
    
    /**
     * Saves the current image to a file
     */
    func saveImage(to url: URL, type: NSBitmapImageRep.FileType = .png) -> Bool {
        guard let exportedImage = exportImage(),
              let tiffData = exportedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return false
        }
        
        guard let imageData = bitmap.representation(using: type, properties: [:]) else {
            return false
        }
        
        do {
            try imageData.write(to: url)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
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