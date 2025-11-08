# Markdown Viewer

A feature-rich menu bar markdown viewer for macOS with multiple themes and App Sandbox support.

## Features

### File Management
✓ **Drag & drop support** - Drop .md files onto the menu bar drop zone
✓ **File picker** - Click drop zone to browse for files (Sandbox-compatible with NSOpenPanel)
✓ **Recent files (5)** - Shows date added with relative timestamps ("5m ago", "2h ago")
✓ **Show in Finder** - Quick access button for each recent file
✓ **Window surfacing** - Opening recent files brings windows to front across all apps
✓ **Window position memory** - Remembers window size and position per file

### Themes
✓ **Game Boy** - Classic retro green (#9bbc0f background, #0f380f text)
✓ **macOS** - Native system colors that adapt to Light/Dark mode
✓ **Deep Blue** - Modern blue theme (#0510F5 background, white text)

### Markdown Rendering
✓ **Rich formatting** - Bold, italic, inline code with proper syntax removal
✓ **Headers** - Six levels (H1-H6) with appropriate sizing
✓ **Code blocks** - Syntax highlighting, dark backgrounds, copy button
✓ **Lists** - Bulleted and numbered lists
✓ **Block quotes** - Styled with left border
✓ **Images** - Both local and remote images (shields.io badges, etc.)
✓ **Text selection** - All content is selectable

### Security & Permissions
✓ **App Sandbox** - Enabled with proper entitlements
✓ **Network access** - Secure remote image loading via AsyncImage
✓ **File permissions** - User-selected files and downloads folder access
✓ **Clean window management** - Proper cleanup to prevent resource leaks

### UI/UX
✓ **Persistent menu** - Click menu bar icon, stays open until closed
✓ **No auto-popup** - Manual control only
✓ **Animated drop zone** - Visual feedback with gradients and scale effects
✓ **Date tracking** - Shows when each file was added to recent files
✓ **Monospace fonts** - Consistent design throughout

## Build & Run

1. Open `MarkdownViewer.xcodeproj` in Xcode
2. Build & Run (⌘R)
3. App appears in menu bar with document icon

## Usage

### Opening Files
1. **Drag & Drop**: Drag any `.md` file onto the drop zone
2. **File Picker**: Click "or click to browse" on the drop zone
3. **Recent Files**: Click any recent file to reopen (surfaces to front)

### Changing Themes
- Select from Game Boy, macOS, or Deep Blue theme buttons
- Theme applies to newly opened windows
- Visual preview shows each theme's background color

### Managing Files
- **Show in Finder**: Click folder icon next to recent files
- **Window Management**: Close windows normally; they clean up properly
- **Recent Files**: Automatically tracks last 5 opened files with timestamps

## Requirements

- macOS 14.0+
- Xcode 15.0+
- App Sandbox enabled with network client entitlements

## Security & Privacy

This app uses App Sandbox with the following entitlements:
- `com.apple.security.app-sandbox` - Enhanced security isolation
- `com.apple.security.network.client` - Load remote images (shields.io, etc.)
- `com.apple.security.files.user-selected.read-only` - Access files you select
- `com.apple.security.files.downloads.read-only` - Access Downloads folder

## Screenshots

![Screenshot](markdown-viewer-screenshot.avif "Markdown Screenshot")

## Technical Details

- Built with SwiftUI for macOS
- NSStatusItem menu bar integration
- NSOpenPanel for sandbox-compatible file access
- AsyncImage for remote image loading
- NSWindow lifecycle management with proper cleanup
- UserDefaults for persistent settings and recent files
