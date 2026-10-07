import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/core/theme/app_theme.dart';
import 'package:wpcc_community/core/theme/member_theme.dart';
import 'package:wpcc_community/core/widgets/member_components.dart';
import 'package:wpcc_community/features/events/event_detail_page.dart';
import 'package:wpcc_community/features/events/events_page.dart';

Widget _app(Widget page, Brightness brightness, double scale,
        {GlobalKey? boundary}) =>
    MaterialApp(
      theme: buildMemberTheme(buildWpccTheme(brightness: brightness)),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(
          body: RepaintBoundary(
              key: boundary, child: MemberBackdrop(child: page))),
    );

Future<void> _capture(
    WidgetTester tester, GlobalKey boundary, String name) async {
  if (Platform.environment['CAPTURE_MEMBER_UI'] != 'true') return;
  await tester.pumpAndSettle();
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final picture = await render.toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    await File('${Directory.systemTemp.path}/wpcc-member-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  testWidgets('Events search has no filter control', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: EventsPage(
      loadRecurring: () async => [],
      loadEvents: ({required limit, required offset}) async => [],
    ))));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Search filters'), findsNothing);
    expect(tester.widget<MemberSearchBar>(find.byType(MemberSearchBar)).onFilter, isNull);
  });
  testWidgets('event geometry matches reference phone and tablet bounds',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final brightness in Brightness.values) {
      for (final width in [390.0, 834.0, 1024.0]) {
        tester.view.physicalSize = Size(width, width == 834 ? 1194 : 844);
        await tester.pumpWidget(_app(
            EventsPage(
                loadRecurring: () async => [],
                loadEvents: ({required limit, required offset}) async => [
                      {'event_id': 'fixture', 'title': 'Sunday celebration'}
                    ]),
            brightness,
            1));
        await tester.pumpAndSettle();
        expect(find.text('Ongoing services'), findsOneWidget);
        expect(find.text('Upcoming events'), findsOneWidget);
        final poster = find.byType(MemberArtwork);
        expect(tester.getSize(poster).width, tester.getSize(poster).height);
        await tester.tap(find.text('Upcoming').first);
        await tester.pumpAndSettle();
        final artwork = find.byType(MemberArtwork);
        expect(tester.getSize(artwork), const Size(64, 66));
        final row =
            find.ancestor(of: artwork, matching: find.byType(Material)).first;
        expect(tester.getSize(row).height, 88);
        final material = tester.widget<Material>(row);
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.side.width, 1);
        expect(shape.borderRadius, BorderRadius.circular(20));
        expect(tester.getSize(find.byType(MemberSearchBar)).width,
            width >= 900 ? 720 : width - (width < 600 ? 40 : 64));
        final dateFilter = tester.widget<MemberIconButton>(find.ancestor(
            of: find.byTooltip('Date filter'),
            matching: find.byType(MemberIconButton)));
        expect(dateFilter.plain, isTrue);

        await tester.pumpWidget(_app(
            const EventDetailPage(eventId: 'fixture', seed: {
              'recurring_event_id': 'fixture',
              'title': 'Sunday celebration',
            }),
            brightness,
            1));
        await tester.pumpAndSettle();
        final art = find.byType(Hero);
        expect(tester.getSize(art),
            width < 600 ? const Size(350, 262.5) : const Size(680, 430));
        final gutter = width < 600 ? 20.0 : 32.0;
        final left = width >= 900 ? (width - 820) / 2 + gutter : gutter;
        expect(tester.getTopLeft(art), Offset(left, 88));
        final title = tester.widget<Text>(find.text('Sunday celebration'));
        expect(title.style!.fontSize, 26);
        expect(title.style!.height, 1.2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('direct event links can return to Events without history',
      (tester) async {
    final router = GoRouter(initialLocation: '/events/fixture', routes: [
      GoRoute(
          path: '/events', builder: (_, __) => const Text('Events landing')),
      GoRoute(
          path: '/events/:id',
          builder: (_, __) => const EventDetailPage(eventId: 'fixture', seed: {
                'recurring_event_id': 'fixture',
                'title': 'Sunday celebration',
              })),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        theme: buildMemberTheme(buildWpccTheme(brightness: Brightness.dark))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Events landing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('events and recurring detail adapt in both themes at large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 390.0, 393.0, 600.0, 768.0, 834.0, 1024.0]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          tester.view.physicalSize = Size(width, width == 834 ? 1194 : 844);
          await tester.pumpWidget(_app(
              EventsPage(
                  loadEvents: ({required limit, required offset}) async => [
                        {
                          'event_id': 'sunday',
                          'title': 'Sunday celebration',
                          'event_start_at': '2026-10-04T09:00:00Z',
                        },
                        {
                          'event_id': 'choir',
                          'title': 'Choir rehearsal and preparation',
                          'department_id': 'music',
                          'event_start_at': '2026-10-04T12:00:00Z',
                        },
                      ],
                  loadRecurring: () async => [
                        {
                          'recurring_event_id': 'prayer',
                          'title': 'Prayer and fellowship',
                          'day_of_week': 3,
                          'start_time': '18:00:00',
                        }
                      ]),
              brightness,
              scale,
              boundary: boundary));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(find.text('Upcoming'), 100,
              scrollable: find
                  .descendant(
                      of: find.byType(ListView).at(1),
                      matching: find.byType(Scrollable))
                  .first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Upcoming').first);
          await tester.pumpAndSettle();
          expect(find.text('Sunday celebration'), findsOneWidget);
          if ((width == 390 || width == 834) && scale == 1) {
            await _capture(
                tester, boundary, 'events-${width.toInt()}-${brightness.name}');
          }
          expect(find.text('Choir rehearsal and preparation'), findsOneWidget);
          await tester.drag(
              find.byType(ListView).at(1), const Offset(-1000, 0));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Recurring'));
          await tester.pumpAndSettle();
          expect(find.text('Prayer and fellowship'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(_app(
              const EventDetailPage(eventId: 'prayer', seed: {
                'recurring_event_id': 'prayer',
                'title': 'Prayer and fellowship',
                'description': 'An evening of prayer for the church community.',
                'day_of_week': 3,
                'start_time': '18:00:00',
                'end_time': '19:00:00',
                'location': 'Wisdom Power Christian Centre',
              }),
              brightness,
              scale,
              boundary: boundary));
          await tester.pumpAndSettle();
          if ((width == 390 || width == 834) && scale == 1) {
            await _capture(tester, boundary,
                'event-detail-${width.toInt()}-${brightness.name}');
          }
          await tester.drag(find.byType(ListView), const Offset(0, -1000));
          await tester.pumpAndSettle();
          expect(find.text('Check in'), findsNothing);
          expect(find.text('Directions'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });

  testWidgets('events pagination counts both church and department rows',
      (tester) async {
    final offsets = <int>[];
    await tester.pumpWidget(_app(
        EventsPage(
            loadRecurring: () async => [],
            loadEvents: ({required limit, required offset}) async {
              offsets.add(offset);
              return List.generate(
                  offset == 0 ? 20 : 1,
                  (index) => {
                        'event_id': 'event-${offset + index}',
                        'title': 'Event ${offset + index}',
                        if (index.isOdd) 'department_id': 'music',
                      });
            }),
        Brightness.light,
        1));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more'), 500,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Load more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(offsets, [0, 20]);
    expect(find.text('Load more'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('events load errors expose a working retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(_app(
        EventsPage(
            loadRecurring: () async => [],
            loadEvents: ({required limit, required offset}) async {
              if (attempts++ == 0) throw StateError('Offline');
              return [
                {'event_id': 'restored', 'title': 'Restored event'}
              ];
            }),
        Brightness.dark,
        1));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load events'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upcoming').first);
    await tester.pumpAndSettle();
    expect(find.text('Restored event'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event flyer opens uncropped and can be closed', (tester) async {
    await tester.pumpWidget(_app(
        const EventDetailPage(eventId: 'fixture', seed: {
          'recurring_event_id': 'fixture',
          'title': 'Church gathering',
          'featured_image': 'https://example.test/flyer.jpg',
        }),
        Brightness.dark,
        1));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('View full flyer'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final image = tester.widget<Image>(find.byWidgetPredicate((widget) =>
        widget is Image && widget.semanticLabel == 'Full event flyer'));
    expect(image.fit, BoxFit.contain);
    expect(image.semanticLabel, 'Full event flyer');
    await tester.tap(find.byTooltip('Close flyer'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event description expands without hiding venue or directions',
      (tester) async {
    await tester.pumpWidget(_app(
        EventDetailPage(eventId: 'long', seed: {
          'recurring_event_id': 'long',
          'title': 'Church gathering',
          'location': 'WPCC auditorium',
          'description':
              List.filled(30, 'Join our church community in worship.')
                  .join(' '),
        }),
        Brightness.dark,
        1));
    await tester.pumpAndSettle();
    expect(find.text('Venue'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Read more'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
    final description =
        tester.widget<Text>(find.textContaining('Join our church'));
    expect(description.maxLines, isNull);
    await tester.scrollUntilVisible(find.text('Show less'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.textContaining('Join our church')).maxLines,
        5);
    expect(tester.takeException(), isNull);
  });
}
