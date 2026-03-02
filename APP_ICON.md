# App Icon Specifications

## Current Status
✅ **FINAL DESIGN APPROVED** — Ready for implementation (2026-03-02)

## Final Design: Gift Box with Calendar

### Visual Description

**Composition:**
- Background: Blue gradient (AppColor.primary → AppColor.primaryDark) with subtle diagonal texture
- Center: Stylized white gift box (rounded corners, soft shadow)
- Top: Birthday candle with flame (orange gradient) on the gift box lid
- Corner (top-right): Circular calendar badge showing "🎂" emoji
- Accent: Subtle confetti particles (3-5 stars/sparkles) around the gift box
- Ribbon: Orange ribbon (AppColor.accent) wrapping horizontally with a bow on top

**Color Palette (matching AppColor):**
- Background: `gradientBlue` (Blue gradient: #007AFF → #0059CC)
- Gift Box: White (#FFFFFF) with subtle drop shadow
- Candle Flame: Orange gradient (#FF9400 → #FF6600)
- Ribbon: Orange accent (#FF9400)
- Confetti: Light sparkles (#FFFFFF at 30% opacity)

**Style:**
- **Flat design** with subtle depth (2-3px shadow)
- **Rounded corners** (iOS superellipse standard, ~22% corner radius)
- **High contrast** for visibility
- **Simple, memorable** iconography
- **Apple HIG compliant**

---

## Implementation

### Option A: Using Asset Catalog in Xcode
1. Create design in Figma/Sketch/Adobe XD at 1024x1024
2. Export to PNG
3. Open `App/Assets.xcassets` (or create one)
4. Create new AppIcon asset
5. Drag and drop icon files to correct slots
6. Build and verify on device

### Option B: Using Online Generators
1. Design master icon at 1024x1024
2. Export to PNG
3. Use [AppIcon.co](https://appicon.co/) or [MakeAppIcon.com](https://makeappicon.com/)
4. Upload and download all sizes
5. Add to Asset Catalog

---

## Testing Checklist

- [ ] Icon displays correctly on home screen
- [ ] Icon displays correctly in App Store
- [ ] No pixelation on any device size
- [ ] Good contrast on light background
- [ ] Good contrast on dark background
- [ ] Recognizable at small sizes (29x29)
- [ ] Looks good in Settings app
- [ ] Approved by design review

---

## Figma/Sketch Template

### Canvas Setup (1024x1024)
```
Size: 1024 x 1024 px
Export: PNG @ 1x
Format: RGB + Alpha
```

### Layer Structure
```
Background (Rectangle)
├─ Gradient Fill (Blue)
├─ Subtle Pattern (optional)

Confetti Group (3-5 elements)
├─ Star 1 (White, 30% opacity)
├─ Star 2 (White, 25% opacity)
├─ Sparkle 1 (White, 35% opacity)

Gift Box Group
├─ Box Body (Rectangle, White, rounded)
│  ├─ Shadow (Drop Shadow, 10px, 30%)
├─ Ribbon Horizontal (Rectangle, Orange)
├─ Bow (Path/Shape, Orange)
├─ Candle (Rectangle, White)
└─ Flame (Path, Orange Gradient)

Calendar Badge (Circle)
├─ Background (White)
├─ Emoji Text ("🎂", size ~256px)
```

### Dimensions (1024x1024 canvas)
```
Gift Box: 500 x 400 px (centered)
Ribbon: 40 px height, full box width
Bow: 120 x 120 px (centered on ribbon)
Candle: 40 x 150 px (centered on top of box)
Flame: 60 x 80 px (on top of candle)
Calendar Badge: 200 x 200 px (top-right corner)
Confetti: 40-60 px each, scattered
```

---

## Related Assets

- Launch Screen: `Sources/aiPresentsApp/Views/LaunchScreen.swift`
- Color Palette: `Sources/aiPresentsApp/Resources/AppColor.swift`
- App Name: "AI Präsente"

---

## Resources

- [Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App Icon Generator Tools](https://developer.apple.com/design/human-interface-guidelines/app-icons#App-icon-resources)

---

**Last Updated:** 2026-03-02
**Status:** ✅ READY FOR IMPLEMENTATION
**Design Version:** 1.0 (Final)
