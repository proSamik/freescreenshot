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
import ServiceManagement

/**
 * Main application class that sets up the UI and keyboard shortcuts
 */
@main
struct FreeScreenshotApp: App {
    @StateObject private var appState = AppState.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /**
     * Defines the app's UI scene
     */
    var body: some Scene {
        // Use Settings scene instead of WindowGroup to support menu bar app
        Settings {
            ContentView()
                .environmentObject(self.appState)
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
    // Use a strong property for the status item so it can't be deallocated
    private(set) var statusItem: NSStatusItem! = nil
    private var hotkey: HotKey?
    
    // Keep strong references to windows to prevent them from being deallocated
    private var launcherWindowController: NSWindowController?
    private var windowDelegates = [NSWindowDelegate]()
    
    // Keep a reference to the app state
    private let appState = AppState.shared
    
    /**
     * Called when the application finishes launching
     * Requests necessary permissions for screen capture
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from Dock - set this first thing
        NSApp.setActivationPolicy(.accessory)
        
        // Request screen recording permission
        let screenCaptureAccess = CGPreflightScreenCaptureAccess()
        if !screenCaptureAccess {
            let granted = CGRequestScreenCaptureAccess()
            print("Screen capture access requested: \(granted)")
        } else {
            print("Screen capture access already granted")
        }
        
        // Set up the status bar item
        setupStatusBarItem()
        
        // Set up global hotkey for taking screenshots (Cmd+Shift+7)
        setupHotkey()
        
        // Configure app to launch at login
        setupLoginItem()
        
        // Check if app was launched directly (not reactivated)
        // This could be from Spotlight, Finder, or first launch
        if NSApp.windows.isEmpty {
            // Open the launcher window when app is first launched
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openLauncher()
            }
        }
    }
    
    /**
     * Called when app is about to terminate
     * Only happens with explicit quit, not window close
     */
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources before exit
        print("Application is terminating")
        // Additional cleanup if needed
    }
    
    /**
     * Prevent the app from quitting when all windows are closed
     */
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    /**
     * Handle reactivation of the app (when icon is clicked in Dock if visible)
     */
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // If no windows visible, open the launcher
            openLauncher()
        }
        return true
    }
    
    /**
     * Sets up the status bar (menu bar) item with icon and menu
     */
    private func setupStatusBarItem() {
        // Create a status item with fixed length to ensure it's visible
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            // Use standard template image that works well in both light and dark mode
            button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "FreeScreenshot")
            
            // Create the menu
            let menu = NSMenu()
            
            menu.addItem(NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Open Launcher", action: #selector(openLauncher), keyEquivalent: ""))
            
            menu.addItem(NSMenuItem.separator())

            menu.addItem(NSMenuItem(title: "Configuration", action: #selector(showConfiguration), keyEquivalent: ""))
            
            menu.addItem(NSMenuItem.separator())
            
            // menu.addItem(NSMenuItem(title: "Check for updates", action: #selector(checkForUpdates), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem.menu = menu
        }
    }
    
    /**
     * Sets up the global hotkey for taking screenshots
     */
    private func setupHotkey() {
        hotkey = HotKey(key: .seven, modifiers: [.command, .shift])
        
        // Set up the hotkey action
        hotkey?.keyDownHandler = { [weak self] in
            self?.takeScreenshot()
        }
    }
    
    /**
     * Configure the app to launch at login
     */
    private func setupLoginItem() {
        // Check if already configured
        if !isLoginItemEnabled() {
            toggleLaunchAtLogin()
        }
    }
    
    /**
     * Checks if the app is configured to launch at login
     */
    private func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            // Use the modern API for macOS 13+
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older macOS versions, we can't reliably check without using deprecated APIs
            // This is a best-effort approach that doesn't trigger deprecation warnings
            if let bundleID = Bundle.main.bundleIdentifier {
                // Use FileManager to check if the launch agent plist exists
                let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
                let launchAgentsURL = libraryURL?.appendingPathComponent("LaunchAgents")
                let plistPath = launchAgentsURL?.appendingPathComponent("\(bundleID).plist")
                
                return plistPath != nil && FileManager.default.fileExists(atPath: plistPath!.path)
            }
            return false
        }
    }
    
    /**
     * Toggle whether the app launches at login
     */
    @objc private func toggleLaunchAtLogin() {
        if let bundleID = Bundle.main.bundleIdentifier {
            let loginItemEnabled = !isLoginItemEnabled()
            
            if loginItemEnabled {
                // Using the API available in macOS 13+
                if #available(macOS 13.0, *) {
                    do {
                        try SMAppService.mainApp.register()
                    } catch {
                        print("Error registering login item: \(error)")
                    }
                } else {
                    // Fall back to older API for older macOS versions
                    let helper = SMLoginItemSetEnabled(bundleID as CFString, true)
                    print("Login item status: \(helper)")
                }
            } else {
                if #available(macOS 13.0, *) {
                    do {
                        try SMAppService.mainApp.unregister()
                    } catch {
                        print("Error unregistering login item: \(error)")
                    }
                } else {
                    // Fall back to older API for older macOS versions
                    let helper = SMLoginItemSetEnabled(bundleID as CFString, false)
                    print("Login item status: \(helper)")
                }
            }
            
            // Update menu item state
            if let menu = statusItem?.menu {
                for item in menu.items {
                    if item.title == "Launch at Login" {
                        item.state = loginItemEnabled ? .on : .off
                    }
                }
            }
        }
    }
    
    /**
     * Captures a screenshot when triggered from menu or hotkey
     */
    @objc private func takeScreenshot() {
        // Use the singleton AppState
        AppState.shared.initiateScreenCapture()
    }
    
    /**
     * Open launcher window
     */
    @objc private func openLauncher() {
        // Switch to regular activation policy before showing window
        NSApp.setActivationPolicy(.regular)
        
        // If we already have a launcher window controller, just show its window
        if let windowController = launcherWindowController, let window = windowController.window {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        // Otherwise check if a launcher window is already open
        for window in NSApplication.shared.windows {
            if window.title == "FreeScreenshot Launcher" {
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                return
            }
        }
        
        // Create a new window with ContentView using the shared AppState singleton
        let contentView = ContentView()
            .environmentObject(AppState.shared)
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Set up window properties
        window.contentViewController = hostingController
        window.title = "FreeScreenshot Launcher"
        window.center()
        
        // Create a window delegate and keep a strong reference to it
        let windowDelegate = WindowDelegate()
        windowDelegates.append(windowDelegate)
        window.delegate = windowDelegate
        
        // Create a window controller to manage the window lifecycle
        let windowController = NSWindowController(window: window)
        launcherWindowController = windowController
        
        windowController.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    
    /**
     * Show configuration settings
     */
    @objc private func showConfiguration() {
        // Create and display a configuration window with settings
        let configMenu = NSMenu(title: "Configuration")
        
        // Add Launch at Login toggle
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = isLoginItemEnabled() ? .on : .off
        configMenu.addItem(launchAtLoginItem)
        
        // Add other configuration options here
        configMenu.addItem(NSMenuItem(title: "Keyboard Shortcuts", action: #selector(configureShortcuts), keyEquivalent: ""))
        configMenu.addItem(NSMenuItem(title: "Upload Settings", action: #selector(configureUpload), keyEquivalent: ""))
        
        // Position and display the menu
        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(configMenu, with: event, for: NSApp.mainWindow?.contentView ?? NSView())
        }
    }
    
    /**
     * Configure keyboard shortcuts
     */
    @objc private func configureShortcuts() {
        // Placeholder for keyboard shortcuts configuration
        print("Configure keyboard shortcuts")
    }
    
    /**
     * Configure upload settings
     */
    @objc private func configureUpload() {
        // Placeholder for upload settings configuration
        print("Configure upload settings")
    }
    
    /**
     * Check for app updates
     */
    @objc private func checkForUpdates() {
        // Placeholder for update checking functionality
        print("Check for updates")
    }
    
    /**
     * Show about information
     */
    @objc private func showAbout() {
        // Display about information
        let alert = NSAlert()
        alert.messageText = "FreeScreenshot"
        alert.informativeText = "Version 1.0\n© 2025 Samik Choudhury"
        alert.runModal()
    }
}

/**
 * AppState: Manages the central state of the application
 * Handles screenshot capture process and maintains editor state
 */
class AppState: ObservableObject {
    // Shared instance for the application
    static let shared = AppState()
    
    @Published var isCapturingScreen = false
    @Published var capturedImage: NSImage?
    @Published var isEditorOpen = false
    
    // Keep strong references to prevent deallocation
    private var editorWindowController: NSWindowController?
    private var windowDelegates = [NSWindowDelegate]()
    
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
        
        // Ensure the status item remains visible
        DispatchQueue.main.async {
            // Make sure we're in accessory mode before starting capture
            NSApp.setActivationPolicy(.accessory)
            
            // Force the status item to refresh by toggling its length
            if let appDelegate = NSApp.delegate as? AppDelegate, 
               let statusItem = appDelegate.statusItem {
                let currentLength = statusItem.length
                statusItem.length = currentLength + 0.1
                statusItem.length = currentLength
            }
        }
        
        // Close the main window temporarily if it's open
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
                    
                    // Create and show a new editing window
                    self.showEditingWindow(with: image)
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
    
    /**
     * Shows a new window for editing the captured screenshot
     */
    private func showEditingWindow(with image: NSImage) {
        // Switch to regular activation policy before showing editor window
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
        }
        
        let editorViewModel = EditorViewModel()
        editorViewModel.setImage(image)
        
        let editorView = EditorView(viewModel: editorViewModel)
        let hostingController = NSHostingController(rootView: editorView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Set up window properties
        window.contentViewController = hostingController
        window.title = "Screenshot Editor"
        window.center()
        
        // Create a window delegate and keep a strong reference to it
        let windowDelegate = WindowDelegate()
        windowDelegates.append(windowDelegate)
        window.delegate = windowDelegate
        
        // Create a window controller to manage the window lifecycle
        let windowController = NSWindowController(window: window)
        editorWindowController = windowController
        
        windowController.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

/**
 * WindowDelegate: Handles window close events to prevent app termination
 */
class WindowDelegate: NSObject, NSWindowDelegate {
    /**
     * Called when the window close button is clicked
     * Just hides the window instead of allowing it to be destructively closed
     */
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Don't actually close the window, just hide it
        sender.orderOut(nil)
        
        // Force activation policy to accessory (menu bar only) after a slight delay
        // This ensures all animations complete and app UI state is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Double-check if any windows are still visible
            let visibleWindows = NSApp.windows.filter { 
                $0.isVisible && !($0 is NSPanel) && $0.title != "" 
            }
            
            if visibleWindows.isEmpty {
                // If no visible windows, set app back to accessory mode (menu bar only)
                NSApp.setActivationPolicy(.accessory)
                
                // Force hide dock icon by activating another app briefly then coming back
                if let finder = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.finder" }) {
                    finder.activate(options: .activateIgnoringOtherApps)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
        }
        
        // Return false to prevent the default close behavior
        return false
    }
    
    /**
     * Called when the window becomes key (active)
     * Ensure app is visible in Dock while windows are open
     */
    func windowDidBecomeKey(_ notification: Notification) {
        // When a window becomes active, make sure app is visible
        NSApp.setActivationPolicy(.regular)
    }
}
