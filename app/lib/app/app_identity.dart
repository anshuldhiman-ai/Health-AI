/// Single source for the display name and static identifiers (Section 0).
///
/// The product name is undecided. Until it exists:
/// - paths use the working codename `app`
/// - user-visible display strings come from l10n (R13), never hard-coded
/// - this file is the ONE place a rebrand changes code-side identifiers.
class AppIdentity {
  AppIdentity._();

  /// Working codename used in paths, package name and logs.
  static const appCodename = 'app';

  /// Display name. TODO(placeholder): replace with the real name once decided
  /// (Section 0). Keep in sync with l10n and Android `strings.xml`.
  static const displayName = '{{APP_NAME}}';

  /// Placeholder for the Android applicationId.
  /// Format: `com.<yourname>.<app>`. CANNOT be changed after the first
  /// Play release — decide before the first upload (Section 0).
  static const applicationId = '{{APPLICATION_ID}}';
}
