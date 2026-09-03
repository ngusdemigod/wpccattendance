import '../database.dart';

class MyEventsTable extends SupabaseTable<MyEventsRow> {
  @override
  String get tableName => 'my_events';

  @override
  MyEventsRow createRow(Map<String, dynamic> data) => MyEventsRow(data);
}

class MyEventsRow extends SupabaseDataRow {
  MyEventsRow(super.data);

  @override
  SupabaseTable get table => MyEventsTable();

  String? get eventId => getField<String>('event_id');
  set eventId(String? value) => setField<String>('event_id', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get eventScope => getField<String>('event_scope');
  set eventScope(String? value) => setField<String>('event_scope', value);

  String? get sourceTable => getField<String>('source_table');
  set sourceTable(String? value) => setField<String>('source_table', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  DateTime? get eventStartAt => getField<DateTime>('event_start_at');
  set eventStartAt(DateTime? value) =>
      setField<DateTime>('event_start_at', value);

  DateTime? get eventEndAt => getField<DateTime>('event_end_at');
  set eventEndAt(DateTime? value) => setField<DateTime>('event_end_at', value);

  String? get featuredImage => getField<String>('featured_image');
  set featuredImage(String? value) => setField<String>('featured_image', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  double? get latitude => getField<double>('latitude');
  set latitude(double? value) => setField<double>('latitude', value);

  double? get longitude => getField<double>('longitude');
  set longitude(double? value) => setField<double>('longitude', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
