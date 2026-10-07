# Learning Dashboard (Flutter · Android)

Login → course dashboard → course details with lesson completion, working offline after the first load.

**Run:** `flutter run` · **Test:** `flutter test` · **APK:** `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
**Demo login:** `demo@learner.com` / `password123` (any other combination shows the error state).
**Other states:** `--dart-define=MOCK_SCENARIO=empty` or `=error` shows the empty / API-failure dashboard.

The API is mocked by a Dio interceptor that serves `assets/mock/*.json` with latency. It goes through the real network stack and **fails with a connection error when the device is offline**, so airplane mode exercises the production offline path.

## 1. Architecture
Feature-first Clean Architecture with BLoC: `presentation → application (bloc) → domain (usecase → repository interface) ← data (repo impl → api / local db)`.
- `domain/` is pure Dart: no Flutter, Dio or sqflite. Blocs depend on use cases, which depend on a repository *interface*, so each layer is testable with fakes.
- `data/` is the only place that converts transport/database exceptions into typed `Failure`s (`Either<Failure, T>`). Blocs never see Dio or JSON.
- GetIt wires dependencies. Blocs are factories scoped to their route; everything else is a lazy singleton.
I picked this because it is proportionate: one interface per feature, no generic base classes, and each concern lives in one place (Dio setup, DB schema, error mapping).

## 2. Offline support
**SQLite (sqflite) is the single source of truth.** Screens observe `watch*` streams from the database; `refresh*` calls fetch from the network and write into the DB, which re-emits to the UI. So cached data shows instantly, and a failed refresh shows an "offline" banner over the cached list instead of an error screen (the error screen appears only when nothing is cached).
- **Lesson completion is local-first:** written in a transaction that also recomputes course progress, flagged `pending_sync`, then sent to the API. Queued completions are pushed before the next refresh.
- **Merge rule:** completion is one-way, so a server copy that hasn't caught up can't undo a local completion. Once a course's lessons are stored, its progress is derived from them (`completed * 100 ~/ total`, so 100% only when everything is done).
- Covered by `test/unit/course_repo_impl_test.dart`, which runs against a real in-memory SQLite.

## 3. Security
Tokens go in `flutter_secure_storage` (Android Keystore–backed encryption; Keychain on iOS), never SharedPreferences. `allowBackup=false` keeps them out of cloud backups. The token is attached by an interceptor, logs never include headers or bodies, and a genuine 401 clears the session, while network errors never log the user out. In production I'd add short-lived access tokens with rotating refresh tokens, certificate pinning, and R8/obfuscation.

## 4. Scale (1M users, hundreds of courses)
1. **Pagination and delta sync**: cursor-paginated course lists, `updated_since` lesson sync, and ETag/`If-None-Match` to avoid re-downloading unchanged data.
2. **Robust sync queue**: WorkManager background sync with retry/backoff, idempotency keys for completion events, and server-side conflict resolution.
3. **Backend/CDN offload**: CDN-cached catalogue content, per-user progress from a separate lightweight endpoint, and rate limiting.
4. **Observability**: Crashlytics/Sentry behind the existing `ErrorReporter` seam, performance traces on API and DB calls, and staged rollouts with remote config and feature flags.
5. **Engineering scale**: build flavors (dev/qa/prod), CI running analyze, tests and per-ABI split APKs/AAB, schema migrations, and localisation.

## 5. Second platform (iOS / macOS)
Keep the same layers and contracts in Swift. SwiftUI views observe an `@Observable` ViewModel per screen (the bloc equivalent, with state as an enum or struct). Use cases and repository protocols map one-to-one, with `async/await` and `AsyncStream` replacing `Future`/`Stream`. Networking uses `URLSession` behind an `APIClient` protocol, with `Codable` models. Local storage uses SwiftData (or GRDB/SQLite) with the same merge rules, plus `NWPathMonitor` for connectivity. The token goes in the Keychain. Dependencies are injected through initializers or a small container, and tests use XCTest with protocol fakes. A shared macOS target can reuse everything below the views.
