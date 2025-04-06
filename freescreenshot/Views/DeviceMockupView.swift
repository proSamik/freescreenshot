//
//  DeviceMockupView.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI

/**
 * DeviceMockupView: A view that displays device mockups with a screenshot inside
 */
struct DeviceMockupView: View {
    let screenshot: NSImage
    @State private var selectedDevice: DeviceType = .macbook
    @State private var previewImage: NSImage?
    @Binding var selectedImage: NSImage?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Device Mockups")
                .font(.headline)
                .padding(.top)
            
            // Device selector
            Picker("Device", selection: $selectedDevice) {
                ForEach(DeviceType.allCases) { device in
                    Text(device.displayName).tag(device)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedDevice) { _ in
                updatePreview()
            }
            
            // Preview of the device mockup
            if let preview = previewImage {
                Image(nsImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding()
            } else {
                ProgressView()
                    .frame(height: 300)
            }
            
            // Apply button
            Button("Apply") {
                selectedImage = previewImage
            }
            .buttonStyle(.borderedProminent)
            .disabled(previewImage == nil)
            .padding(.bottom)
        }
        .frame(width: 450)
        .onAppear {
            updatePreview()
        }
    }
    
    /**
     * Updates the preview image when the device type changes
     */
    private func updatePreview() {
        DispatchQueue.main.async {
            self.previewImage = ImageUtilities.createDeviceMockup(for: screenshot, deviceType: selectedDevice)
        }
    }
}

/**
 * DeviceMockupPicker: A sheet that allows selecting a device mockup
 */
struct DeviceMockupPicker: View {
    @Binding var isPresented: Bool
    let screenshot: NSImage
    @Binding var outputImage: NSImage?
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Text("Choose Device Mockup")
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            DeviceMockupView(screenshot: screenshot, selectedImage: $outputImage)
        }
        .frame(width: 500, height: 450)
    }
}

/**
 * Preview for device mockups to be shown in asset catalog
 */
struct DeviceMockupAsset: Identifiable {
    let id = UUID()
    let device: DeviceType
    let assetName: String
    
    static let assets: [DeviceMockupAsset] = [
        DeviceMockupAsset(device: .macbook, assetName: "mockup_macbook"),
        DeviceMockupAsset(device: .iphone, assetName: "mockup_iphone"),
        DeviceMockupAsset(device: .ipad, assetName: "mockup_ipad")
    ]
} 