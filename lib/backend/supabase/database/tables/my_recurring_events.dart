import '../database.dart';

class MyRecurringEventsTable extends SupabaseTable<MyRecurringEventsRow> {
  @override
  String get tableName => 'my_recurring_events';

  @override
  MyRecurringEventsRow createRow(Map<String, dynamic> data) =>
      MyRecurringEventsRow(data);
}

class MyRecurringEventsRow extends SupabaseDataRow {
  MyRecurringEventsRow(super.data);

  @override
  SupabaseTable get table => MyRecurringEventsTable();

  String? get recurringEventId => getField<String>('recurring_event_id');
  set recurringEventId(String? value) =>
      setField<String>('recurring_event_id', value);

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

  String? get recurrenceType => getField<String>('recurrence_type');
  set recurrenceType(String? value) => setField<String>('recurrence_type', value);

  int? get dayOfWeek => getField<int>('day_of_week');
  set dayOfWeek(int? value) => setField<int>('day_of_week', value);

  int? get weekOfMonth => getField<int>('week_of_month');
  set weekOfMonth(int? value) => setField<int>('week_of_month', value);

  int? get dayOfMonth => getField<int>('day_of_month');
  set dayOfMonth(int? value) => setField<int>('day_of_month', value);

  int? get month => getField<int>('month');
  set month(int? value) => setField<int>('month', value);

  PostgresTime? get startTime => getField<PostgresTime>('start_time');
  set startTime(PostgresTime? value) =>
      setField<PostgresTime>('start_time', value);

  PostgresTime? get endTime => getField<PostgresTime>('end_time');
  set endTime(PostgresTime? value) => setField<PostgresTime>('end_time', value);

  String? get featuredImage => getField<String>('featured_image');
  set featuredImage(String? value) => setField<String>('featured_image', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
