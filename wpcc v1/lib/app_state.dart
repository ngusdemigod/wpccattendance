import 'package:flutter/material.dart';
import 'flutter_flow/request_manager.dart';
import '/backend/schema/structs/index.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _storagpuburl = prefs.getString('ff_storagpuburl') ?? _storagpuburl;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  /// r2 public development url
  String _storagpuburl = 'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/';
  String get storagpuburl => _storagpuburl;
  set storagpuburl(String value) {
    _storagpuburl = value;
    prefs.setString('ff_storagpuburl', value);
  }

  String _eventid = '';
  String get eventid => _eventid;
  set eventid(String value) {
    _eventid = value;
  }

  final _listOfEventsManager =
      FutureRequestManager<List<EventsAttendanceViewRow>>();
  Future<List<EventsAttendanceViewRow>> listOfEvents({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<EventsAttendanceViewRow>> Function() requestFn,
  }) =>
      _listOfEventsManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearListOfEventsCache() => _listOfEventsManager.clear();
  void clearListOfEventsCacheKey(String? uniqueKey) =>
      _listOfEventsManager.clearRequest(uniqueKey);

  final _workforceManager = FutureRequestManager<List<WorkerProfilesRow>>();
  Future<List<WorkerProfilesRow>> workforce({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<WorkerProfilesRow>> Function() requestFn,
  }) =>
      _workforceManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearWorkforceCache() => _workforceManager.clear();
  void clearWorkforceCacheKey(String? uniqueKey) =>
      _workforceManager.clearRequest(uniqueKey);

  List<DepartmentSummaryViewRow> _allDepartments = [];
  List<DepartmentSummaryViewRow> get allDepartments => _allDepartments;
  set allDepartments(List<DepartmentSummaryViewRow> value) {
    _allDepartments = value;
  }

  DateTime? _departmentsLoadedAt;
  static const _departmentsCacheTtl = Duration(minutes: 5);

  Future initializeDepartments() async {
    try {
      final departments = await DepartmentSummaryViewTable().queryRows(
        queryFn: (q) => q,
        limit: 500,
      );
      _allDepartments = departments;
      _departmentsLoadedAt = DateTime.now();
    } catch (e) {
      print('Error initializing departments: $e');
    }
  }

  /// Re-runs [initializeDepartments] only when the cached department summary
  /// is missing or stale. This is invoked on every app resume and screen
  /// focus change (see `FocusReloader`), so without a staleness check it
  /// would re-fetch the full department table far more often than needed.
  Future clearAllRequestCache() async {
    final loadedAt = _departmentsLoadedAt;
    if (loadedAt != null &&
        DateTime.now().difference(loadedAt) < _departmentsCacheTtl) {
      return;
    }
    await initializeDepartments();
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
