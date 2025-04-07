//
//  BackgroundPicker.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI

/**
 * BackgroundPicker: A view for selecting different types of backgrounds
 */
struct BackgroundPicker: View {
    @ObservedObject var viewModel: EditorViewModel
    @Binding var isPresented: Bool
    @State private var selectedGradientPreset = 0
    @State private var tempBackgroundType: BackgroundType
    @State private var tempBackgroundColor: Color
    @State private var tempBackgroundGradient: Gradient
    @State private var tempIs3DEffect: Bool
    @State private var tempPerspective3DDirection: Perspective3DDirection
    @State private var tempAspectRatio: AspectRatio
    @State private var tempImagePadding: CGFloat
    @State private var tempCornerRadius: CGFloat
    @State private var refreshPreview: Bool = false
    
    // Predefined gradient presets
    private let gradientPresets: [Gradient] = [
        Gradient(colors: [.blue, .purple]),
        Gradient(colors: [.green, .blue]),
        Gradient(colors: [.orange, .red]),
        Gradient(colors: [.pink, .purple]),
        Gradient(colors: [.gray, .black]),
        Gradient(colors: [.yellow, .green])
    ]
    
    init(viewModel: EditorViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._tempBackgroundType = State(initialValue: viewModel.backgroundType)
        self._tempBackgroundColor = State(initialValue: viewModel.backgroundColor)
        self._tempBackgroundGradient = State(initialValue: viewModel.backgroundGradient)
        self._tempIs3DEffect = State(initialValue: viewModel.is3DEffect)
        self._tempPerspective3DDirection = State(initialValue: viewModel.perspective3DDirection)
        self._tempAspectRatio = State(initialValue: viewModel.aspectRatio)
        self._tempImagePadding = State(initialValue: viewModel.imagePadding)
        self._tempCornerRadius = State(initialValue: viewModel.cornerRadius)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT COLUMN - Controls
            controlsColumn
            
            Divider()
            
            // RIGHT COLUMN - Preview
            previewColumn
        }
        .frame(width: 800, height: 700)
        .onAppear {
            // Apply any existing background settings when picker appears
            updateAndApplyChanges()
        }
    }
    
    // MARK: - UI Components
    
    // Left column with all controls
    private var controlsColumn: some View {
        VStack(spacing: 0) {
            Text("Background Options")
                .font(.headline)
                .padding(.top, 8)
            
            // Background type selector
            Picker("Background Type", selection: $tempBackgroundType) {
                ForEach(BackgroundType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .onChange(of: tempBackgroundType) { _ in
                updateAndApplyChanges()
            }
            
            // Different options based on selected background type
            backgroundTypeOptions
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .frame(minHeight: 10)
            
            Divider()
                .padding(.horizontal, 16)
            
            // 3D effect toggle
            Toggle("Apply 3D Perspective Effect", isOn: $tempIs3DEffect)
                .onChange(of: tempIs3DEffect) { _ in
                    updateAndApplyChanges()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            // 3D perspective direction selector (only shown when 3D effect is enabled)
            if tempIs3DEffect {
                perspectiveDirectionSelector
            }
            
            // Canvas size adjustment
            canvasSettingsView
            
            Spacer()
            
            // Buttons
            buttonRow
        }
        .frame(width: 400)
        .padding(.horizontal, 12)
    }
    
    // Right column with preview
    private var previewColumn: some View {
        VStack {
            Text("Preview")
                .font(.headline)
                .padding(.top, 20)
            
            // Preview container
            GeometryReader { geo in
                // Fixed size container for the image preview
                ZStack {
                    standardPreviewView(in: geo)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .frame(minWidth: 300)
        .padding(.horizontal, 16)
    }
    
    // Background type specific options
    private var backgroundTypeOptions: some View {
        Group {
            switch tempBackgroundType {
            case .solid:
                solidColorView
                
            case .gradient:
                gradientView
                
            case .image:
                backgroundImageView
                
            case .none:
                Text("No background will be applied")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Solid color background options
    private var solidColorView: some View {
        VStack(alignment: .leading) {
            Text("Color")
                .font(.subheadline)
            
            ColorPicker("", selection: $tempBackgroundColor)
                .labelsHidden()
                .onChange(of: tempBackgroundColor) { _ in
                    updateAndApplyChanges()
                }
        }
    }
    
    // Gradient background options
    private var gradientView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gradient Preset")
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<gradientPresets.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: gradientPresets[index],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedGradientPreset == index ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedGradientPreset = index
                                tempBackgroundGradient = gradientPresets[index]
                                updateAndApplyChanges()
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    // Device mockup options
    private var deviceMockupView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Device mockups have been removed")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // Background image options
    private var backgroundImageView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Background Image")
                .font(.subheadline)
            
            Button("Select Image") {
                selectBackgroundImage()
            }
            .frame(maxWidth: .infinity)
            
            if viewModel.backgroundImage != nil {
                Text("Image selected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // 3D perspective direction selector
    private var perspectiveDirectionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Perspective Direction")
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Perspective3DDirection.allCases) { direction in
                        Button(action: {
                            tempPerspective3DDirection = direction
                            updateAndApplyChanges()
                        }) {
                            VStack {
                                Image(systemName: directionIcon(for: direction))
                                    .font(.system(size: 16))
                                    .frame(width: 24, height: 24)
                                
                                Text(direction.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 60)
                            }
                            .padding(6)
                            .background(tempPerspective3DDirection == direction ? 
                                       Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .transition(.opacity)
    }
    
    // Canvas settings view
    private var canvasSettingsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Canvas Settings")
                .font(.subheadline)
            
            // Aspect ratio selector
            Text("Aspect Ratio")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AspectRatio.allCases) { ratio in
                        Button(action: {
                            tempAspectRatio = ratio
                            updateAndApplyChanges()
                        }) {
                            Text(ratio.displayName)
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(tempAspectRatio == ratio ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                                .foregroundColor(tempAspectRatio == ratio ? .accentColor : .primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(tempAspectRatio == ratio ? Color.accentColor : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 4)
            }
            
            // Padding slider
            HStack {
                Text("Padding: \(Int(tempImagePadding))%")
                    .font(.caption)
                    .frame(width: 100, alignment: .leading)
                
                Slider(value: $tempImagePadding, in: 0...40, step: 1)
                    .onChange(of: tempImagePadding) { _ in
                        updateAndApplyChanges()
                    }
            }
            
            // Corner radius slider
            HStack {
                Text("Corner Radius: \(Int(tempCornerRadius))px")
                    .font(.caption)
                    .frame(width: 120, alignment: .leading)
                
                Slider(value: $tempCornerRadius, in: 0...50, step: 1)
                    .onChange(of: tempCornerRadius) { _ in
                        updateAndApplyChanges()
                    }
            }
            
            // Preview corner radius as a visual aid
            if tempCornerRadius > 0 {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: tempCornerRadius / 2)
                        .stroke(Color.accentColor, lineWidth: 1)
                        .frame(width: 80, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: tempCornerRadius / 2)
                            .fill(Color.accentColor.opacity(0.2))
                        )
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // Button row at the bottom
    private var buttonRow: some View {
        HStack {
            Button("Cancel") {
                // Revert to original image
                if let originalImage = viewModel.originalImage {
                    viewModel.image = originalImage
                    viewModel.backgroundType = .none
                }
                isPresented = false
            }
            .keyboardShortcut(.escape)
            
            Spacer()
            
            Button("Apply") {
                // Keep current changes and apply them permanently
                applyChanges()
                isPresented = false
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // MARK: - Preview Views
    
    // Standard background preview for non-device types
    private func standardPreviewView(in geo: GeometryProxy) -> some View {
        Group {
            // Static background that doesn't rotate (if background is applied)
            if tempBackgroundType != .none {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .frame(
                        // Increased canvas size to accommodate 3D rotation
                        width: min(geo.size.width * 0.95, geo.size.height * 0.95),
                        height: min(geo.size.width * 0.95, geo.size.height * 0.95)
                    )
            }
            
            // Image preview with 3D rotation applied only to the image
            if let image = viewModel.image {
                // Use SwiftUI's built-in 3D rotation for the preview only
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        // Make image smaller to ensure it stays within canvas when rotated
                        width: tempIs3DEffect 
                            ? min(geo.size.width * 0.7, geo.size.height * 0.7)
                            : min(geo.size.width * 0.8, geo.size.height * 0.8),
                        height: tempIs3DEffect 
                            ? min(geo.size.width * 0.7, geo.size.height * 0.7) 
                            : min(geo.size.width * 0.8, geo.size.height * 0.8)
                    )
                    // Apply 3D rotation using SwiftUI's built-in effect - only for non-device backgrounds
                    .rotation3DEffect(
                        tempIs3DEffect ? getRotationAngle() : .zero,
                        axis: tempIs3DEffect ? getRotationAxis() : (x: 0, y: 0, z: 1),
                        anchor: getRotationAnchor(),
                        perspective: tempIs3DEffect ? 0.2 : 0
                    )
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
                    .id(refreshPreview)
            } else {
                Text("No preview available")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Opens a file picker to select a background image
     */
    private func selectBackgroundImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.png, .jpeg, .jpg, .tiff, .gif, .bmp]
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            if let image = NSImage(contentsOf: url) {
                viewModel.backgroundImage = image
                updateAndApplyChanges()
            }
        }
    }
    
    /**
     * Updates view model properties and applies changes
     */
    private func updateAndApplyChanges() {
        viewModel.backgroundType = tempBackgroundType
        viewModel.backgroundColor = tempBackgroundColor
        viewModel.backgroundGradient = tempBackgroundGradient
        viewModel.is3DEffect = tempIs3DEffect
        viewModel.perspective3DDirection = tempPerspective3DDirection
        viewModel.aspectRatio = tempAspectRatio
        viewModel.imagePadding = tempImagePadding
        viewModel.cornerRadius = tempCornerRadius
        
        // Apply the background change
        viewModel.applyBackground()
        
        // Trigger preview refresh
        refreshPreview.toggle()
    }
    
    /**
     * Applies all changes permanently
     */
    private func applyChanges() {
        updateAndApplyChanges()
    }
    
    /**
     * Returns an appropriate system icon name for each perspective direction
     */
    private func directionIcon(for direction: Perspective3DDirection) -> String {
        switch direction {
        case .topLeft:
            return "arrow.up.left"
        case .top:
            return "arrow.up"
        case .topRight:
            return "arrow.up.right"
        case .bottomLeft:
            return "arrow.down.left"
        case .bottom:
            return "arrow.down"
        case .bottomRight:
            return "arrow.down.right"
        }
    }
    
    /**
     * Returns the 3D rotation angle based on selected direction
     */
    private func getRotationAngle() -> Angle {
        switch tempPerspective3DDirection {
        case .topLeft, .top, .topRight:
            return .degrees(15) // Increase from 10 to 15 degrees
        case .bottomLeft, .bottom, .bottomRight:
            return .degrees(-15) // Increase from -10 to -15 degrees
        }
    }
    
    /**
     * Returns the 3D rotation axis based on selected direction
     */
    private func getRotationAxis() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch tempPerspective3DDirection {
        case .topLeft:
            return (x: 1, y: 1, z: 0)
        case .top:
            return (x: 1, y: 0, z: 0)
        case .topRight:
            return (x: 1, y: -1, z: 0)
        case .bottomLeft:
            return (x: -1, y: 1, z: 0)
        case .bottom:
            return (x: -1, y: 0, z: 0)
        case .bottomRight:
            return (x: -1, y: -1, z: 0)
        }
    }
    
    /**
     * Returns the anchor point for rotation based on direction
     */
    private func getRotationAnchor() -> UnitPoint {
        switch tempPerspective3DDirection {
        case .topLeft:
            return .topLeading
        case .top:
            return .top
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottom:
            return .bottom
        case .bottomRight:
            return .bottomTrailing
        }
    }
} 