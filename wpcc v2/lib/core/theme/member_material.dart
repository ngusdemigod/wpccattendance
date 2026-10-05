import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MemberMaterialWeight { control, navigation, sheet }

class TransparencyPreference extends ValueNotifier<bool> {
  TransparencyPreference._() : super(false);
  static final instance = TransparencyPreference._();
  Future<void> load() async {
    value = (await SharedPreferences.getInstance())
            .getBool('wpcc.reduceTransparency') ??
        false;
  }

  Future<void> select(bool reduced) async {
    value = reduced;
    await (await SharedPreferences.getInstance())
        .setBool('wpcc.reduceTransparency', reduced);
  }
}

class MemberMaterialScope extends InheritedNotifier<TransparencyPreference> {
  MemberMaterialScope({super.key, required super.child})
      : super(notifier: TransparencyPreference.instance);
}

abstract final class MemberMaterials {
  static bool solid(BuildContext context) =>
      (context
              .dependOnInheritedWidgetOfExactType<MemberMaterialScope>()
              ?.notifier
              ?.value ??
          TransparencyPreference.instance.value) ||
      MediaQuery.highContrastOf(context);

  static double blur(MemberMaterialWeight weight) => switch (weight) {
        MemberMaterialWeight.control => 24,
        MemberMaterialWeight.navigation => 24,
        MemberMaterialWeight.sheet => 28,
      };

  static Color fill(BuildContext context, MemberMaterialWeight weight) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF29292D) : const Color(0xFFF7F7FA);
    if (solid(context)) return base;
    final opacity = switch (weight) {
      MemberMaterialWeight.control => dark ? .62 : .70,
      MemberMaterialWeight.navigation => dark ? .46 : .58,
      MemberMaterialWeight.sheet => dark ? .88 : .92,
    };
    return base.withValues(alpha: opacity);
  }

  static Color edge(BuildContext context) => MediaQuery.highContrastOf(context)
      ? Theme.of(context).colorScheme.onSurfaceVariant
      : (Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: .18)
          : Colors.black.withValues(alpha: .09));
}
