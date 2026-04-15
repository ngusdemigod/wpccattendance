import '../database.dart';

class EventsAttendanceViewTable extends SupabaseTable<EventsAttendanceViewRow> {
  @override
  String get tableName => 'events_attendance_view';

  @override
  EventsAttendanceViewRow createRow(Map<String, dynamic> data) =>
      EventsAttendanceViewRow(data);
}

class EventsAttendanceViewRow extends SupabaseDataRow {
  EventsAttendanceViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EventsAttendanceViewTable();

  String? get eventId => getField<String>('event_id');
  set eventId(String? value) => setField<String>('event_id', value);

  DateTime? get createdTime => getField<DateTime>('created_time');
  set createdTime(DateTime? value) => setField<DateTime>('created_time', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get featuredImage => getField<String>('featured_image');
  set featuredImage(String? value) => setField<String>('featured_image', value);

  int? get activeWorker => getField<int>('active_worker');
  set activeWorker(int? value) => setField<int>('active_worker', value);

  int? get totalWorkers => getField<int>('total_workers');
  set totalWorkers(int? value) => setField<int>('total_workers', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get closedBy => getField<String>('closed_by');
  set closedBy(String? value) => setField<String>('closed_by', value);

  String? get eventScope => getField<String>('event_scope');
  set eventScope(String? value) => setField<String>('event_scope', value);

  DateTime? get eventStartDate => getField<DateTime>('event_start_date');
  set eventStartDate(DateTime? value) =>
      setField<DateTime>('event_start_date', value);

  DateTime? get eventEndTime => getField<DateTime>('event_end_time');
  set eventEndTime(DateTime? value) =>
      setField<DateTime>('event_end_time', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get eventBranchId => getField<String>('event_branch_id');
  set eventBranchId(String? value) =>
      setField<String>('event_branch_id', value);
}
