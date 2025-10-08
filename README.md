# WindowCloak

<div align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2012.3+-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
</div>

A privacy-focused macOS application that selectively hides specific applications from screen sharing sessions while keeping them visible and usable on your local display. All processing happens locally, no data leaves your machine.

Perfect for any screen sharing scenario where you need to:
- Keep reference materials (notes apps, documentation) open but hidden from viewers
- Maintain privacy for specific applications during screen sharing
- Share your full workflow without revealing sensitive information

https://github.com/user-attachments/assets/172a67b2-f5d4-4268-86ab-52e7e639cdab

## 📋 Requirements

- macOS 12.3 (Monterey) or later
- Screen Recording permission (granted on first launch)

## 🚀 Getting Started

### Installation

1. Go to the [Releases page](https://github.com/Orogenesis/WindowCloak/releases)
2. Download the latest version: **WindowCloak-X.X.X-macos.dmg**
3. Open the downloaded DMG file
4. Drag **WindowCloak** to the **Applications** folder
5. Eject the DMG

Since the app isn't code-signed by Apple, macOS will quarantine it after download. To unblock it:

```bash
xattr -dr com.apple.quarantine /Applications/WindowCloak.app
```

Alternatively, open **System Settings → Privacy & Security** and click **"Open Anyway"** next to the blocked app message.

After unblocking once, you can launch it normally.

### First Launch

1. **Grant Permissions**: On first launch, you'll be prompted to grant Screen Recording permission
   - Open System Settings > Privacy & Security > Screen Recording
   - Enable WindowCloak

2. **Configure Hidden Apps**:
   - Click Settings
   - Go to Applications tab
   - Click "Add Application"
   - Select apps you want to hide

Configuration is automatically persisted to:
```
~/Library/Application Support/com.windowcloak/configuration.json
```

3. **Start Capture**:
   - Click "Start Capture"
   - The preview window shows your filtered screen
   - When sharing in your video conferencing app, share the "WindowCloak Preview" window, not "Share entire screen"

### Building from Source (For Developers)

If you want to build the app yourself:

**Requirements:**
- Xcode 14.0 or later
- Swift 5.9 or later

**Steps:**

1. Clone the repository:
```bash
git clone https://github.com/Orogenesis/WindowCloak.git
cd WindowCloak/WindowCloak
```

2. Build and run:
```bash
make run
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for privacy-conscious developers.
