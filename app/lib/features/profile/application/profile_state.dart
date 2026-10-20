import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile-screen state. The display name is SAMPLE DATA (UI v0); the
/// real profile lives in the encrypted user.db (Section 6.2) through
/// M1. There is NO cloud account and never will be (R1/R3).
///
/// Goal text is derived from the selected plan in `goals_controller`
/// and localised in the profile screen.
class ProfileState {
  const ProfileState({required this.displayName});

  /// Display name only — no e-mail/account fields exist in this app.
  final String displayName;
}

final sampleProfileProvider = Provider<ProfileState>((ref) {
  return const ProfileState(displayName: 'Anshul');
});
