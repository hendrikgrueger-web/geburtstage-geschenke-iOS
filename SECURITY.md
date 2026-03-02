# Security and Secrets Management

## Overview
This document outlines security best practices and secrets management for ai-presents-app-ios.

## Secrets Policy

### Never Commit Secrets
The following must NEVER be committed to the repository:
- API Keys (OpenRouter, etc.)
- Bundle IDs (if sensitive)
- Provisioning Profiles
- Certificates
- Personal tokens
- Database credentials
- Any sensitive configuration data

## Environment Configuration

### OpenRouter API Key
The AI service uses OpenRouter API for gift suggestions. The API key is configured in:

**File:** `Sources/aiPresentsApp/Services/AIService.swift`
```swift
private let apiKey = "" // OpenRouter API Key - needs to be configured
```

### Local Development Setup

#### Option 1: Direct Configuration (Development Only)
For local development, you can temporarily add the API key directly to the source:

```swift
private let apiKey = "your-api-key-here" // REMOVE BEFORE COMMIT
```

⚠️ **WARNING**: Never commit this! Always remove before committing.

#### Option 2: Environment Variables (Recommended)
Use environment variables in Xcode scheme:

1. Edit Scheme → Run → Arguments → Environment Variables
2. Add: `OPENROUTER_API_KEY` = `your-key-here`

Then modify AIService.swift:
```swift
private let apiKey: String = {
    ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
}()
```

#### Option 3: xcconfig File (Team Development)
Create a `secrets.xcconfig` file (add to .gitignore):

```
OPENROUTER_API_KEY = your-api-key-here
```

Then create `secrets.example.xcconfig` (commit this):

```
OPENROUTER_API_KEY = your-openrouter-api-key-here
```

Add to Xcode scheme:
1. Project Settings → Configurations
2. Duplicate Debug → Debug-Secrets
3. Set "Based on" to Debug
4. Edit Debug-Secrets → Build Settings → User-Defined
5. Add: `OPENROUTER_API_KEY` = `$(OPENROUTER_API_KEY)`

## Production Deployment

### For App Store Distribution
For production builds, the API key must be:
1. Stored in encrypted format in the build server
2. Injected at build time
3. NEVER embedded in the compiled binary

### Using Remote Config
For better security, consider using:
- Firebase Remote Config
- Custom backend service
- Environment-specific configuration files

## iCloud/CloudKit

### CloudKit Container
The CloudKit container name is configured in your Apple Developer account:

```
iCloud.com.yourcompany.aipresentsapp
```

⚠️ **NOTE**: Container names are NOT secrets, but should be consistent across builds.

## Contacts Framework

### Privacy
The app requests Contacts framework permission. Best practices:

1. Explain why contacts access is needed (onboarding)
2. Allow users to decline and still use the app
3. Store only necessary data (name, birthday, relation)
4. Never upload contacts to external servers
5. Allow users to delete all data in Settings

## User Notifications

### Local Notifications
The app schedules local reminders. Security considerations:

1. No sensitive data in notification body
2. Use proper identifiers for notification cancellation
3. Handle user permission denial gracefully
4. Allow users to disable notifications in app

## SwiftData

### Local Storage
SwiftData stores data locally on device:

- Data is stored in SQLite format
- Location: `~/Library/Application Support/...`
- Encrypted at rest by iOS (File Data Protection)

### iCloud Sync
CloudKit sync requires:
- Proper Apple Developer account
- CloudKit entitlements configured
- User signed in to iCloud

## Code Review Checklist for Security

- [ ] No API keys, tokens, or secrets committed
- [ ] No hardcoded credentials
- [ ] Proper error handling for network requests
- [ ] Input validation on all user inputs
- [ ] Sensitive data logged (debug prints removed)
- [ ] Third-party dependencies are secure
- [ ] HTTPS used for all network requests
- [ ] Proper permission handling (Contacts, Notifications)

## Secrets Management Tools

### Recommended Tools
- **Environment Variables**: Built-in, no external dependencies
- **xcconfig Files**: Xcode-native, team-friendly
- **CocoaPods-Keys**: Easy integration, encrypted storage
- **SwiftGen**: Code generation for resources

### Security Audits
Run regular security audits:

```bash
# Scan for potential secrets in git history
git log --all --full-history --source -- "**/*.swift" | grep -i "api.*key\|token\|secret"

# Check for hardcoded credentials
grep -r "apiKey\|secret\|token\|password" Sources/ --exclude-dir=.build
```

## Incident Response

### If Secrets Are Leaked
1. **Immediate Action**: Revoke the secret
2. **Rotate Keys**: Generate new API keys
3. **Review Logs**: Check access logs for unauthorized use
4. **Update Repositories**: Remove committed secrets (use BFG or filter-repo)
5. **Notify Team**: Inform developers of the incident
6. **Document**: Document the incident and prevention measures

### Example: Remove Committed Secrets
```bash
# Using BFG Repo-Cleaner
brew install bfg
bfg --replace-text passwords.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## Compliance

### GDPR/Privacy
- User data stored locally
- No tracking/analytics (unless opted-in)
- Clear privacy policy in-app
- Right to data deletion

### Apple App Store Guidelines
- App Privacy Info configured in App Store Connect
- Clear explanation of data usage
- No deceptive data collection
- Proper permission requests

## Resources

- [Apple Security Overview](https://developer.apple.com/security/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Apple Human Interface Guidelines - Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)

---

**Last Updated:** 2026-03-02
**Version:** 1.0
