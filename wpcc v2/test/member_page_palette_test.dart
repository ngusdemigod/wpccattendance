import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';

void main() {
  const pages = [
    '/home',
    '/events',
    '/media',
    '/give',
    '/profile',
    '/departments',
    '/prayer-alerts',
    '/devotional',
    '/souls',
    '/search'
  ];
  for (final dark in [false, true]) {
    test('unspecified pages share purple fallback in dark=$dark', () {
      final expected = dark ? const Color(0xFF39264D) : const Color(0xFFEDE3F6);
      for (final path in ['/resources/department-tools', '/resources/anonymous-reports',
        '/unspecified/detail']) {
        expect(MemberPagePalette.colors(path, dark).first, expected);
      }
      expect(MemberPagePalette.colors('/home', dark).first,
          dark ? const Color(0xFF3A1E25) : const Color(0xFFF1E4E9));
    });
    test('each member hub has its own tint in dark=$dark', () {
      final colors = pages.map((path) => MemberPagePalette.colors(path, dark));
      expect(
          colors.map((palette) => palette.first).toSet().length, pages.length);
      for (final palette in colors) {
        expect(palette.last,
            dark ? const Color(0xFF151517) : const Color(0xFFF7F7F8));
        expect(palette.every((color) => color.a == 1), isTrue);
      }
    });
    test('detail pages retain their parent section tint in dark=$dark', () {
      expect(MemberPagePalette.colors('/events/event-id', dark),
          MemberPagePalette.colors('/events', dark));
      expect(MemberPagePalette.colors('/media/albums/album-id', dark),
          MemberPagePalette.colors('/media', dark));
    });
  }
}
