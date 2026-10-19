import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile-screen state. SAMPLE DATA (UI v0); the real profile lives
/// in the encrypted user.db (Section 6.2) through M1. There is NO
/// cloud account and never will be (R1/R3).
///
/// Note: [goalSubtitle] is USER DATA (like a logged dish name), not a
/// UI string, so it is sample content here and not an ARB key.
class ProfileState {
  const ProfileState({
    required this.displayName,
    required this.goalSubtitle,
  });

  /// Display name only — no e-mail/account fields exist in this app.
  final String displayName;

  final String goalSubtitle;
}

final sampleProfileProvider = Provider<ProfileState>((ref) {
  return const ProfileState(
    displayName: 'Anshul',
    goalSubtitle: 'Lose 5 kg in 3 months',
  );
});
