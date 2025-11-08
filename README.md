# Markdown Viewer

Game Boy themed menu bar markdown reader for macOS.

## Features

### Core Functionality
✓ **Persistent menu** - Click to open, stays open until X button clicked
✓ **Drag & drop** - Drop .md files to open in new windows
✓ **Recent files (5)** - Shows last modified time with "Show in Finder" button
✓ **Window state** - Remembers position and size per file
✓ **No auto-popup** - Manual control only

### Markdown Support
✓ **Headers** - All 6 levels with appropriate sizing
✓ **Text formatting** - Bold, italic, inline code with syntax highlighting
✓ **Lists** - Bullet and numbered lists
✓ **Block quotes** - Styled with left border and indentation
✓ **Code blocks** - Syntax highlighting with copy button
✓ **Images** - Local images rendered, remote images displayed as formatted text
✓ **Text selection** - All content selectable

### Themes
✓ **Game Boy** - Classic green palette (default)
✓ **macOS** - System colors
✓ **Deep Blue** - High contrast blue theme

## Build & Run

1. Open `MarkdownViewer.xcodeproj` in Xcode
2. Build & Run (Cmd+R)

## Usage

1. Click menu bar icon - menu stays open
2. Drag .md file to drop zone
3. Click X to close menu
4. Recent files show "5m ago", "2h ago", etc.

## Requirements

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## File Preview

![Screenshot](markdown-viewer-screenshot.avif "Markdown Screenshot")
