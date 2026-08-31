# Pluto Product Requirements Document

## 1. Product Summary

Pluto is a cross-platform audio note-taking application built with Flutter. It helps users capture thoughts, reminders, ideas, meetings, lectures, and personal reflections quickly through voice instead of typing. The app combines real-time audio recording, reliable playback, intelligent organization, and secure cloud synchronization so notes are easy to create, find, and access across devices.

The first version of Pluto should feel fast, calm, and dependable: open the app, record a thought, save it with useful context, and find it later without friction.

## 2. Problem Statement

Typing is slow and inconvenient when users are walking, commuting, studying, working, or trying to capture an idea before it disappears. Existing voice memo tools often store recordings as isolated files with weak organization, limited search, and inconsistent access across devices.

Pluto solves this by treating audio recordings as structured notes. Users should be able to record naturally, play back clearly, categorize intelligently, and trust that their notes are backed up securely.

## 3. Goals

- Enable users to create a voice note in under 5 seconds from opening the app.
- Provide reliable recording and playback on Android and iOS through Flutter.
- Organize notes using categories, tags, timestamps, and optional smart suggestions.
- Synchronize notes securely across signed-in devices.
- Support offline note creation and later cloud sync.
- Protect user audio and metadata with strong authentication, secure storage, and encrypted transmission.

## 4. Non-Goals

- Pluto is not a full podcast recording or audio editing studio.
- Pluto will not support multi-track audio editing in the MVP.
- Pluto will not include public social sharing or collaborative workspaces in the MVP.
- Pluto will not require users to transcribe every note before saving it.
- Pluto will not prioritize desktop-first workflows in the initial mobile release.

## 5. Target Users

### Students

Students use Pluto to capture lecture highlights, assignment ideas, study reminders, and personal summaries while moving between classes.

### Professionals

Professionals use Pluto to record meeting takeaways, client notes, task reminders, brainstorming sessions, and quick decisions during busy workdays.

### Creators and Writers

Creators use Pluto to capture ideas, hooks, scripts, melodies, and reflections when typing would interrupt their flow.

### Everyday Users

Everyday users use Pluto for grocery reminders, personal notes, errands, journaling, and thoughts they want to revisit later.

## 6. User Personas

### Aisha, University Student

Aisha records short notes after lectures and tags them by subject. She needs fast recording, clear playback, and reliable search before exams.

### Rohan, Product Manager

Rohan captures action items immediately after meetings. He needs synced notes, categories, and quick scanning by date or project.

### Maya, Content Creator

Maya records creative ideas throughout the day. She needs a lightweight capture flow and simple organization that does not slow her down.

## 7. Core User Stories

- As a user, I want to start recording quickly so I can capture an idea before I forget it.
- As a user, I want to pause and resume recording so interruptions do not force me to restart.
- As a user, I want to play, pause, seek, and replay audio notes so I can review them easily.
- As a user, I want to name, tag, and categorize notes so I can find them later.
- As a user, I want Pluto to suggest categories based on note context so organizing notes takes less effort.
- As a user, I want my notes to sync across devices so I can access them anywhere.
- As a user, I want offline recording so bad connectivity never blocks capture.
- As a user, I want secure storage so private recordings remain protected.
- As a user, I want to delete notes permanently so I control my data.

## 8. MVP Scope

### Must Have

- Email, Google, or Apple sign-in.
- Home screen with recent audio notes.
- One-tap audio recording.
- Pause, resume, stop, and save recording.
- Recording timer and microphone permission handling.
- Audio playback with play, pause, seek, duration, and progress state.
- Basic note metadata: title, date, duration, category, tags, and favorite status.
- Manual categories such as Personal, Work, Study, Ideas, Reminders, and Uncategorized.
- Search by title, category, tag, and date.
- Local offline storage for recorded notes.
- Cloud sync for audio files and note metadata.
- Delete and restore from trash for a limited retention period.
- Basic account settings and sign-out.

### Should Have

- Smart category suggestions based on title, tags, and optional transcript.
- Optional speech-to-text transcription after recording.
- Filter notes by category, favorite, date range, and sync status.
- Background upload status and retry handling.
- Lock screen or system notification controls during playback.
- Export or share audio note file.

### Could Have

- Reminder creation from voice notes.
- AI-generated summaries.
- Custom category colors.
- Folder-based organization.
- Widgets or quick actions for instant recording.
- Web or desktop companion experience.

## 9. Functional Requirements

### 9.1 Authentication

- Users can create an account and sign in.
- Users can sign out without losing already synced data.
- Anonymous/local-first usage may be considered, but MVP should prioritize authenticated sync.
- Authentication errors must be clear and recoverable.

### 9.2 Recording

