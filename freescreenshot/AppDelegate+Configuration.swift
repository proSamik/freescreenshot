//
//  AppDelegate+Configuration.swift
//  freescreenshot
//
//  Created by Samik Choudhury on 06/04/25.
//

import Cocoa

/**
 * Extension for handling app permissions persistently
 */
extension AppDelegate {
    
    /**
     * Saves the current permissions state to UserDefaults
     * This helps track if permissions were previously granted
     */
    func savePermissionState(granted: Bool) {
        UserDefaults.standard.set(granted, forKey: "ScreenCapturePermissionGranted")
        UserDefaults.standard.synchronize()
    }
    
    /**
     * Checks if permissions were previously granted
     */
    func wasPermissionPreviouslyGranted() -> Bool {
        return UserDefaults.standard.bool(forKey: "ScreenCapturePermissionGranted")
    }
    
    /**
     * Ensures screen capture permission is properly saved in TCC database
     * This function takes a more robust approach to macOS permissions
     */
    func ensureScreenCapturePermission() {
        // Check current permission status
        let screenCaptureAccess = CGPreflightScreenCaptureAccess()
        
        if !screenCaptureAccess {
            // We don't have permission - need to request it
            showPermissionAlert()
        } else {
            print("Screen capture access is already granted")
            
            // Even with permission, we need to verify it's working correctly
            // Schedule a test capture after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.verifyPermissionWorks()
            }
        }
    }
    
    /**
     * Shows an alert explaining the permission requirements
     */
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "FreeScreenshot needs screen recording permission to capture screenshots. You'll be prompted to grant this permission in System Settings.\n\nIf you've already granted permission but still see this message, you may need to manually add this application in System Settings > Privacy & Security > Screen Recording."
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Open System Settings")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // User chose to continue - request the permission
            requestPermission()
        } else {
            // User chose to open System Settings
            openScreenRecordingPreferences()
        }
    }
    
    /**
     * Requests screen recording permission from macOS
     */
    private func requestPermission() {
        let granted = CGRequestScreenCaptureAccess()
        print("Screen capture access requested: \(granted)")
        
        if granted {
            // Permission was granted - verify it works after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.verifyPermissionWorks()
            }
        } else {
            // Permission was denied - show another alert
            DispatchQueue.main.async {
                self.showPermissionDeniedAlert()
            }
        }
    }
    
    /**
     * Shows an alert if permission was denied
     */
    private func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Permission Denied"
        alert.informativeText = "FreeScreenshot cannot function without screen recording permission. Please enable it in System Settings > Privacy & Security > Screen Recording."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openScreenRecordingPreferences()
        }
    }
    
    /**
     * Verifies that the permission actually works by trying a screen capture
     */
    private func verifyPermissionWorks() {
        // Use the native screencapture tool to test if permission is working
        let tempFilePath = NSTemporaryDirectory() + "permission_test.png"
        let tempFileURL = URL(fileURLWithPath: tempFilePath)
        
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        
        // Capture a small region of the screen to minimize disruption
        // -R: region (x,y,width,height)
        // -x: no sound
        task.arguments = ["-R", "0,0,1,1", "-x", tempFilePath]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // Check if the file exists and has a size
            if FileManager.default.fileExists(atPath: tempFilePath) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: tempFilePath)[.size] as? NSNumber ?? 0
                
                if fileSize.intValue > 0 {
                    print("Permission verified: successfully captured screen")
                    
                    // Clean up the temporary file
                    try? FileManager.default.removeItem(at: tempFileURL)
                } else {
                    print("Permission issue: capture file exists but is empty")
                    showPermissionIssueAlert()
                }
            } else {
                print("Permission issue: failed to create capture file")
                showPermissionIssueAlert()
            }
        } catch {
            print("Error testing permission: \(error)")
            showPermissionIssueAlert()
        }
    }
    
    /**
     * Shows an alert if permission was granted but doesn't seem to work
     */
    private func showPermissionIssueAlert() {
        let alert = NSAlert()
        alert.messageText = "Permission Issue Detected"
        alert.informativeText = "The app has permission to capture your screen, but the capture doesn't seem to be working correctly. This might be fixed by:\n\n1. Removing FreeScreenshot from Screen Recording in System Settings, then adding it back\n2. Restarting your Mac\n3. Reinstalling the application"
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openScreenRecordingPreferences()
        }
    }
    
    /**
     * Opens System Settings to the Screen Recording privacy settings
     */
    private func openScreenRecordingPreferences() {
        // Modern URL scheme for macOS 13+
        var url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        
        // Fallback for older macOS versions
        if #available(macOS 13.0, *) {
            // Using modern URL scheme
        } else {
            // Older URL scheme
            let prefPane = "com.apple.preference.security"
            url = URL(string: "x-apple.systempreferences:\(prefPane)")!
        }
        
        NSWorkspace.shared.open(url)
    }
} 