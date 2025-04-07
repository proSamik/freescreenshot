//
//  EditorModels.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI

/**
 * EditingTool: Represents the various editing tools available in the editor
 */
enum EditingTool: String, CaseIterable, Identifiable {
    case select
    case arrow
    case text
    case highlighter
    case boxShadow
    case glassEffect
    
    var id: String { self.rawValue }
    
    /**
     * Returns the icon name for the tool
     */
    var iconName: String {
        switch self {
        case .select: return "arrow.up.left.and.arrow.down.right"
        case .arrow: return "arrow.up.right"
        case .text: return "textformat"
        case .highlighter: return "highlighter"
        case .boxShadow: return "rectangle.fill"
        case .glassEffect: return "circle.dotted"
        }
    }
    
    /**
     * Returns the display name for the tool
     */
    var displayName: String {
        switch self {
        case .select: return "Select"
        case .arrow: return "Arrow"
        case .text: return "Text"
        case .highlighter: return "Highlight"
        case .boxShadow: return "Box Shadow"
        case .glassEffect: return "Glass Effect"
        }
    }
}

/**
 * ArrowStyle: Represents the styles available for arrows
 */
enum ArrowStyle: String, CaseIterable, Identifiable {
    case straight
    case curved
    case spiral
    case bent
    
    var id: String { self.rawValue }
}

/**
 * BackgroundType: Represents the types of backgrounds that can be applied
 */
enum BackgroundType: String, CaseIterable, Identifiable {
    case solid
    case gradient
    case image
    case device
    case none
    
    var id: String { self.rawValue }
    
    /**
     * Returns the display name for the background type
     */
    var displayName: String {
        switch self {
        case .solid: return "Solid Color"
        case .gradient: return "Gradient"
        case .image: return "Image"
        case .device: return "Device Mockup"
        case .none: return "None"
        }
    }
}

/**
 * DeviceType: Represents the device mockup types
 */
enum DeviceType: String, CaseIterable, Identifiable {
    case iphone
    case macbook
    case macbookWithIphone
    
    var id: String { self.rawValue }
    
    /**
     * Returns the display name for the device type
     */
    var displayName: String {
        switch self {
        case .iphone: return "iPhone"
        case .macbook: return "MacBook"
        case .macbookWithIphone: return "MacBook + iPhone"
        }
    }
    
    /**
     * Returns the path to the device mockup image
     */
    var imagePath: String {
        switch self {
        case .iphone: return "DeviceMockups/iphone"
        case .macbook: return "DeviceMockups/macbook"
        case .macbookWithIphone: return "DeviceMockups/macbookwithiphone"
        }
    }
    
    /**
     * Returns the mockup image from the app bundle
     */
    var mockupImage: NSImage? {
        // Simple, reliable approach that works with the app bundle
        return NSImage(named: self.rawValue)
    }
    
    /**
     * Returns the screen content area rectangle within the mockup image (normalized 0-1 coordinates)
     */
    var screenArea: CGRect {
        switch self {
        case .iphone:
            return CGRect(x: 0.028, y: 0.054, width: 0.945, height: 0.892)
        case .macbook:
            return CGRect(x: 0.134, y: 0.116, width: 0.732, height: 0.498)
        case .macbookWithIphone:
            // This is the MacBook screen area within the combo mockup
            return CGRect(x: 0.13, y: 0.14, width: 0.69, height: 0.45)
        }
    }
    
    /**
     * Returns the secondary screen area for the macbookWithIphone case (iPhone screen)
     */
    var secondaryScreenArea: CGRect? {
        switch self {
        case .macbookWithIphone:
            return CGRect(x: 0.83, y: 0.38, width: 0.12, height: 0.25)
        default:
            return nil
        }
    }
}

/**
 * EditableElement: Base protocol for all editable elements in the editor
 */
protocol EditableElement: Identifiable {
    var id: UUID { get }
    var position: CGPoint { get set }
    var rotation: Angle { get set }
    var scale: CGFloat { get set }
    
    associatedtype ViewType: View
    func render() -> ViewType
}

/**
 * TextElement: Represents a text annotation in the editor
 */
struct TextElement: EditableElement {
    var id = UUID()
    var position: CGPoint
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var text: String
    var fontSize: CGFloat = 16
    var fontColor: Color = .black
    var fontWeight: Font.Weight = .regular
    var fontStyle: Font.Design = .default
    
    /**
     * Renders the text element in the editor
     */
    func render() -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight, design: fontStyle))
            .foregroundColor(fontColor)
            .position(position)
            .rotationEffect(rotation)
            .scaleEffect(scale)
    }
}

/**
 * ArrowElement: Represents an arrow annotation in the editor
 */
struct ArrowElement: EditableElement {
    var id = UUID()
    var position: CGPoint
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var startPoint: CGPoint
    var endPoint: CGPoint
    var style: ArrowStyle = .straight
    var strokeWidth: CGFloat = 2
    var color: Color = .black
    
