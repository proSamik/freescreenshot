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
                        // Dynamic sizing based on image dimensions
                        .frame(
                            width: viewModel.image != nil ? max(viewModel.canvasWidth, 400) : 600,
                            height: viewModel.image != nil ? max(viewModel.canvasHeight, 300) : 400
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
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 700)
        .frame(minHeight: 600)
        .sheet(isPresented: $isShowingBackgroundPicker) {
            BackgroundPicker(viewModel: viewModel, isPresented: $isShowingBackgroundPicker)
        }
        .fileExporter(
            isPresented: $isShowingSaveDialog,
            document: ImageDocument(image: viewModel.image ?? NSImage()),
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