- Users can start a new recording from the main screen.
- The app must request microphone permissions before first recording.
- Users can pause, resume, cancel, or save a recording.
- The app must show recording duration in real time.
- The app must prevent accidental loss when leaving the recording screen.
- If the app is interrupted by a call, OS event, or crash, it should attempt to preserve the partial recording.

### 9.3 Saving Notes

- After recording, users can save with an editable title.
- If the user does not enter a title, Pluto should generate a default title using date and time.
- Users can assign a category and tags before or after saving.
- Notes must store created date, updated date, duration, file size, sync state, and local file path.

### 9.4 Playback

- Users can play, pause, resume, and seek within a note.
- Playback state must remain visually clear.
- Users can see current position and total duration.
- Playback should continue when the screen changes unless the user stops it or OS restrictions apply.
- Only one note should play at a time.

### 9.5 Organization

- Users can view all notes ordered by newest first by default.
- Users can filter by category, tag, favorites, and date.
- Users can rename notes, update categories, add tags, favorite notes, and delete notes.
- Pluto should support an Uncategorized state for notes that have not been organized.

### 9.6 Intelligent Categorization

- Pluto should suggest a category when enough metadata exists.
- For MVP, suggestions may use local heuristics such as keywords in the title, tags, or transcript.
- If transcription is enabled, category suggestions can use transcript keywords.
- Users must be able to override suggested categories.
- Smart categorization must never block saving a note.

### 9.7 Cloud Sync

- Notes must sync across devices for signed-in users.
- Audio files and metadata must remain linked consistently.
- Notes created offline must be queued for upload when connectivity returns.
- Sync conflicts should prefer the most recently updated metadata while preserving audio files.
- Users should see sync states such as Synced, Uploading, Offline, and Failed.
- Failed sync attempts should retry automatically and offer manual retry.

### 9.8 Search

- Users can search notes by title, category, tags, and date.
- If transcription is included, transcript search should be supported.
- Search results should update quickly as the user types.
- Empty states should help users understand whether no notes exist or no results match.

### 9.9 Settings

- Users can manage account details.
- Users can choose whether transcription is enabled.
- Users can view storage usage.
- Users can export or delete account data where supported.
- Users can access privacy policy and terms.

## 10. Non-Functional Requirements

### Performance

- App launch to usable home screen should target under 2 seconds on typical modern devices.
- Recording should begin within 1 second after tapping record, excluding first-time permission prompts.
- Search should return local results in under 300 ms for up to 1,000 notes.
- Playback controls should respond immediately to user input.

### Reliability

- Recordings must not be lost during normal app navigation.
- Offline-first behavior must allow users to record without network access.
- Sync failures must not delete local notes.
- The app should recover gracefully from permission denial, storage limits, and network errors.

### Security and Privacy

- All network traffic must use HTTPS/TLS.
- Authentication tokens must be stored using secure platform storage.
- Cloud audio files should be protected by per-user access rules.
- Users must be able to delete notes.
- Sensitive logs must not include audio contents, transcripts, auth tokens, or personally identifiable information.
- If transcription or AI categorization uses cloud services, users must be clearly informed and allowed to disable it.

### Accessibility

- Core actions must support screen readers.
- Recording, playback, and save controls must have accessible labels.
- Touch targets should be at least 44 x 44 points.
- Color should not be the only indicator of state.
- Text should scale reasonably with system font settings.

### Platform Support

- MVP target platforms: Android and iOS.
- Flutter code should keep platform-specific audio, permission, and background behavior isolated behind services.
- Web, macOS, Windows, and Linux can remain future expansion targets.

## 11. Suggested Information Architecture

- Home
  - Recent notes
  - Search
  - Category filters
  - Record action
- Recording
  - Timer
  - Pause/resume
  - Cancel
  - Save
- Note Detail
  - Playback
  - Metadata
  - Category and tags
  - Transcript, if enabled
  - Share/export
- Categories
  - Category list
  - Notes by category
  - Manage categories
- Settings
  - Account
  - Sync status
  - Storage
  - Transcription preferences
  - Privacy and support

## 12. Key User Flows

### Flow 1: Create a Voice Note

1. User opens Pluto.
2. User taps Record.
3. App requests microphone permission if needed.
4. Recording starts and timer begins.
5. User pauses, resumes, or stops recording.
6. User saves the note with optional title, category, and tags.
7. Note appears on the Home screen and syncs in the background.

### Flow 2: Find and Replay a Note

1. User opens Home.
2. User searches or filters by category.
3. User selects a note.
4. User taps Play.
5. User pauses, seeks, or replays the recording.

### Flow 3: Offline Capture and Sync

1. User records a note without internet access.
2. Note saves locally with Offline sync state.
3. Network returns.
4. App uploads metadata and audio.
5. Sync state changes to Synced.

