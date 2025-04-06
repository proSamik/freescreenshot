import SwiftUI

/**
 * DeviceMockupPicker: A sheet that allows selecting a device mockup
 */
struct DeviceMockupPicker: View {
    @Binding var isPresented: Bool
    let screenshot: NSImage
    @Binding var outputImage: NSImage?
    @State private var selectedDeviceImage: NSImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color(NSColor.controlBackgroundColor)
                
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .keyboardShortcut(.escape)
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Choose Device Mockup")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Apply") {
                        if let selectedImage = selectedDeviceImage {
                            outputImage = selectedImage
                        }
                        isPresented = false
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedDeviceImage == nil)
                }
                .padding()
            }
            .frame(height: 60)
            
            Divider()
            
            // Device mockup view
            VStack(spacing: 20) {
                // Device selector
                Picker("Device", selection: $selectedDevice) {
                    ForEach(DeviceType.allCases) { device in
                        Text(device.displayName).tag(device)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 20)
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
            }
            .padding()
        }
        .frame(width: 500, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            updatePreview()
        }
    }
    
    // Private state
    @State private var selectedDevice: DeviceType = .macbook
    @State private var previewImage: NSImage?
    
    /**
     * Updates the preview image when the device type changes
     */
    private func updatePreview() {
        DispatchQueue.main.async {
            self.previewImage = ImageUtilities.createDeviceMockup(for: screenshot, deviceType: selectedDevice)
            self.selectedDeviceImage = self.previewImage
        }
    }
} 