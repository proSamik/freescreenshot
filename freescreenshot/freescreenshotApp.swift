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

/**
 * Main application class that sets up the UI and keyboard shortcuts
 */
@main
struct FreeScreenshotApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /**
     * Defines the app's UI scene
     */
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.appState)
                .onAppear {
                    // Ensure window is properly sized and visible
                    DispatchQueue.main.async {
                        if let window = NSApplication.shared.windows.first {
                            window.setContentSize(NSSize(width: 800, height: 600))
                            window.center()
                            window.makeKeyAndOrderFront(nil)
                            NSApplication.shared.activate(ignoringOtherApps: true)
                        }
                    }
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Take Screenshot") {
                    self.appState.initiateScreenCapture()
                }
                .keyboardShortcut("7", modifiers: [.command, .shift])
            }
        }
    }
}

/**
 * AppDelegate: Handles application lifecycle events and permissions
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    /**
     * Called when the application finishes launching
     * Requests necessary permissions for screen capture
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request screen recording permission
        let screenCaptureAccess = CGPreflightScreenCaptureAccess()
        if !screenCaptureAccess {
            let granted = CGRequestScreenCaptureAccess()
            print("Screen capture access requested: \(granted)")
        } else {
            print("Screen capture access already granted")
        }
        
        // Set up global hotkey for taking screenshots (Cmd+Shift+7)
        setupHotkey()
    }
    
    /**
     * Sets up the global hotkey for taking screenshots
     */
    private func setupHotkey() {
        let hotkey = HotKey(key: .seven, modifiers: [.command, .shift])
        
        // Set up the hotkey action
        hotkey.keyDownHandler = {
            if let appState = NSApplication.shared.windows.first?.contentViewController?.view.window?.windowController?.contentViewController?.representedObject as? AppState {
                appState.initiateScreenCapture()
            } else {
                // Fallback if we can't access the AppState directly
                NotificationCenter.default.post(name: Notification.Name("TakeScreenshot"), object: nil)
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
    
    init() {
        // Listen for screenshot notifications from global hotkey
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenshotNotification), name: Notification.Name("TakeScreenshot"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleScreenshotNotification() {
        initiateScreenCapture()
    }
    
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
                        NSApplication.shared.activate(ignoringOtherApps: true)
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
