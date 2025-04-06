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
    @State private var isShowingSaveDialog = false
    @State private var showExportOptions = false
    
    // Current API compatibility issues with fill(_:style:)
    private let fillClear = Color.clear
    private let fillBlack = Color.black
    private let fillWhite = Color.white
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ScrollView(.horizontal, showsIndicators: false) {
                toolbar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .frame(height: 80) // Fix height to ensure toolbar visibility
            
            // Main editor canvas
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                editorCanvasView
                    .frame(minWidth: 600, minHeight: 400)
                    .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
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
     * The toolbar view with editing tools
     */
    private var toolbar: some View {
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

/**
 * Color preview component
 */
struct ColorPreview: View {
    let color: NSColor
    
    var body: some View {
        ZStack {
            // Checkered background to show transparency
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
            // Color overlay
            Rectangle()
                .foregroundColor(Color(color))
            // Border
            Rectangle()
                .stroke(Color.gray, lineWidth: 1)
        }
        .cornerRadius(4)
    }
}

/**
 * Button style for toolbar buttons
 */
struct ToolbarButtonStyle: ButtonStyle {
    var isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                ZStack {
                    // Background fill
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
                    
                    // Border
                    if isActive {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 1)
                    }
                }
            )
            .foregroundColor(isActive ? .accentColor : .primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

/**
 * Primary button style for main actions
 */
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
} 