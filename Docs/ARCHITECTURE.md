# Architecture — ai-presents-app-ios

## Stack
- SwiftUI
- SwiftData
- CloudKit sync
- Contacts.framework
- UserNotifications
- OpenRouter API client (modular, optional)

## Modules
- ContactsImport
- BirthdayTimeline
- GiftIdeas
- ReminderScheduler
- AIAdvisor
- Settings/Privacy

## Data Model
- PersonRef(id, contactIdentifier, displayName, birthday, relation, updatedAt)
- GiftIdea(id, personId, title, note, budgetMin, budgetMax, link, status, tags, createdAt)
- GiftHistory(id, personId, title, category, year)
- ReminderRule(id, leadDays[], quietHours, enabled)

## Privacy-by-design
- Minimal field ingest from Contacts
- No raw addressbook export
- AI calls only with reduced, user-visible payload
- AI opt-in per feature
