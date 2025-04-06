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
    
    // Predefined gradient presets
    private let gradientPresets: [Gradient] = [
        Gradient(colors: [.blue, .purple]),
        Gradient(colors: [.green, .blue]),
        Gradient(colors: [.orange, .red]),
        Gradient(colors: [.pink, .purple]),
        Gradient(colors: [.gray, .black]),
        Gradient(colors: [.yellow, .green])
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Background Options")
                .font(.headline)
                .padding(.top)
            
            // Background type selector
            Picker("Background Type", selection: $viewModel.backgroundType) {
                ForEach(BackgroundType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: viewModel.backgroundType) { _ in
                viewModel.applyBackground()
            }
            
            // Different options based on selected background type
            Group {
                switch viewModel.backgroundType {
                case .solid:
                    VStack(alignment: .leading) {
                        Text("Color")
                            .font(.subheadline)
                        
                        ColorPicker("", selection: $viewModel.backgroundColor)
                            .labelsHidden()
                            .onChange(of: viewModel.backgroundColor) { _ in
                                viewModel.applyBackground()
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
                                            viewModel.backgroundGradient = gradientPresets[index]
                                            viewModel.applyBackground()
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
            Toggle("Apply 3D Perspective Effect", isOn: $viewModel.is3DEffect)
                .onChange(of: viewModel.is3DEffect) { _ in
                    viewModel.applyBackground()
                }
                .padding(.horizontal)
            
            // Preview
            if let image = viewModel.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding()
            }
            
            // Buttons
            HStack {
                Button("Cancel") {
                    // Revert to original image
                    if let originalImage = viewModel.originalImage {
                        viewModel.image = originalImage
                    }
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Apply") {
                    // Keep current changes
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 550)
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
                viewModel.applyBackground()
            }
        }
    }
} 