# LazyWindowManager
A Linux-style window manipulation tool for Windows, written in AutoHotkey v2.
\
Move and resize windows from anywhere (not just the title bar), even with one-handed mouse gestures.

## Features

### 🖱️ Primary Modes

- **Win + Left Click**: Move any window by dragging from anywhere on the window
- **Win + Right Click**: Resize windows intelligently
  - **Edge zones** (outer 30%): Resize from the clicked edge or corner
  - **Center zone** (inner 70%): Resize from all sides simultaneously, keeping the window centered

### 🎯 Trigger Mode (One-Handed Operation aka Lazy mode)

- **Middle Double-Click** on any window to activate trigger mode for that window, on desktop to activate for any window
  - Visual feedback: colored borders on Desktop while active
  - Left/Right clicks now work as if the Win key is pressed
  - Perfect for trackpad/laptop users or one-handed operation
  - Automatically deactivates when clicking a different window or on single middle-click

## Installation

1. Install [AutoHotkey v2](https://www.autohotkey.com/) (v2.0 or later required)
2. Download [lazywindowmanager.ahk](./lazywindowmanager.ahk) from this repository
3. Double-click the script to run it
4. (Optional) Add to Windows Startup folder for automatic launch

## Usage

### Moving Windows

**Method 1: Keyboard + Mouse**
- Hold `Win` key
- Click and drag anywhere on the window with left mouse button

**Method 2: Trigger Mode**
- Double-click middle mouse button on a window
- Now simply click and drag with left button (no Win key needed)

### Resizing Windows

**Method 1: Keyboard + Mouse**
- Hold `Win` key
- Right-click on the window:
  - Click near edges/corners to resize from that side
  - Click in the center to resize from all sides (centered resize)

**Method 2: Trigger Mode**
- Double-click middle mouse button on a window
- Right-click to resize (same edge/center logic applies)

### Keyboard Shortcuts

- `Ctrl + Alt + Q`: Force exit the script

## Compatibility

- **OS**: Tested on Windows 11 25H2

## Contributing

Contributions are welcome! Feel free to:
- Report bugs via Issues
- Submit Pull Requests for improvements
- Suggest new features

## License

This project is open source. Feel free to use, modify, and distribute as needed.

## Credits

Inspired by window manipulation features found in various Linux desktop environments (GNOME, KDE, i3, etc.).
