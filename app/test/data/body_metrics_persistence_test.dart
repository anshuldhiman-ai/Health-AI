import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('profile details survive a fresh controller and startup load', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(bodyMetricsProvider.notifier)
        .update(
          name: 'Taylor',
          heightCm: 172.5,
          weightKg: 68.2,
          useFeet: true,
          useLbs: true,
          onboardingCompleted: true,
        );

    final restored = await loadSavedBodyMetrics();
    expect(restored.name, 'Taylor');
    expect(restored.heightCm, 172.5);
    expect(restored.weightKg, 68.2);
    expect(restored.useFeet, isTrue);
    expect(restored.useLbs, isTrue);
    expect(restored.onboardingCompleted, isTrue);
    expect(restored.bmi, closeTo(68.2 / (1.725 * 1.725), 0.001));
  });

  test(
    'rapid profile edits persist in order, keeping the newest values',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(bodyMetricsProvider.notifier);

      final first = controller.update(name: 'First', heightCm: 160);
      final second = controller.update(name: 'Final', weightKg: 62);
      await Future.wait([first, second]);

      final restored = await loadSavedBodyMetrics();
      expect(restored.name, 'Final');
      expect(restored.heightCm, 160);
      expect(restored.weightKg, 62);
    },
  );
}
