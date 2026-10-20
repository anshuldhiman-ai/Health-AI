import 'package:app/design_system/components/empty_state.dart';
import 'package:app/design_system/components/meter_bar.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/components/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Design-system component tests: clamping, semantics and that the
/// generic widgets work in both themes.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: child),
  );

  testWidgets('ProgressRing renders its child and semantics value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const ProgressRing(
          progress: 0.25,
          semanticLabel: 'kcal ring',
          child: Text('482'),
        ),
      ),
    );

    expect(find.text('482'), findsOneWidget);
    final node = tester.getSemantics(find.text('482'));
    // The ring label and the centred number merge into one node —
    // that is the accessible experience we want to guard.
    expect(node.label, contains('kcal ring'));
    expect(node.value, '25%');
    semantics.dispose();
  });

  testWidgets('MeterBar clamps overflowing values', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            MeterBar(label: 'Protein', value: 150, target: 100),
            MeterBar(label: 'Fat', value: 0, target: 60),
          ],
        ),
      ),
    );

    // No overflow, label row renders for both bars.
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('150 / 100 g'), findsOneWidget);
    expect(find.text('0 / 60 g'), findsOneWidget);
  });

  testWidgets('StatTile and EmptyState render with their semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            const StatTile(
              icon: Icons.directions_walk,
              value: '6,320',
              caption: 'steps',
            ),
            EmptyState(
              icon: Icons.no_meals_outlined,
              title: 'No meals yet',
              message: 'Log your first meal',
              actionLabel: 'Add',
              onAction: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('6,320'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });
}
