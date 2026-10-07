import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `tool/trim_web_build.cjs` removes the Thin, Light and Duotone Phosphor fonts
/// from the web build so the app does not download about 1.5 MB of unused
/// icon fonts at startup. This keeps the source in step with that trim.
void main() {
  test('app code only uses the Regular, Fill and Bold Phosphor weights', () {
    final offenders = <String>[];
    final pattern = RegExp(
        r'PhosphorIcons(Thin|Light|Duotone)\b|PhosphorIconsStyle\.(thin|light|duotone)\b');
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Use Regular/Fill/Bold, or update tool/trim_web_build.cjs and '
            'docs/pwa-performance.md if another weight is genuinely needed.');
  });
}
