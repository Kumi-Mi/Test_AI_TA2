# LearnFlow Product Redesign — Approved Design

Date: 2026-07-18  
Status: Approved in conversation; awaiting final document review  
Primary platform: Android (Flutter)  
Administration: Separate web application  

## 1. Product definition

LearnFlow is an English-learning product for Vietnamese learners aged 15–30 at CEFR A1–B1. It combines a structured A1→B1 curriculum with a personalized daily session of roughly 10–15 minutes. The daily plan blends the next curriculum lesson with vocabulary due for review according to Half-Life Regression (HLR).

The product must be usable by real users. Production screens must never invent users, scores, ranks, activity, percentages, model confidence, streaks, or learning history. When evidence does not exist, the interface displays an honest empty, onboarding, or “still learning your preferences” state.

### Existing assets retained

- The Flutter Android project and current four-skill exercise prototype.
- The 1,718-item English–Vietnamese catalog derived from the Duolingo HLR corpus.
- The trained HLR artifact and the on-device forgetting prediction path.
- Custom Input, device TTS, speech recognition, word-error scoring, Word Catch, and Text Cipher as starting points to deepen rather than discard.

### Existing MVP behavior to remove from production

- Default session values such as 68% win rate, two consecutive wins, and 18 minutes before a learner has answered anything.
- `ML Lab`, demo seeds, test fixtures, and developer controls in the production navigation.
- Silent fallback to fictional seed progress when production data fails.
- Claims about engagement state or skill progress before enough real evidence exists.

## 2. Confirmed product decisions

- Audience: Vietnamese learners aged 15–30, CEFR A1–B1.
- Learning model: structured curriculum plus adaptive daily sessions.
- Content: reviewed core curriculum; AI and Custom Input are supplemental and visibly identified.
- Onboarding: a real 3–4 minute trial lesson before registration.
- Account gate: registration is requested after the trial to save results.
- Authentication: email/password, email verification, password reset, and Google Sign-In.
- Audio: core lesson and dialogue audio is AI-generated in advance and stored; Custom Input uses generated TTS on demand. Synthetic audio is not represented as human recording.
- Social: weekly, level-matched leaderboard; the leaderboard is published only when at least five real opted-in learners are active in a cohort.
- Gamification: real XP, levels, streaks, missions, badges, and personal challenges. No hearts that block learning, virtual currency, or random reward boxes.
- Custom Input privacy: content is not stored by default. A user must explicitly choose “Save to private library” before it is synchronized to MySQL.
- Monetization: no payments in the first release; authorization data is designed so subscription entitlements can be added later.
- Release order: Android first. The Admin web application is required in the initial system; a learner-facing web app and iOS are deferred.
- Visual direction: Quiet Editorial.

## 3. Information architecture

The Android bottom navigation contains five destinations, each with one responsibility:

1. **Today** — the next adaptive 10–15 minute session.
2. **Path** — the A1→B1 course, units, checkpoints, and unlock state.
3. **Practice** — focused practice modes, mini-games, and Custom Input.
4. **Progress** — evidence-backed personal learning history.
5. **Profile** — account, goals, schedule, privacy, downloads, and settings.

`ML Lab` is developer-only. Admin tools are not embedded in the learner app.

## 4. User journeys

### 4.1 First use

1. One concise value-proposition screen; no multi-page marketing carousel.
2. A real A1 trial lesson lasting approximately 3–4 minutes.
3. Feedback restricted to evidence from the trial; no inferred level from too little data.
4. Registration with verified email/password or Google.
5. Goal, learning schedule, timezone, and notification consent.
6. A placement test or an explicit “Start from A1” choice.
7. The first personalized Today plan.

### 4.2 Returning learner

- If vocabulary is due, Today starts with review and then continues into curriculum.
- If engagement evidence is insufficient, the session uses a balanced policy and says the app is still learning the learner’s preferences.
- Offline learners use downloaded content. Answer events enter a local outbox and synchronize later.
- A leaderboard cohort below five active opted-in learners shows a truthful waiting state and personal progress, not generated competitors.

### 4.3 Account recovery

- Request reset without revealing whether an email exists.
- Single-use, expiring reset token.
- Revoke existing refresh sessions after password reset, with an explicit choice for trusted devices if later supported.

## 5. Functional scope

### 5.1 Required for the first complete release

#### Identity and onboarding

- Trial lesson.
- Registration, email verification, login, logout, password reset, Google Sign-In.
- Placement or A1 start.
- Goal, schedule, timezone, notification and privacy settings.

