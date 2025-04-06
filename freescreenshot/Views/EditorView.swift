//
//  EditorView.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Cocoa

/**
 * EditorView: Main view for editing screenshots
 * Provides toolbar with editing tools and canvas for manipulation
 */
struct EditorView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Editor state
    @State private var isShowingBackgroundPicker = false
    @State private var isShowingDeviceMockup = false
    @State private var isDrawingArrow = false
    @State private var arrowStart: CGPoint?
    @State private var currentDragPosition: CGPoint?
    @State private var isDrawingHighlighter = false
    @State private var highlighterPoints: [CGPoint] = []
    @State private var isSelectingBoxShadow = false
    @State private var boxShadowStart: CGPoint?
    @State private var isSelectingGlassEffect = false
    @State private var glassEffectStart: CGPoint?
    @State private var isTextEditorActive = false
    @State private var textEditorContent = ""
    @State private var textEditorPosition: CGPoint?
    @State private var isShowingSaveDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
            
            // Main editor canvas
            editorCanvasView
        }
        .sheet(isPresented: $isShowingBackgroundPicker) {
            BackgroundPicker(viewModel: viewModel, isPresented: $isShowingBackgroundPicker)
        }
        .sheet(isPresented: $isShowingDeviceMockup) {
            if let image = viewModel.originalImage {
                DeviceMockupPicker(isPresented: $isShowingDeviceMockup, screenshot: image, outputImage: $viewModel.image)
            }
        }
        .fileExporter(
            isPresented: $isShowingSaveDialog,
            document: ImageDocument(image: viewModel.exportImage() ?? NSImage()),
            contentType: .png,
            defaultFilename: "screenshot"
        ) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print("Error saving: \(error)")
            }
        }
        .navigationTitle("Screenshot Editor")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    /**
     * Creates the main editor canvas view
     */
    private var editorCanvasView: some View {
        ZStack {
            // Background color/pattern
            backgroundLayer
            
            // Image being edited
            imageLayer
            
            // Draw all elements
            elementsLayer
            
            // Temp drawing elements
            temporaryDrawingElements
            
            // Text editor
            textEditorLayer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .gesture(
            TapGesture()
                .onEnded {
                    // If we've tapped without a valid currentDragPosition, we can't use this approach
                    if let currentLocation = currentDragPosition {
                        handleCanvasTap(at: currentLocation)
                    }
                }
        )
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    // Store the current position for tap detection
                    currentDragPosition = value.location
                    handleDrag(state: .changed, location: value.location)
                }
                .onEnded { value in
                    handleDrag(state: .ended, location: value.location)
                }
        )
    }
    
    /**
     * Background color/pattern layer
     */
    private var backgroundLayer: some View {
        Color(NSColor.windowBackgroundColor)
            .ignoresSafeArea()
    }
    
    /**
     * Image being edited layer
     */
    private var imageLayer: some View {
        Group {
            if let image = viewModel.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
    }
    
    /**
     * Elements layer for all editing elements
     */
    private var elementsLayer: some View {
        ForEach(viewModel.elements.indices, id: \.self) { index in
            ElementView(element: viewModel.elements[index])
                .opacity(0.99) // Workaround to ensure views update properly
        }
    }
    
    /**
     * Temporary drawing elements while editing
     */
    private var temporaryDrawingElements: some View {
        Group {
            // Arrow drawing
            arrowDrawingLayer
            
            // Highlighter drawing
            highlighterDrawingLayer
            
            // Box shadow
            boxShadowLayer
            
            // Glass effect
            glassEffectLayer
        }
    }
    
    /**
     * Arrow drawing temporary layer
     */
    private var arrowDrawingLayer: some View {
        Group {
            if isDrawingArrow, let start = arrowStart, let current = currentDragPosition {
                ArrowShape(start: start, end: current, style: viewModel.arrowStyle)
                    .stroke(Color(nsColor: NSColor(viewModel.textColor)), lineWidth: viewModel.lineWidth)
            }
        }
    }
    
    /**
     * Highlighter drawing temporary layer
     */
    private var highlighterDrawingLayer: some View {
        Group {
            if isDrawingHighlighter, highlighterPoints.count > 1 {
                Path { path in
                    path.move(to: highlighterPoints[0])
                    for point in highlighterPoints.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    Color(nsColor: NSColor(viewModel.highlighterColor)).opacity(viewModel.highlighterOpacity),
                    lineWidth: viewModel.lineWidth * 5
                )
            }
        }
    }
    
    /**
     * Box shadow drawing temporary layer
     */
    private var boxShadowLayer: some View {
        Group {
            if isSelectingBoxShadow, let start = boxShadowStart, let current = currentDragPosition {
                let rect = CGRect(
                    x: min(start.x, current.x),
                    y: min(start.y, current.y),
                    width: abs(current.x - start.x),
                    height: abs(current.y - start.y)
                )
                
                // Draw temporary box shadow
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
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
                    
                    Rectangle()
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: rect.width, height: rect.height)
                        )
                }
            }
        }
    }
    
    /**
     * Glass effect drawing temporary layer
     */
    private var glassEffectLayer: some View {
        Group {
            if isSelectingGlassEffect, let start = glassEffectStart, let current = currentDragPosition {
                let rect = CGRect(
                    x: min(start.x, current.x),
                    y: min(start.y, current.y),
                    width: abs(current.x - start.x),
                    height: abs(current.y - start.y)
                )
                
                // Draw temporary glass effect
                Rectangle()
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .blur(radius: 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    /**
     * Text editor layer for active text editing
     */
    private var textEditorLayer: some View {
        Group {
            if isTextEditorActive, let position = textEditorPosition {
                TextField("Enter text", text: $textEditorContent, onCommit: {
                    if !textEditorContent.isEmpty {
                        viewModel.addText(at: position, text: textEditorContent)
                    }
                    isTextEditorActive = false
                    textEditorContent = ""
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .position(position)
            }
        }
    }
    
    /**
     * The toolbar view with editing tools
     */
    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Background button
                ToolbarButton(
                    title: "Background",
                    icon: "photo.fill",
                    isSelected: isShowingBackgroundPicker
                ) {
                    isShowingBackgroundPicker = true
                }
                
                // Device mockup button
                ToolbarButton(
                    title: "Device",
                    icon: "macbook",
                    isSelected: isShowingDeviceMockup
                ) {
                    isShowingDeviceMockup = true
                }
                
                Divider()
                    .frame(height: 30)
                
                // Text tool
                ToolbarButton(
                    title: "Text",
                    icon: "textformat",
                    isSelected: viewModel.currentTool == .text
                ) {
                    viewModel.currentTool = .text
                    resetAllDrawingStates()
                }
                
                // Arrow tool with style picker
                Menu {
                    ForEach(ArrowStyle.allCases) { style in
                        Button(style.rawValue.capitalized) {
                            viewModel.arrowStyle = style
                            viewModel.currentTool = .arrow
                            resetAllDrawingStates()
                        }
                    }
                } label: {
                    ToolbarButton(
                        title: "Arrow",
                        icon: "arrow.up.right",
                        isSelected: viewModel.currentTool == .arrow
                    ) {
                        viewModel.currentTool = .arrow
                        resetAllDrawingStates()
                    }
                }
                
                // Highlighter tool
                ToolbarButton(
                    title: "Highlight",
                    icon: "highlighter",
                    isSelected: viewModel.currentTool == .highlighter
                ) {
                    viewModel.currentTool = .highlighter
                    resetAllDrawingStates()
                }
                
                // Box shadow tool
                ToolbarButton(
                    title: "Box Shadow",
                    icon: "rectangle.fill",
                    isSelected: viewModel.currentTool == .boxShadow
                ) {
                    viewModel.currentTool = .boxShadow
                    resetAllDrawingStates()
                }
                
                // Glass effect tool
                ToolbarButton(
                    title: "Glass",
                    icon: "circle.dotted",
                    isSelected: viewModel.currentTool == .glassEffect
                ) {
                    viewModel.currentTool = .glassEffect
                    resetAllDrawingStates()
                }
                
                Divider()
                    .frame(height: 30)
                
                // Color picker
                ColorPicker("", selection: $viewModel.textColor)
                    .labelsHidden()
                    .frame(width: 30, height: 30)
                
                // Line width picker
                Menu {
                    Button("Thin") { viewModel.lineWidth = 1 }
                    Button("Medium") { viewModel.lineWidth = 2 }
                    Button("Thick") { viewModel.lineWidth = 4 }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .frame(width: 30, height: 30)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Remove selected element
                Button {
                    viewModel.removeSelectedElement()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .frame(width: 30, height: 30)
                }
                
                Spacer()
                
                // Export button
                Button {
                    isShowingSaveDialog = true
                } label: {
                    Text("Export")
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)
        }
    }
    
    /**
     * Handles taps on the canvas
     */
    private func handleCanvasTap(at location: CGPoint) {
        switch viewModel.currentTool {
        case .select:
            // Deselect all if tapping empty area
            viewModel.selectedElementId = nil
            
        case .text:
            isTextEditorActive = true
            textEditorPosition = location
            
        default:
            break
        }
    }
    
    /**
     * Handles drag gestures on the canvas
     */
    private func handleDrag(state: DragState, location: CGPoint) {
        currentDragPosition = location
        
        switch viewModel.currentTool {
        case .select:
            handleSelectDrag(state: state, location: location)
            
        case .arrow:
            handleArrowDrag(state: state, location: location)
            
        case .highlighter:
            handleHighlighterDrag(state: state, location: location)
            
        case .boxShadow:
            handleBoxShadowDrag(state: state, location: location)
            
        case .glassEffect:
            handleGlassEffectDrag(state: state, location: location)
            
        default:
            break
        }
    }
    
    /**
     * Handles dragging for selection tool
     */
    private func handleSelectDrag(state: DragState, location: CGPoint) {
        switch state {
        case .changed:
            if !viewModel.isDragging {
                viewModel.startDrag(at: location)
            } else {
                viewModel.updateDrag(to: location)
            }
        case .ended:
            viewModel.endDrag()
        }
    }
    
    /**
     * Handles dragging for arrow tool
     */
    private func handleArrowDrag(state: DragState, location: CGPoint) {
        switch state {
        case .changed:
            if !isDrawingArrow {
                isDrawingArrow = true
                arrowStart = location
            }
        case .ended:
            if let start = arrowStart {
                viewModel.addArrow(from: start, to: location)
                isDrawingArrow = false
                arrowStart = nil
            }
        }
    }
    
    /**
     * Handles dragging for highlighter tool
     */
    private func handleHighlighterDrag(state: DragState, location: CGPoint) {
        switch state {
        case .changed:
            if !isDrawingHighlighter {
                isDrawingHighlighter = true
                highlighterPoints = [location]
            } else {
                highlighterPoints.append(location)
            }
        case .ended:
            if highlighterPoints.count > 1 {
                viewModel.addHighlighter(points: highlighterPoints)
                isDrawingHighlighter = false
                highlighterPoints = []
            }
        }
    }
    
    /**
     * Handles dragging for box shadow tool
     */
    private func handleBoxShadowDrag(state: DragState, location: CGPoint) {
        switch state {
        case .changed:
            if !isSelectingBoxShadow {
                isSelectingBoxShadow = true
                boxShadowStart = location
            }
        case .ended:
            if let start = boxShadowStart {
                let rect = CGRect(
                    x: min(start.x, location.x),
                    y: min(start.y, location.y),
                    width: abs(location.x - start.x),
                    height: abs(location.y - start.y)
                )
                viewModel.addBoxShadow(rect: rect)
                isSelectingBoxShadow = false
                boxShadowStart = nil
            }
        }
    }
    
    /**
     * Handles dragging for glass effect tool
     */
    private func handleGlassEffectDrag(state: DragState, location: CGPoint) {
        switch state {
        case .changed:
            if !isSelectingGlassEffect {
                isSelectingGlassEffect = true
                glassEffectStart = location
            }
        case .ended:
            if let start = glassEffectStart {
                let rect = CGRect(
                    x: min(start.x, location.x),
                    y: min(start.y, location.y),
                    width: abs(location.x - start.x),
                    height: abs(location.y - start.y)
                )
                viewModel.addGlassEffect(rect: rect)
                isSelectingGlassEffect = false
                glassEffectStart = nil
            }
        }
    }
    
    /**
     * Resets all temporary drawing states
     */
    private func resetAllDrawingStates() {
        isDrawingArrow = false
        arrowStart = nil
        isDrawingHighlighter = false
        highlighterPoints = []
        isSelectingBoxShadow = false
        boxShadowStart = nil
        isSelectingGlassEffect = false
        glassEffectStart = nil
        isTextEditorActive = false
        textEditorContent = ""
        textEditorPosition = nil
        currentDragPosition = nil
    }
}

/**
 * DragState: Represents the state of a drag gesture
 */
enum DragState {
    case changed
    case ended
}

/**
 * ToolbarButton: Reusable button for the toolbar
 */
struct ToolbarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 30, height: 30)
                
                Text(title)
                    .font(.caption)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

/**
 * ElementView: Generic view for rendering editable elements
 */
struct ElementView: View {
    let element: any EditableElement
    
    var body: some View {
        Group {
            if let textElement = element as? TextElement {
                textElement.render()
            } else if let arrowElement = element as? ArrowElement {
                arrowElement.render()
            } else if let highlighterElement = element as? HighlighterElement {
                highlighterElement.render()
            } else if let boxShadowElement = element as? BoxShadowElement {
                boxShadowElement.render()
            } else if let glassEffectElement = element as? GlassEffectElement {
                glassEffectElement.render()
            }
        }
    }
}

/**
 * ImageDocument: Represents an image document for export
 */
struct ImageDocument: FileDocument, @unchecked Sendable {
    static var readableContentTypes: [UTType] { [UTType.png, UTType.jpeg] }
    
    var image: NSImage
    
    /**
     * Initializes an image document with an NSImage
     */
    init(image: NSImage) {
        self.image = image
    }
    
    /**
     * Initializes an image document from file data
     */
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let image = NSImage(data: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.image = image
    }
    
    /**
     * Writes the image to a file
     */
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = ImageUtilities.imageToData(image, format: .png) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
} 