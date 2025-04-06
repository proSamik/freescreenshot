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
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Background Options")
                .font(.headline)
                .padding(.top)
            
            // Background type selector
            Picker("Background Type", selection: $tempBackgroundType) {
                ForEach(BackgroundType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: tempBackgroundType) { _ in
                updateAndApplyChanges()
            }
            
            // Different options based on selected background type
            Group {
                switch tempBackgroundType {
                case .solid:
                    VStack(alignment: .leading) {
                        Text("Color")
                            .font(.subheadline)
                        
                        ColorPicker("", selection: $tempBackgroundColor)
                            .labelsHidden()
                            .onChange(of: tempBackgroundColor) { _ in
                                updateAndApplyChanges()
                            }
                    }
                    
                case .gradient:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gradient Preset")
                            .font(.subheadline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<gradientPresets.count, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: gradientPresets[index],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 60, height: 40)
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
                            .padding(.horizontal)
                        }
                    }
                    
                case .image:
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
                    
                case .none:
                    Text("No background will be applied")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(height: 150)
            
            Divider()
            
            // 3D effect toggle
            Toggle("Apply 3D Perspective Effect", isOn: $tempIs3DEffect)
                .onChange(of: tempIs3DEffect) { _ in
                    updateAndApplyChanges()
                }
                .padding(.horizontal)
            
            // 3D perspective direction selector (only shown when 3D effect is enabled)
            if tempIs3DEffect {
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
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            // Preview
            if let image = viewModel.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding()
                    .id(refreshPreview)
            }
            
            // Buttons
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
            .padding()
        }
        .frame(width: 500, height: 550)
        .onAppear {
            // Apply any existing background settings when picker appears
            updateAndApplyChanges()
        }
    }
    
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
     * Updates the viewModel with temp values and applies background
     */
    private func updateAndApplyChanges() {
        // Update the viewModel with temporary values
        viewModel.backgroundType = tempBackgroundType
        viewModel.backgroundColor = tempBackgroundColor
        viewModel.backgroundGradient = tempBackgroundGradient
        viewModel.is3DEffect = tempIs3DEffect
        viewModel.perspective3DDirection = tempPerspective3DDirection
        
        // Apply the background change
        DispatchQueue.main.async {
            // Apply the background with a slight delay to ensure UI updates
            viewModel.applyBackground()
            
            // Force UI refresh by toggling state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.refreshPreview.toggle()
            }
        }
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
        case .left:
            return "arrow.left"
        case .bottomLeft:
            return "arrow.down.left"
        case .bottom:
            return "arrow.down"
        case .bottomRight:
            return "arrow.down.right"
        case .right:
            return "arrow.right"
        }
    }
} 