#### Curriculum and lesson engine

- A1–B1 courses, units, lessons, learning outcomes, checkpoints, prerequisites, and published versions.
- Exercise types: contextual meaning, listening choice, dictation, sentence ordering, cloze, Word Catch, Text Cipher, shadowing/recording, and branching dialogue.
- Reviewed explanation and feedback for every graded core exercise.
- Pre-generated AI audio with voice, locale, speed, checksum, and generation provenance.
- Downloadable content manifests for offline lessons.

#### Adaptive learning

- HLR vocabulary ordering using corpus priors kept separate from personal observations.
- Personal response time, attempts, correctness, last-seen time, and error history.
- Daily plans combining due review and curriculum work.
- Engagement adaptation only after its evidence threshold is met. Before that threshold, a documented balanced policy is used without a fabricated prediction label.

#### Practice and personal library

- Word Catch and Text Cipher rebuilt around shared session orchestration.
- Listening discrimination, dictation, sentence builder, shadowing, and branching dialogue.
- Custom Input for listening, speaking, reading, and writing.
- Private saved documents, saved vocabulary, due-review queue, mistake notebook, and targeted retry sessions.

#### Progress and motivation

- Actual time learned, completed lessons, answer accuracy, encountered words, due words, and evidence count.
- Listening, speaking, reading, and writing progress shown only after the configured minimum evidence.
- Append-only XP ledger, levels, qualifying streak days, missions, and badges.
- Weekly, level-matched, opt-in leaderboard with a five-active-member publication threshold.
- HLR-based review notifications with user-controlled schedule and consent.

### 5.2 Deferred after the first complete release

- Open-ended AI role-play beyond reviewed branching dialogue.
- Phoneme/acoustic pronunciation scoring beyond transcript and word-level feedback.
- Daily Story, article/subtitle import, groups, friends, teacher/classroom mode.
- Paid subscriptions and payment processing.
- iOS and learner-facing web applications.

These features must not leave dead navigation or “coming soon” cards in production unless a release has been committed and the state is useful to the learner.

## 6. Quiet Editorial design system

### 6.1 Visual language

- Warm paper surfaces, deep forest ink, restrained ochre accent, oat neutrals, and a limited mist accent.
- A Vietnamese-capable editorial serif for display text and a highly readable sans-serif for controls, data, and long text.
- No decorative gradients, rainbow cards, or repeated mascot components.
- Hand-drawn illustration is limited to onboarding and meaningful empty states.
- Layout hierarchy comes from typography, spacing, rhythm, and content—not an equal grid of colorful cards.

### 6.2 Interaction rules

- One primary action per screen.
- Lesson mode removes bottom navigation and unrelated actions.
- Motion lasts approximately 160–260 ms and communicates state; Reduce Motion is respected.
- Minimum touch target is 48 dp.
- Contrast targets WCAG AA, text scaling is supported, audio has transcripts/captions, and semantics are present for assistive technology.
- Loading, empty, offline, partial-data, permission-denied, and retry states are designed as first-class component states.

### 6.3 Figma deliverable

The implementation phase creates a Figma source of truth with pages for Foundations, Components, Patterns, Mobile Flows, Admin, and Prototypes. Color, typography, spacing, radius, elevation, and motion are represented as variables/tokens. Components include every interactive and data state and are mapped to Flutter design tokens.

## 7. System architecture

### 7.1 Selected approach

A modular monolith is used rather than microservices or an experience-first local prototype.

- **Android:** Flutter.
- **Backend:** NestJS modules behind a versioned HTTPS JSON API and OpenAPI contract.
- **Database:** MySQL 8 with Prisma schema and migrations.
- **Admin:** React/Vite consuming the same API with separate admin authentication and RBAC.
- **Local mobile data:** SQLite via Drift for cached manifests/content, progress snapshots, and an event outbox; secure storage for refresh credentials.
- **Media:** S3-compatible object storage. Local development uses MinIO; MySQL stores URLs, checksums, access metadata, and generation provenance rather than audio blobs.
- **Development email:** Mailpit. Deployed email uses a configured SMTP/provider adapter.
- **Core TTS:** a provider adapter whose initial production target is Google Cloud Text-to-Speech; generated files are reviewed and stored before publication. Missing credentials disable generation visibly rather than creating fake audio.
- **Custom TTS:** device TTS initially, with a server provider available behind the same disclosure and consent policy.