## 13. Data Model

### User

- `id`
- `displayName`
- `email`
- `createdAt`
- `updatedAt`

### AudioNote

- `id`
- `userId`
- `title`
- `categoryId`
- `tags`
- `durationMs`
- `fileSizeBytes`
- `localFilePath`
- `cloudFileUrl`
- `transcript`
- `isFavorite`
- `syncStatus`
- `createdAt`
- `updatedAt`
- `deletedAt`

### Category

- `id`
- `userId`
- `name`
- `color`
- `isSystemDefault`
- `createdAt`
- `updatedAt`

## 14. Analytics and Success Metrics

- Activation: percentage of new users who create at least one note in the first session.
- Capture speed: median time from app open to recording start.
- Retention: percentage of users returning weekly.
- Engagement: average number of notes created per active user per week.
- Reliability: percentage of recordings saved successfully.
- Sync health: percentage of notes successfully synced within 5 minutes of network availability.
- Organization usage: percentage of notes assigned to a category or tag.
- Search success: percentage of searches that lead to note playback or note edit.

## 15. Acceptance Criteria

- A user can install the app, sign in, record a note, save it, replay it, and see it in the note list.
- A user can deny microphone permission and receive a clear explanation with a way to retry.
- A user can create a note offline and access it before sync completes.
- A user can update title, category, tags, and favorite status.
- A user can search for a saved note by title.
- A user can delete a note and no longer see it in the main list.
- A signed-in user can access synced notes from another device.
- Audio files cannot be accessed by another user account.
- Failed uploads preserve local recordings and allow retry.

## 16. Technical Considerations

### Flutter Architecture

- Use a layered architecture with presentation, application/state, domain, and data layers.
- Keep audio recording and playback behind service interfaces.
- Keep sync logic separate from UI widgets.
- Use dependency injection to simplify testing.
- Use platform permission wrappers for microphone, storage, and background behavior.

### Candidate Packages

- Audio recording: `record` or equivalent maintained Flutter package.
- Audio playback: `just_audio` or equivalent.
- Permissions: `permission_handler`.
- Local database: `drift`, `isar`, `hive`, or `sqflite`.
- Secure storage: `flutter_secure_storage`.
- Cloud sync: Firebase Authentication, Cloud Firestore, and Cloud Storage, or an equivalent backend.
- State management: Riverpod, Bloc, or Provider based on team preference.

### Testing

- Unit tests for note metadata, category suggestion logic, and sync conflict handling.
- Widget tests for recording, note list, note detail, search, and empty states.
- Integration tests for create, save, play, delete, and offline sync flows.
- Manual QA for microphone permissions, interrupted recordings, background playback, and low-storage states.

## 17. Risks and Mitigations

- Audio recording behavior differs across platforms.
  - Mitigation: isolate platform logic, test on physical Android and iOS devices, and define platform-specific QA scenarios.
- Cloud sync can produce conflicts or duplicate notes.
  - Mitigation: use stable note IDs, updated timestamps, sync states, and conflict rules.
- Audio files may consume significant storage.
  - Mitigation: show storage usage, compress recordings where appropriate, and allow deletion/export.
- Users may worry about privacy.
  - Mitigation: provide clear controls for transcription, secure storage, and data deletion.
- AI categorization may be inaccurate.
  - Mitigation: make suggestions editable, non-blocking, and easy to override.

## 18. Release Plan

### Phase 1: Foundation

- App shell and navigation.
- Local note model and storage.
- Microphone permission handling.
- Recording and playback proof of concept.

### Phase 2: MVP

- Full create, save, list, detail, edit, delete flow.
- Categories, tags, favorites, and search.
- Authentication and cloud sync.
- Offline queue and sync retry.

### Phase 3: Intelligence

- Smart category suggestions.
- Optional transcription.
- Transcript search.
- AI-generated summaries, if privacy and cost requirements are acceptable.

### Phase 4: Polish and Scale

- Export and sharing.
- Reminder integration.
- Quick record shortcuts.
- Improved storage management.
- Additional platform support.

## 19. Open Questions

- Should Pluto require sign-in before recording, or allow local-only usage first?
- Which backend should be selected for cloud sync: Firebase, Supabase, custom API, or another provider?
- Should transcription be part of MVP or a post-MVP feature?
- Should recordings be compressed by default, and what audio quality target should be used?
- What is the expected retention behavior for deleted notes?
- Should Pluto support passcode or biometric lock for private notes?

## 20. MVP Definition of Done

The MVP is complete when a signed-in user on Android or iOS can reliably record an audio note, save it with metadata, organize it, replay it, search for it, delete it, and access it from another device after cloud sync, with offline capture preserved and privacy controls documented.
