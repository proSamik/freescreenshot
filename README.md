# FreeScreenshot

FreeScreenshot is a macOS application that transforms dull screenshots into stunning visuals with just a few clicks.

## Features

- Capture screenshots with Cmd+Shift+7 or drag and drop existing images
- Add beautiful backgrounds to your screenshots
- Choose from solid colors, gradients, or custom background images
- Apply 3D perspective effects for a professional look
- Export your enhanced screenshots in various formats
- Then Edit more if required in FlameShot (Download it) or Preview (Pre-installed in MacOS)

## Download 

[Download the .dmg](FreeScreenshot.dmg) 

> **⚠️ Caution**: Due to Financial Constraints. The application is not signed with an Apple Developer Certificate. Users may receive security warnings when trying to open the application for the first time. They can bypass this by right-clicking the app and selecting "Open" from the context menu, or by adjusting their security settings in System Preferences > Security & Privacy. For commercial distribution, consider enrolling in the [Apple Developer Program](https://developer.apple.com/programs/) to properly sign your application.

## Getting Started

### Prerequisites

- macOS 12.0 or later
- Xcode 13.0 or later for development

### Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run the application

```bash
git clone https://github.com/prosamik/freescreenshot.git
cd freescreenshot
open freescreenshot.xcodeproj
```

## Usage

1. Launch the application
2. Press Cmd+Shift+7 to capture a screenshot, or drag and drop an image
3. Use the toolbar to select different editing tools
4. Apply backgrounds, add annotations, and enhance your screenshot
5. Click "Export" to save your masterpiece

## Creating a Distribution DMG

Follow these steps to create a professional DMG file for distributing the application:

### Prerequisites

- Xcode installed
- [Homebrew](https://brew.sh/) installed
- create-dmg utility (installed via Homebrew)

### Installation Steps

1. Install the create-dmg utility:

```bash
brew install create-dmg
```

2. Build the application in Release mode:

```bash
cd /path/to/freescreenshot
xcodebuild -configuration Release -scheme freescreenshot
```

3. Create the DMG file with drag-to-install behavior:

```bash
create-dmg \
  --volname "FreeScreenshot" \
  --volicon "/path/to/DerivedData/freescreenshot-xxx/Build/Products/Release/freescreenshot.app/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "freescreenshot.app" 150 190 \
  --hide-extension "freescreenshot.app" \
  --app-drop-link 450 190 \
  ~/Desktop/FreeScreenshot.dmg \
  /path/to/DerivedData/freescreenshot-xxx/Build/Products/Release/
```

Note: Replace `/path/to/DerivedData/freescreenshot-xxx` with your actual DerivedData path, which can be found by running:

```bash
find ~/Library/Developer/Xcode/DerivedData -name "freescreenshot*" -type d
```

## Dependencies

- [HotKey](https://github.com/soffes/HotKey) - For keyboard shortcut handling

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by Jumpshare and other screenshot enhancement tools
- Built with SwiftUI for a native macOS experience 