//
//  ContentView.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI
import UniformTypeIdentifiers

/**
 * ContentView: Main view of the application
 * Handles transitions between welcome screen and editor view
 */
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var editorViewModel = EditorViewModel()
    @State private var isDropTargeted = false
    @State private var isScreenCaptureInProgress = false
    @State private var isBackgroundPickerPresented = false
    @State private var isDragOver = false
    
    var body: some View {
        ZStack {
            // Welcome screen when no image is captured
            if !appState.isEditorOpen {
                welcomeView
            } else {
                // Editor view when an image is available
                if let image = appState.capturedImage {
                    EditorView(viewModel: editorViewModel)
                        .onAppear {
                            editorViewModel.setImage(image)
                        }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 800)
    }
    
    /**
     * Welcome screen view
     */
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.top, 40)
            
            Text("Free Screenshot")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Transform your screenshots into stunning visuals")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
            
            // Drag & Drop Zone
            dropZoneView
                .padding(.vertical, 30)
            
            VStack(alignment: .leading, spacing: 15) {
                instructionRow(icon: "keyboard", text: "Press Cmd+Shift+7 to capture a screenshot")
                instructionRow(icon: "wand.and.stars", text: "Add backgrounds, arrows, text, and effects")
                instructionRow(icon: "square.and.arrow.up", text: "Export your enhanced screenshot")
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
            
            Button(action: {
                appState.initiateScreenCapture()
            }) {
                Text("Take Screenshot")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("7", modifiers: [.command, .shift])
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    /**
     * Drop zone for image files
     */
    private var dropZoneView: some View {
        VStack {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 30))
                .foregroundColor(isDropTargeted ? .accentColor : .secondary)
                .padding(.bottom, 8)
            
            Text("Drag & Drop Image Here")
                .font(.headline)
                .foregroundColor(isDropTargeted ? .accentColor : .primary)
        }
        .frame(width: 300, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.5), 
                       style: StrokeStyle(lineWidth: 2, dash: [5]))
                .background(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                .cornerRadius(12)
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers, _ in
            handleDrop(providers: providers)
            return true
        }
    }
    
    /**
     * Helper function to create consistent instruction rows
     */
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 28, height: 28)
                .foregroundColor(.accentColor)
            
            Text(text)
                .font(.body)
        }
    }
    
    /**
     * Handles file drop for image import
     */
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                if let urlData = urlData as? Data, 
                   let url = URL(dataRepresentation: urlData, relativeTo: nil),
                   ["jpg", "jpeg", "png", "gif", "tiff", "bmp"].contains(url.pathExtension.lowercased()) {
                    DispatchQueue.main.async {
                        if let image = NSImage(contentsOf: url) {
                            self.appState.capturedImage = image
                            self.appState.isEditorOpen = true
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Initiates the screenshot process
     */
    private func initiateScreenshot() {
        isScreenCaptureInProgress = true
        
        // Use the appState to initiate screen capture
        appState.initiateScreenCapture()
        isScreenCaptureInProgress = false
    }
    
    /**
     * Saves the screenshot to disk
     */
    private func saveScreenshot() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Screenshot"
        savePanel.message = "Choose a location to save your screenshot"
        savePanel.nameFieldLabel = "File name:"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                self.editorViewModel.saveImage(to: url)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
