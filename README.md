# FreeScreenshot

FreeScreenshot is a macOS application that transforms dull screenshots into stunning visuals with just a few clicks.

Demo Video- https://youtu.be/oOLXdRLYA24

## Features

- Capture screenshots with Cmd+Shift+7 or drag and drop existing images
- Add beautiful backgrounds to your screenshots
- Choose from solid colors, gradients, or custom background images
- Apply 3D perspective effects for a professional look
- Export your enhanced screenshots in various formats
- Then Edit more if required in FlameShot (Download it) or Preview (Pre-installed in MacOS)
- Universal binary support for both Apple Silicon and Intel Macs

## Download 

[Download the Silicon Based Mac DMG](FreeScreenshot-silicon.dmg) 

[Download the Intel Based Mac DMG](FreeScreenshot-intel.dmg) 

> **⚠️ Caution**: Due to Financial Constraints. The application is not signed with an Apple Developer Certificate. Users may receive security warnings when trying to open the application for the first time. They can bypass this by right-clicking the app and selecting "Open" from the context menu, or by adjusting their security settings in System Preferences > Security & Privacy. For commercial distribution, consider enrolling in the [Apple Developer Program](https://developer.apple.com/programs/) to properly sign your application.

## System Requirements

- macOS 12.0 or later
- Compatible with both Apple Silicon (M1/M2/M3) and Intel-based Macs
- Xcode 13.0 or later for development

## Getting Started

### Prerequisites

- macOS 12.0 or later
- Swift 5.7 or later
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/prosamik/freescreenshot.git
cd freescreenshot
```

2. Build the universal binary:
```bash
swift build -c release --arch arm64 --arch x86_64
```

## Creating a Universal DMG

Follow these steps to create a professional universal DMG file for distribution:

1. Build the universal binary:
```bash
swift build -c release --arch arm64 --arch x86_64
```

2. Generate the application icon:
```bash
# Create iconset directory
mkdir -p AppIcon.iconset

# Copy icons with proper naming
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/16.png AppIcon.iconset/icon_16x16.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/32.png AppIcon.iconset/icon_16x16@2x.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/32.png AppIcon.iconset/icon_32x32.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/64.png AppIcon.iconset/icon_32x32@2x.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/128.png AppIcon.iconset/icon_128x128.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/256.png AppIcon.iconset/icon_128x128@2x.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/256.png AppIcon.iconset/icon_256x256.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/512.png AppIcon.iconset/icon_256x256@2x.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/512.png AppIcon.iconset/icon_512x512.png
cp freescreenshot/Assets.xcassets/AppIcon.appiconset/1024.png AppIcon.iconset/icon_512x512@2x.png

# Generate icns file
iconutil -c icns AppIcon.iconset
```

3. Create the app bundle:
```bash
# Create app bundle structure
mkdir -p FreeScreenshot.app/Contents/{MacOS,Resources}

# Copy binary and resources
cp .build/apple/Products/Release/FreeScreenshot FreeScreenshot.app/Contents/MacOS/
cp freescreenshot/Info.plist FreeScreenshot.app/Contents/
cp AppIcon.icns FreeScreenshot.app/Contents/Resources/
cp -R freescreenshot/Assets.xcassets FreeScreenshot.app/Contents/Resources/
```

4. Create the DMG:
```bash
# Create DMG structure
mkdir -p dmg_temp
cp -R FreeScreenshot.app dmg_temp/
ln -s /Applications dmg_temp/Applications

# Create DMG file
hdiutil create -volname "FreeScreenshot" -srcfolder dmg_temp -ov -format UDZO FreeScreenshot.dmg

# Clean up
rm -rf AppIcon.iconset AppIcon.icns dmg_temp FreeScreenshot.app
```

## Usage

1. Mount the DMG file
2. Drag FreeScreenshot.app to your Applications folder
3. Right-click FreeScreenshot.app and select "Open" (required first time only)
4. Press Cmd+Shift+7 to capture a screenshot, or drag and drop an image
5. Use the toolbar to select different editing tools
6. Apply backgrounds, add annotations, and enhance your screenshot
7. Click "Export" to save your masterpiece

## Dependencies

- [HotKey](https://github.com/soffes/HotKey) - For keyboard shortcut handling

## License

This project is licensed under the MIT License - see the LICENSE file for details.

```
MIT License

Copyright (c) 2025 FreeScreenshot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Acknowledgments

- Inspired by Jumpshare and other screenshot enhancement tools
- Built with SwiftUI for a native macOS experience


<div style="display: flex; width: 100%; align-items: center;">
    <a href="https://linkedin.com/in/proSamik"><img src="https://img.shields.io/github/followers/prosamik" alt="Followers" /></a>
    <a href="https://github.com/prosamik" style="margin-left: auto;"><img src="https://komarev.com/ghpvc/?username=prosamik-freescreenshot&label=Freescreenshot&count_bg=%23109BEF&title_bg=%233B3636&edge_flat=false" alt="Readme count" align="right" /></a>
</div>
  
