import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wpcc_community/features/departments/department_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wpcc_community/features/departments/department_repository.dart';
import 'package:wpcc_community/features/departments/admin/department_profile_edit_page.dart';
import 'package:wpcc_community/features/departments/admin/department_requests_page.dart';

class FakeDepartmentRepository extends DepartmentRepository {
  FakeDepartmentRepository(super.client);
  bool manager = true;
  final decisions = <bool>[];
  @override
  Future<List<Map<String, dynamic>>> leadership(String id) async => [];
  @override
  Future<List<Map<String, dynamic>>> members(String id, {String search = ''}) async => [];
  @override
  Future<List<Map<String, dynamic>>> attendanceEvents(String id) async => [];
  @override
  Future<List<Map<String, dynamic>>> files(String id) async => [];
  @override
  Future<List<Map<String, dynamic>>> wallets(String id) async => [];
  @override
  Future<Map<String, dynamic>?> context(String departmentId) async => {
        'name': 'Media & Technical',
        'can_manage': manager,
        'branch_id': 'branch',
      };
  @override
  Future<List<Map<String, dynamic>>> pendingRequests(
          String departmentId) async =>
      decisions.isEmpty
          ? [
              {'id': 'request', 'full_name': 'Pending Member'}
            ]
          : [];
  @override
  Future<void> reviewRequest(
      String departmentId, String requestId, bool approve) async {
    decisions.add(approve);
  }
}

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient('https://example.test', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => client.dispose());
  testWidgets('join another department returns to a single usable shell', (tester) async {
    final repo = FakeDepartmentRepository(client)..manager = false;
    final router = GoRouter(initialLocation: '/departments', routes: [
      ShellRoute(builder: (_, __, child) => Scaffold(body: child), routes: [
        GoRoute(path: '/departments', builder: (context, _) => TextButton(
          onPressed: () => context.push('/departments/test'),
          child: const Text('Open department'))),
        GoRoute(path: '/home', builder: (_, __) => const Text('Home ready')),
      ]),
      GoRoute(path: '/departments/:id', builder: (_, __) => DepartmentDetailPage(
        departmentId: 'test', repository: repo)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open department'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Join another department'));
    await tester.pumpAndSettle();
    expect(find.text('Open department'), findsOneWidget);
    expect(router.canPop(), isFalse);
    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('Home ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'department images keep name read-only and hide unauthorized controls',
      (tester) async {
    final repo = FakeDepartmentRepository(client);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final manager in [true, false]) {
      repo.manager = manager;
      await tester.pumpWidget(MaterialApp(
          home: DepartmentProfileEditPage(
              key: ValueKey(manager),
              departmentId: 'department',
              repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Change cover image'),
          manager ? findsOneWidget : findsNothing);
      if (manager) {
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
      }
      expect(tester.takeException(), isNull);
    }
  });

  for (final approve in [true, false]) {
    testWidgets(
        'join decision $approve requires confirmation and refreshes queue',
        (tester) async {
      final repo = FakeDepartmentRepository(client);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: DepartmentRequestsPage(
                  departmentId: 'department', repository: repo))));
      await tester.pumpAndSettle();
      final label = approve ? 'Approve' : 'Decline';
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(repo.decisions, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.decisions, isEmpty);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(repo.decisions, [approve]);
      expect(find.text('No pending join requests'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