Flutter follows separate UI/data layers and repository boundaries, consistent with the [official Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations). NestJS provides module boundaries and authentication guards ([official authentication guidance](https://docs.nestjs.com/security/authentication)). Prisma provides typed MySQL access and migrations ([official MySQL connector documentation](https://docs.prisma.io/docs/orm/v6/overview/databases/mysql)).

### 7.2 Backend modules

- Auth and Identity.
- Users and Settings.
- Curriculum and Publishing.
- Exercises and Vocabulary.
- Media and TTS Jobs.
- Learning Sessions and Event Sync.
- Progress and Adaptive Planning.
- Custom Library.
- XP, Levels, Streaks, Missions, and Badges.
- Leaderboard Seasons and Cohorts.
- Notifications.
- Admin RBAC and Audit.

Modules communicate through explicit services/events rather than reaching into each other’s database internals.

## 8. MySQL domain model

### Identity

- `users`
- `auth_identities`
- `refresh_sessions`
- `verification_tokens`
- `user_settings`

Email is normalized and unique. Password hashes are nullable for Google-only accounts. Multiple identities may belong to one user. Refresh tokens are stored only as hashes and can be revoked per device.

### Curriculum and media

- `courses`, `units`, `lessons`, `lesson_versions`
- `exercises`, `exercise_choices`
- `vocabulary_items`
- `media_assets`, `tts_jobs`
- `content_publications`

A published lesson version is immutable. Editing creates a new version so historical answers keep the exact content identity the learner saw. Content passes draft → review → published or archived. A publication creates a versioned manifest that mobile clients can diff and cache.

### Learning and progress

- `learning_sessions`
- `answer_events`
- `lesson_progress`
- `vocabulary_progress`
- `skill_progress`

`answer_events` is append-only and contains a client-generated `event_uuid`, exercise/word references, correctness, attempts, response time, client time, server receipt time, and model/content versions. A unique user/event constraint makes sync idempotent. Progress tables are rebuildable snapshots, never substitutes for the raw event history.

Corpus priors remain in `vocabulary_items`; personal counters remain in `vocabulary_progress`. An HLR snapshot records `model_version` so predictions can be recomputed after a model update.

### Motivation and leaderboard

- `xp_ledger`
- `streak_days`
- `missions`, `user_missions`
- `badges`, `user_badges`
- `leaderboard_seasons`, `leaderboard_members`

XP is an append-only ledger entry linked to a unique source event, not a freely editable total. Streak days require qualifying activity in the learner’s timezone. Badge and mission awards retain evidence references. Leaderboard results are derived from the XP ledger and are not returned until at least five active opted-in members exist in a level-matched weekly cohort.

### Private content and administration

- `custom_documents`, `custom_exercise_runs`
- `admin_roles`, `audit_logs`

No `custom_documents` row exists until a user explicitly saves. Saved content is private to its owner, encrypted using application-managed keys, and cascade-deleted with the document/account policy. Admin changes store actor, action, target, timestamp, and before/after metadata.

## 9. Core data flows

### Content publication

1. Editor creates a draft lesson.
2. Reviewer validates language, answers, explanations, accessibility, and audio.
3. TTS jobs generate audio; checksums and provenance are recorded.
4. Publisher releases an immutable lesson version and manifest.
5. Mobile synchronizes only changed published content and media.

### Learning event synchronization

1. Mobile records the answer event in the local outbox before showing completion.
2. The learner receives immediate local feedback.
3. The API accepts events in batches and enforces user/event idempotency.
4. One transaction stores the event and updates snapshots/XP ledger.
5. The API acknowledges accepted event IDs; mobile removes only acknowledged outbox entries.
6. The server returns authoritative snapshots; the mobile repository merges them with unsent local events.

### Google authentication

Flutter obtains a Google ID token and sends it over HTTPS. The backend verifies issuer, audience, signature, expiry, and subject before creating/linking an identity and issuing LearnFlow access/refresh tokens. A plain Google user ID is never trusted, following [Google’s backend authentication guidance](https://developers.google.com/identity/sign-in/android/backend-auth?hl=en).

## 10. Truthful-data policy

- Every production metric names its source event/snapshot and evidence count.
- An insufficient-evidence threshold produces an onboarding/empty state, not a default percentage.
- Demo fixtures exist only in test and development flavors.
- Production startup fails visibly or uses a known published offline content version; it never falls back to fictional learner progress.
- `ML Lab` is restricted to development builds.
- Admin analytics is computed from real events and displays the query interval and population size.
- Leaderboards use real opted-in users only.

## 11. Error and offline behavior

- Offline lesson activity remains usable when content is downloaded.
- Outbox retries use backoff and idempotency keys.
- Access-token expiry triggers one refresh attempt; failure returns the user to login without discarding local events.
- Missing/unavailable audio shows a specific error and alternative transcript where pedagogically valid; it is not silently replaced.
- Microphone denial provides settings guidance and an alternative non-speaking exercise.
- A content manifest or lesson validation failure retains the last valid published version and alerts Admin.
- API/MySQL downtime cannot erase a completed local attempt.
- User-visible errors state what happened, what was preserved, and what action is possible.

## 12. Security and privacy

- HTTPS only outside local development.
- Passwords use Argon2id; plaintext passwords are never logged or stored.
- Short-lived access tokens and rotating, hashed refresh tokens.
- Email verification/reset tokens are hashed, expiring, and single-use.
- Rate limits on login, registration, reset, verification, TTS, and high-cost endpoints.
- Responses do not reveal whether an email is registered.
- Prisma parameterization and schema constraints protect database access; the app never connects directly to MySQL.
- RBAC separates Editor, Reviewer, Publisher, and Support responsibilities.
- Secrets come from environment/secret storage, not source control.
- Logs exclude passwords, tokens, raw Custom Input, and unnecessary PII.
- Account deletion revokes sessions, deletes private content, and anonymizes retained learning events under a published retention policy.

## 13. Testing and release gates

### Flutter

- Unit tests for HLR, planning, XP, streak, mission, validation, repositories, and sync merge.
- Widget and golden tests for the design system and loading/empty/offline/error/partial-data states.
- Integration tests for offline learning followed by reconnection and idempotent synchronization.
- Accessibility tests for contrast, semantic labels, dynamic text, touch targets, captions, and reduced motion.

### Backend and Admin

- Module unit tests.
- Integration tests against MySQL 8 and object storage in containers.
- OpenAPI contract tests shared by Flutter and Admin.
- End-to-end tests for trial → account, verification, login, Google identity, reset, lesson completion, event replay, publication, TTS workflow, and account deletion.
- RBAC and audit-log tests.

### Content and production gates

- Schema, translation/gloss, answer, duplicate, audio checksum, transcript, and publication validation.
- Production builds fail when demo-only routes, fixtures, or fake endpoints are reachable.
- `flutter analyze`, Flutter tests, API tests, migrations, Admin tests, and Android release build must pass before release.

## 14. Delivery sequence

Each phase ends with a runnable, testable vertical slice.

1. **Foundation:** Flutter feature/repository architecture, build flavors, truthful states, and removal of production demo behavior.
2. **Backend:** NestJS, Prisma, MySQL, Docker Compose, Auth, OpenAPI, MinIO, and Mailpit.
3. **Admin:** RBAC, curriculum CMS, versioning, preview, publish, audit, and TTS workflow.
4. **Design:** Figma Quiet Editorial foundations, components, patterns, mobile flows, Admin flows, and Flutter token mapping.
5. **Learning:** curriculum sync, lesson engine, offline cache, event outbox, HLR and daily planning.
6. **Depth:** Custom Library, mistake notebook, saved vocabulary, AI audio, four-skill progress, and notifications.
7. **Motivation:** XP ledger, levels, streaks, missions, badges, and thresholded leaderboard.
8. **Hardening:** migration, performance, accessibility, security review, backup/restore rehearsal, and Android release build.

## 15. Acceptance criteria

- A new learner can complete a real trial without an account, register, verify, choose a starting level, and resume their saved result.
- A returning learner receives a plan based only on published curriculum and their own/corpus-separated evidence.
- A completed offline session synchronizes once without duplicate progress or XP.
- No production page shows invented learner, leaderboard, engagement, or analytics data.
- Admin can create, review, preview, publish, roll back, and audit versioned content and AI audio.
- Custom Input is absent from MySQL unless explicitly saved and can be deleted.
- Leaderboard data is unavailable below five active opted-in cohort members.
- The product is navigable with assistive technology and remains usable under supported text scaling and offline conditions.
- Android, backend, Admin, migrations, content validation, and end-to-end release gates pass.

## 16. Scope control

This design is intentionally delivered in phases. “Complete” means the approved first-release capabilities are integrated, testable, truthful, and maintainable—not that every possible language-learning feature is shipped in one uncontrolled change. Deferred capabilities must receive their own approved design before implementation.
