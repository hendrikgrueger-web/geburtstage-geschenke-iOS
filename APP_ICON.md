# App Icon Specifications

## Current Status
⚠️ App Icon NOT IMPLEMENTED YET

## Requirements

### Sizes Required
The following sizes are required for iOS app icons:

| Size | Usage | File |
|------|-------|------|
| 1024x1024 | App Store | `Icon-AppStore-1024x1024.png` |
| 512x512 | iTunes Artwork | `Icon-iTunesArtwork-512x512.png` |
| 256x256 | iPad Settings | `Icon-iPadSettings-256x256.png` |
| 128x128 | iPad Settings (2x) | `Icon-iPadSettings-128x128.png` |
| 180x180 | iPhone App (3x) | `Icon-App-60x60@3x.png` |
| 167x167 | iPad Pro App (2x) | `Icon-App-83.5x83.5@2x.png` |
| 152x152 | iPad App (2x) | `Icon-App-76x76@2x.png` |
| 144x144 | iPad Pro App (2x) | `Icon-App-72x72@2x.png` |
| 120x120 | iPhone App (2x) | `Icon-App-60x60@2x.png` |
| 114x114 | iPhone App (2x) | `Icon-App-57x57@2x.png` |
| 76x76 | iPad App (1x) | `Icon-App-76x76.png` |
| 72x72 | iPad App (1x) | `Icon-App-72x72.png` |
| 60x60 | iPhone App (2x) | `Icon-App-60x60.png` |
| 57x57 | iPhone App (1x) | `Icon-App-57x57.png` |
| 40x40 | iPhone Notification (2x) | `Icon-Notification-40x40@2x.png` |
| 29x29 | iPhone Settings (2x) | `Icon-Small-30x30@2x.png` |
| 20x20 | iPhone Notification (2x) | `Icon-Small-20x20@2x.png` |

### Design Guidelines

#### Concept
The app icon should represent:
- **Birthdays** 🎂 / 🎉
- **Gift Ideas** 🎁
- **Reminders** ⏰ / 🔔
- **Apple-style aesthetics**

#### Color Palette
- Primary: Blue gradient (matching AppColor.primary)
- Accent: Warm orange (AppColor.accent)
- Background: Clean white/light gray

#### Style
- **Flat design** with subtle depth
- **Rounded corners** (iOS standard)
- **High contrast** for visibility
- **Simple, memorable** iconography

## Design Ideas

### Option 1: Gift Box with Calendar
- Gift box icon with birthday cake on top
- Calendar overlay showing date
- Blue gradient background
- Orange accent on gift ribbon

### Option 2: Birthday Cake with Bell
- Simple birthday cake illustration
- Notification bell icon
- Celebratory confetti elements
- Blue background with orange sparkles

### Option 3: Abstract Gift
- Stylized gift box shape
- Minimalist calendar elements
- Gradient colors from blue to purple
- Subtle shadow for depth

## Implementation Steps

### Using Asset Catalog in Xcode
1. Open `App/Assets.xcassets`
2. Create new AppIcon asset
3. Drag and drop icon files to correct slots
4. Build and verify on device

### Using Online Generators
- [AppIcon.co](https://appicon.co/)
- [MakeAppIcon.com](https://makeappicon.com/)
- [AppIconGenerator.com](https://www.appicongenerator.com/)

### From Figma/Sketch
1. Design master icon at 1024x1024
2. Export to PNG
3. Use generator tool to create all sizes
4. Add to Asset Catalog

## Testing Checklist

- [ ] Icon displays correctly on home screen
- [ ] Icon displays correctly in App Store
- [ ] No pixelation on any device size
- [ ] Good contrast on light background
- [ ] Good contrast on dark background (if applicable)
- [ ] Recognizable at small sizes (29x29)
- [ ] Looks good in Settings app
- [ ] Approved by design review

## Related Assets

- Launch Screen: See `LaunchScreen.storyboard` specs
- Color Palette: See `Sources/aiPresentsApp/Resources/AppColor.swift`

## Resources

- [Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App Icon Generator Tools](https://developer.apple.com/design/human-interface-guidelines/app-icons#App-icon-resources)

---

**Last Updated:** 2026-03-02
**Status:** PENDING IMPLEMENTATION
