// Architecture test (Section 5.1, Rule R9).
//
// Scans import lines in lib/ and FAILS on violations. Never weaken
// this test.
//
// The dependency rule:
//   presentation (screens, widgets)
//         │  watches / calls
//   application  (Riverpod controllers; UI state as freezed unions)
//         │  calls
//   domain       (entities, value objects, services, use cases, repository
//                 INTERFACES)   ← pure Dart
//         ▲  implemented by
//   data         (drift DAOs, nutrition DB, sensors, storage, repository impls)
//         ▲  uses
//   ml           (FoodRecognizer impl, behind a domain interface)
//
// Rules enforced here:
//   1. domain/ is pure Dart: only dart:, package:meta, package:collection,
//      and package:app/domain.
//   2. design_system imports only dart:, package:flutter, and itself.
//   3. core imports nothing from domain, data, ml, features or design_system.
//   4. data never imports design_system or features.
//   5. features never import each other's internals.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Returns the area a lib/ file belongs to.
/// `domain/services/x.dart` -> `domain`; `features/diary/x.dart` -> `features/diary`.
String? _areaOf(String relPath) {
  final parts = relPath.split('/');
  if (parts.isEmpty) return null;
  final top = parts[0];
  if (top == 'features' && parts.length >= 2) return 'features/${parts[1]}';
  return top;
}

/// Normalizes an import line to a comparable path prefix.
/// `package:app/domain/foo.dart` -> `domain/foo.dart`
/// `dart:io` -> `dart:io`
/// `package:flutter/material.dart` -> `package:flutter/material.dart`
/// Relative imports are returned as-is (and flagged where relevant).
String? _normalize(String importLine) {
  final trimmed = importLine.trim();
  const prefix = 'import ';
  if (!trimmed.startsWith(prefix)) return null;
  var uri = trimmed.substring(prefix.length).trim();
  uri = uri.replaceAll("'", '').replaceAll(';', '').trim();
  if (uri.isEmpty) return null;
  if (uri.startsWith('package:app/')) {
    return uri.substring('package:app/'.length);
  }
  return uri;
}

void main() {
  group('layer discipline (R9)', () {
    test('every import respects the dependency rule', () {
      final violations = <String>[];

      for (final file in _dartFiles(Directory('lib'))) {
        final rel = file.path.replaceAll('\\', '/').split('/lib/').last;
        final area = _areaOf(rel);
        if (area == null) continue;

        for (final line in file.readAsLinesSync()) {
          final imported = _normalize(line);
          if (imported == null) continue;

          // Rule 1: domain is pure Dart.
          if (area == 'domain') {
            final ok =
                imported.startsWith('dart:') ||
                imported.startsWith('package:meta') ||
                imported.startsWith('package:collection') ||
                imported.startsWith('domain/');
            if (!ok) {
              violations.add(
                '$rel imports $imported (domain must be pure Dart)',
              );
            }
            continue;
          }

          // Rule 2: design_system imports only flutter + itself.
          if (area == 'design_system') {
            final ok =
                imported.startsWith('dart:') ||
                imported.startsWith('package:flutter') ||
                imported.startsWith('design_system/');
            if (!ok) {
              violations.add(
                '$rel imports $imported'
                ' (design_system imports only flutter + itself)',
              );
            }
            continue;
          }

          // Rule 3: core is cross-cutting only.
          if (area == 'core') {
            final bad =
                imported.startsWith('domain/') ||
                imported.startsWith('data/') ||
                imported.startsWith('ml/') ||
                imported.startsWith('features/') ||
                imported.startsWith('design_system/') ||
                imported.startsWith('app/');
            if (bad) {
              violations.add(
                '$rel imports $imported (core may not depend on other areas)',
              );
            }
            continue;
          }

          // Rule 4: data may not import UI.
          if (area == 'data') {
            final bad =
                imported.startsWith('design_system/') ||
                imported.startsWith('features/') ||
                imported.startsWith('app/');
            if (bad) {
              violations.add('$rel imports $imported (data may not import UI)');
            }
            continue;
          }

          // Rule 5: features are isolated from each other.
          if (area.startsWith('features/')) {
            final featureName = area.split('/').elementAt(1);
            if (imported.startsWith('features/') &&
                !imported.startsWith('features/$featureName')) {
              violations.add(
                '$rel imports $imported'
                ' (features are isolated from each other)',
              );
            }
            continue;
          }
        }
      }

      for (final v in violations) {
        // ignore: avoid_print
        print('VIOLATION: $v');
      }
      expect(violations, isEmpty, reason: 'layer violations found');
    });
  });

  group('naming conventions (Section 4)', () {
    test('source files are snake_case', () {
      final bad = <String>[];
      for (final file in _dartFiles(Directory('lib'))) {
        final name = file.uri.pathSegments.last;
        if (!_isSnakeCase(name.replaceAll('.dart', ''))) {
          bad.add(name);
        }
      }
      expect(bad, isEmpty, reason: 'files must be snake_case.dart');
    });
  });
}

bool _isSnakeCase(String name) {
  if (name.isEmpty) return false;
  final stripped = name.startsWith('_') ? name.substring(1) : name;
  return RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$').hasMatch(stripped);
}

List<File> _dartFiles(Directory dir) {
  final out = <File>[];
  if (!dir.existsSync()) return out;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      out.add(entity);
    }
  }
  return out;
}
