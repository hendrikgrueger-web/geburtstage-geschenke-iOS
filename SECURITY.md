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

### Cloudflare Worker Proxy

The AI service uses a Cloudflare Worker (`Proxy/`) as a proxy to OpenRouter.
The **real OpenRouter API key** is stored as a Cloudflare Worker Secret — never in the app.

The app authenticates with the proxy using an **App Secret** via `X-App-Secret` header.

```
App → POST /chat (X-App-Secret) → Cloudflare Worker → OpenRouter API (Bearer API-Key)
```

### Local Development Setup

1. Copy `App/Secrets.xcconfig.example` → `App/Secrets.xcconfig`
2. Set `AI_PROXY_SECRET` to the App-Secret matching the Worker's `APP_SECRET`
3. `Secrets.xcconfig` is in `.gitignore` and must never be committed

### Worker Secrets (via wrangler CLI)

```bash
cd Proxy
wrangler secret put OPENROUTER_API_KEY   # real OpenRouter key
wrangler secret put APP_SECRET           # app authentication secret
wrangler deploy
```

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
