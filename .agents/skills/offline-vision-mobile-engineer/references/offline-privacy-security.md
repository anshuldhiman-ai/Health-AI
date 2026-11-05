# Offline-first privacy and mobile security

## Define the claim precisely

Distinguish among:

- Offline-first UX: core flows work without connectivity.
- No app network permission: release manifest has no INTERNET permission.
- No network-capable dependencies: direct and transitive dependencies have been reviewed.
- No outbound traffic in operation: runtime behavior has been observed/tested.

These are different claims. Do not say "100% offline" based on one static check.

## Android permission controls

1. List each permission and its user-facing purpose.
2. Remove unneeded permissions, including those introduced by transitive plugins.
3. Use manifest-merger rules where appropriate.
4. Build the actual release APK/AAB.
5. Inspect the final merged manifest with a tool appropriate to that artifact.
6. Fail CI if forbidden permissions appear.
7. Re-run after every dependency change.

A source manifest is not the final merged manifest. Test the release artifact, not a debug build.

## Dependency review

Review direct and transitive packages for:

- HTTP clients, sockets, WebViews, remote SDKs
- Analytics and telemetry
- Crash reporting
- Advertising and attribution
- Dynamic model/config downloads
- Background services and permission additions
- License and maintenance status
- Binary size and native code

Static package-name greps are only an initial filter.

## Storage and encryption

For every personal-data store, document:

- What is stored
- Whether it is plaintext or encrypted
- Encryption algorithm and key management, if applicable
- Backup/extraction behavior
- Retention and deletion
- Corruption recovery
- Whether data is duplicated elsewhere

App sandboxing protects against ordinary cross-app access but is not equivalent to application-level encryption against rooted-device or forensic access. A secure-storage mirror does not encrypt a separate plaintext JSON or preferences copy.

Avoid hard-coded app-private paths; use platform APIs for app directories. Test migrations and recovery.

## Images and logs

- Keep captured images in memory or app-private temporary storage only when possible.
- Delete temporary files after success, cancellation, and failure.
- Do not log image bytes, health records, or personal identifiers.
- Make image retention an explicit user choice.
- Test lifecycle interruption and cleanup.

## Secret handling

- Keep credentials out of source, logs, build artifacts, and skill packages.
- Use environment/secret stores for build-time credentials.
- Rotate any credential that was accidentally committed.
- Use a dedicated secret scanner; a regex pass is not a complete guarantee.