    /**
     * Renders the arrow element in the editor
     */
    func render() -> some View {
        ArrowShape(start: startPoint, end: endPoint, style: style)
            .stroke(color, lineWidth: strokeWidth)
            .position(position)
            .rotationEffect(rotation)
            .scaleEffect(scale)
    }
}

/**
 * HighlighterElement: Represents a highlighter annotation in the editor
 */
struct HighlighterElement: EditableElement {
    var id = UUID()
    var position: CGPoint
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var points: [CGPoint]
    var color: Color = .yellow
    var opacity: Double = 0.5
    var lineWidth: CGFloat = 10
    
    /**
     * Renders the highlighter element in the editor
     */
    func render() -> some View {
        Path { path in
            guard let firstPoint = points.first else { return }
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(color.opacity(opacity), lineWidth: lineWidth)
        .position(position)
        .rotationEffect(rotation)
        .scaleEffect(scale)
    }
}

/**
 * BoxShadowElement: Represents a box shadow effect in the editor
 */
struct BoxShadowElement: EditableElement {
    var id = UUID()
    var position: CGPoint
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var rect: CGRect
    var shadowRadius: CGFloat = 10
    var shadowColor: Color = .black
    var shadowOpacity: Double = 0.5
    
    /**
     * Renders the box shadow element in the editor
     */
    func render() -> some View {
        ZStack {
            // Darkened background with a hole for the highlighted area
            Rectangle()
                .fill(Color.black.opacity(shadowOpacity))
                .mask(
                    Rectangle()
                        .fill(Color.black)
                        .overlay(
                            Rectangle()
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                                .blendMode(.destinationOut)
                        )
                )
            
            // Border around the highlighted area
            Rectangle()
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .overlay(
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: shadowColor, radius: shadowRadius)
        }
        .position(position)
        .rotationEffect(rotation)
        .scaleEffect(scale)
    }
}

/**
 * GlassEffectElement: Represents a glass blur effect in the editor
 */
struct GlassEffectElement: EditableElement {
    var id = UUID()
    var position: CGPoint
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var rect: CGRect
    var blurRadius: CGFloat = 10
    
    /**
     * Renders the glass effect element in the editor
     */
    func render() -> some View {
        Rectangle()
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .blur(radius: blurRadius)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .position(position)
            .rotationEffect(rotation)
            .scaleEffect(scale)
    }
}

/**
 * ArrowShape: Custom shape for drawing different arrow styles
 */
struct ArrowShape: Shape {
    var start: CGPoint
    var end: CGPoint
    var style: ArrowStyle
    
    /**
     * Draws the path for the arrow based on its style
     */
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch style {
        case .straight:
            path.move(to: start)
            path.addLine(to: end)
            
            // Add arrowhead
            let angle = atan2(end.y - start.y, end.x - start.x)
            let arrowLength: CGFloat = 15
            let arrowAngle: CGFloat = .pi / 6 // 30 degrees
            
            let arrowPoint1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowPoint2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )
            
            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
            
        case .curved:
            let control = CGPoint(
                x: start.x,
                y: end.y
            )
            
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
            
            // Add arrowhead to curved line
            let arrowLength: CGFloat = 15
            let arrowAngle: CGFloat = .pi / 6
            
            // Calculate tangent at the end point
            let tangentX = end.x - control.x
            let tangentY = end.y - control.y
            let angle = atan2(tangentY, tangentX)
            
            let arrowPoint1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowPoint2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )
            
            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
            
        case .spiral:
            let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
            let revolutions = distance / 100
            let steps = 50
            
            path.move(to: start)
            
            for i in 1...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let radius = t * distance / 2
                let angle = t * revolutions * 2 * .pi
                
                let x = start.x + (end.x - start.x) * t + radius * cos(angle)
                let y = start.y + (end.y - start.y) * t + radius * sin(angle)
                
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            // Add arrowhead
            let lastPoint = CGPoint(
                x: start.x + (end.x - start.x) + (distance / 2) * cos(revolutions * 2 * .pi),
                y: start.y + (end.y - start.y) + (distance / 2) * sin(revolutions * 2 * .pi)
            )
            
            let angle = atan2(end.y - lastPoint.y, end.x - lastPoint.x)
            let arrowLength: CGFloat = 15
            let arrowAngle: CGFloat = .pi / 6
            
            let arrowPoint1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowPoint2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )
            
            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
            
        case .bent:
            let midX = (start.x + end.x) / 2
            let _ = (start.y + end.y) / 2
            
            let controlPoint1 = CGPoint(x: midX, y: start.y)
            let controlPoint2 = CGPoint(x: midX, y: end.y)
            
            path.move(to: start)
            path.addCurve(to: end, control1: controlPoint1, control2: controlPoint2)
            
            // Add arrowhead to bent line
            let tangentX = end.x - controlPoint2.x
            let tangentY = end.y - controlPoint2.y
            let angle = atan2(tangentY, tangentX)
            
            let arrowLength: CGFloat = 15
            let arrowAngle: CGFloat = .pi / 6
            
            let arrowPoint1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowPoint2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )
            
            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
        }
        
        return path
    }
} 