# TestFlight Release Preparation Checklist

> Use this checklist when preparing v0.2.0 Beta for TestFlight

---

## Pre-Build Checklist (Code & Project)

### Version & Build
- [ ] Update `CFBundleShortVersionString` in Info.plist to `0.2.0` ✅ (Done)
- [ ] Set automatic build numbering in Xcode
- [ ] Verify CHANGELOG.md is up to date
- [ ] Verify all tests pass locally

### Code Quality
- [ ] All tests pass (636+ test methods)
- [ ] SwiftLint passes (no critical issues)
- [ ] No compiler warnings
- [ ] Review open GitHub issues
- [ ] Verify no TODO/FIXME comments left in critical paths

### Dependencies
- [ ] Swift package dependencies resolved
- [ ] No outdated dependencies
- [ ] Verify compatible iOS deployment target (iOS 17.0+)

---

## Xcode Project Setup

### App Target Configuration
- [ ] Bundle Identifier: `com.hendrikgrueger.aiPresentsApp`
- [ ] Display Name: `AI Präsente`
- [ ] Deployment Target: iOS 17.0
- [ ] Version: 0.2.0
- [ ] Build: Auto-increment enabled

### Signing
- [ ] Development Team selected
- [ ] Provisioning Profile created
- [ ] Signing Certificate valid
- [ ] Test on physical device (not just simulator)

### Capabilities
- [ ] Contacts framework added
- [ ] Push Notifications capability
- [ ] iCloud (CloudKit) capability
- [ ] Background modes (if needed for reminders)

---

## Assets & Resources

### App Icon
- [ ] AppIcon set created in Assets.xcassets
- [ ] All sizes: 1024x1024 (App Store), 60x60@2x, 60x60@3x
- [ ] Icon follows design: APP_ICON.md
- [ ] Verify icon appears correctly on device

### Launch Screen
- [ ] Launch Screen storyboard created
- [ ] Simple, branded design
- [ ] Loads within 3 seconds

### Other Assets
- [ ] Color sets defined
- [ ] SF Symbols used (custom symbols included)
- [ ] No missing image resources

---

## Privacy & Permissions

### Info.plist
- [x] `NSContactsUsageDescription` present
- [x] `NSUserNotificationsUsageDescription` present
- [x] `NSUbiquitousContainersUsageDescription` present
- [x] Privacy Policy documentation created: `Docs/PRIVACY.md` (Deutsch) & `Docs/PRIVACY_EN.md` (English)
- [ ] Privacy Policy URL added to App Store Connect (host version or link to GitHub)
- [x] Terms of Service documentation created: `Docs/TERMS.md` (Deutsch) & `Docs/TERMS_EN.md` (English)
- [ ] Terms of Service URL added to App Store Connect (if applicable)

### App Store Privacy
- [ ] Data collection types documented
- [ ] Third-party SDK privacy info
- [ ] No sensitive data collected without consent

---

## App Store Connect Setup

### App Configuration
- [ ] App created in App Store Connect
- [ ] Bundle Identifier matches Xcode project
- [ ] SKU defined
- [ ] Name: AI Präsente / aiPresents

### Pricing & Distribution
- [ ] Price: Free (or appropriate tier)
- [ ] Availability: All countries or specific regions
- [ ] Content Rights: Verified

### Age Rating
- [ ] Age rating questionnaire completed
- [ ] Rating: 4+ (recommended)
- [ ] No objectionable content

### Metadata
- [ ] Description (German) written
- [ ] Description (English) written
- [ ] Keywords selected (iOS App Store)
- [ ] Promotional Text (max 170 characters)
- [ ] Support URL: https://github.com/harryhirsch1878/ai-presents-app-ios
- [ ] Marketing URL: (optional)
- [ ] Privacy Policy URL: (to be created)

### Screenshots
- [ ] iPhone 6.7" display (iPhone 15 Pro Max) - min 2
- [ ] iPhone 6.5" display (iPhone 14 Pro Max)
- [ ] iPhone 5.5" display
- [ ] Screenshots show core features:
  - [ ] Timeline view
  - [ ] Person detail view
  - [ ] Gift ideas list
  - [ ] Settings screen
  - [ ] AI suggestions
- [ ] No beta content or pre-release features shown

---

## Build & Test

### Archive Build
- [ ] Clean build folder (Cmd+Shift+K)
- [ ] Archive for TestFlight (Product → Archive)
- [ ] Archive validation successful
- [ ] No build warnings or errors
- [ ] Archive size is reasonable (< 50MB target)

### TestFlight Upload
- [ ] Upload archive to App Store Connect
- [ ] Upload completes successfully
- [ ] Processing completes (usually 5-15 minutes)
- [ ] Build appears in TestFlight section

---

## TestFlight Configuration

### Beta Testing
- [ ] Test information written
- [ ] What's New notes (German & English)
- [ ] Beta App Description
- [ ] Feedback URL set

### Testers
- [ ] Internal testers added
- [ ] External tester group created
- [ ] Tester invite email draft ready

---

## Beta Distribution

### Internal Testing
- [ ] Distribute to internal testers
- [ ] Internal testers test and approve
- [ ] Critical bugs fixed before external testing

### External Testing
- [ ] Distribute to external beta testers
- [ ] Share BETA_TESTERS.md with testers
- [ ] Feedback channels configured
- [ ] Monitor crash reports

---

## Post-Release

### Monitoring
- [ ] Set up crash reporting (Xcode Organizer)
- [ ] Monitor App Store Connect analytics
- [ ] Respond to tester feedback promptly
- [ ] Track known issues

### Next Version Planning
- [ ] Create v0.3.0 issue/branch
- [ ] Update ROADMAP.md
- [ ] Prioritize tester feedback

---

## Quick Reference

### Build Commands
```bash
# Resolve dependencies
swift package resolve

# Run tests
swift test

# Create archive (in Xcode)
Product → Archive
```

### File Locations
- App Icon Design: `APP_ICON.md`
- TestFlight Guide: `TESTFLIGHT.md`
- Beta Tester Guide: `BETA_TESTERS.md`
- Documentation: `Docs/` folder

### Version History
- v0.1.0: Initial MVP (2026-03-02)
- v0.2.0: TestFlight Beta (current)
- v0.3.0: Widget & Siri (planned)

---

## Contact & Support

- **GitHub Issues**: https://github.com/harryhirsch1878/ai-presents-app-ios/issues
- **Email**: harryhirsch1878@gmail.com
- **Documentation**: See `Docs/` folder

---

Last updated: 2026-03-02
Version: 0.2.0 Beta
