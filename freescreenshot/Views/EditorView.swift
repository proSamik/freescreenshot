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
    @State private var isShowingSaveDialog = false
    
    /**
     * Calculate canvas width based on aspect ratio
     */
    private var calculatedCanvasWidth: CGFloat {
        if let image = viewModel.image {
            let aspectRatio = viewModel.aspectRatio.ratio
            if aspectRatio >= 1 {
                // For landscape or square
                return min(700, max(500, image.size.width * 1.2))
            } else {
                // For portrait
                return min(600, max(400, image.size.height * 1.2 * aspectRatio))
            }
        }
        return 600 // Default
    }
    
    /**
     * Calculate canvas height based on aspect ratio
     */
    private var calculatedCanvasHeight: CGFloat {
        if let image = viewModel.image {
            let aspectRatio = viewModel.aspectRatio.ratio
            if aspectRatio >= 1 {
                // For landscape or square
                return calculatedCanvasWidth / aspectRatio
            } else {
                // For portrait
                return min(800, max(500, image.size.height * 1.2))
            }
        }
        return 500 // Default
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar - simplified to only show background feature
            HStack {
                Spacer()
                Text("Screenshot Background Tool")
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main editor canvas
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    editorCanvasView
                        // Dynamic sizing based on aspect ratio and available space
                        .frame(
                            width: calculatedCanvasWidth, 
                            height: calculatedCanvasHeight
                        )
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                        .padding(20)
                }
                .background(Color(NSColor.windowBackgroundColor))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            }
            .frame(minHeight: 450)
            
            // Bottom toolbar with background and export buttons
            HStack(spacing: 16) {
                // Background button
                Button {
                    isShowingBackgroundPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                            .font(.title2)
                            .frame(width: 30, height: 30)
                        
                        Text("Background")
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isShowingBackgroundPicker ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
                    .foregroundColor(isShowingBackgroundPicker ? .accentColor : .primary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Export button
                Button {
                    exportImage()
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
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 700)
        .frame(minHeight: 600)
        .sheet(isPresented: $isShowingBackgroundPicker) {
            BackgroundPicker(viewModel: viewModel, isPresented: $isShowingBackgroundPicker)
        }
        .navigationTitle("Screenshot Background Tool")
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
        // Show only the processed image with background
        Group {
            if let image = viewModel.image {
                GeometryReader { geo in
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                        .id(image.hashValue) // Force refresh when image changes
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            } else {
                Color(NSColor.windowBackgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /**
     * Exports the screenshot using NSSavePanel instead of fileExporter
     * This prevents the app from quitting after export
     */
    private func exportImage() {
        guard let image = viewModel.image else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Screenshot"
        savePanel.message = "Choose a location to save your screenshot"
        savePanel.nameFieldLabel = "File name:"
        savePanel.nameFieldStringValue = "screenshot"
        
        savePanel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { response in
            if response == .OK {
                if let url = savePanel.url {
                    // Convert NSImage to PNG data
                    if let pngData = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: pngData),
                       let data = bitmap.representation(using: .png, properties: [:]) {
                        do {
                            try data.write(to: url)
                            print("Image saved successfully to \(url)")
                        } catch {
                            print("Error saving image: \(error)")
                        }
                    }
                }
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