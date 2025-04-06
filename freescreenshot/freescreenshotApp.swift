//
//  freescreenshotApp.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import SwiftUI
import Cocoa
import HotKey
import Carbon.HIToolbox

@main
struct FreeScreenshotApp: App {
    @StateObject private var appState = AppState()
    private var screenshotHotkey: HotKey?
    
    init() {
        // Initialize the screenshot hotkey (Cmd+Shift+7)
        screenshotHotkey = HotKey(key: .seven, modifiers: [.command, .shift])
        
        // Set up the hotkey action
        screenshotHotkey?.keyDownHandler = {Fix
            appState.initiateScreenCapture()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Take Screenshot") {
                    appState.initiateScreenCapture()
                }
                .keyboardShortcut("7", modifiers: [.command, .shift])
            }
        }
    }
}

/**
 * AppState: Manages the central state of the application
 * Handles screenshot capture process and maintains editor state
 */
class AppState: ObservableObject {
    @Published var isCapturingScreen = false
    @Published var capturedImage: NSImage?
    @Published var isEditorOpen = false
    
    /**
     * Initiates the screen capture process
     * Activates crosshair selection tool for user to select screen area
     */
    func initiateScreenCapture() {
        isCapturingScreen = true
        
        // Close the main window temporarily
        if let window = NSApplication.shared.windows.first {
            window.orderOut(nil)
        }
        
        // Give time for window to close before capturing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.captureScreenWithSelection()
        }
    }
    
    /**
     * Captures screen with selection using native macOS APIs
     * Creates a crosshair selection tool for the user to select an area
     */
    private func captureScreenWithSelection() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-s", "-c"] // Interactive, Selection, to Clipboard
        
        task.terminationHandler = { process in
            DispatchQueue.main.async {
                self.isCapturingScreen = false
                
                // Get image from clipboard
                if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                    self.capturedImage = image
                    self.isEditorOpen = true
                    
                    // Reopen the main window
                    if let window = NSApplication.shared.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
        }
        
        do {
            try task.run()
        } catch {
            print("Error capturing screenshot: \(error)")
            self.isCapturingScreen = false
        }
    }
}
