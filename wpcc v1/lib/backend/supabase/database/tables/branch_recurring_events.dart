import '../database.dart';

class BranchRecurringEventsTable
    extends SupabaseTable<BranchRecurringEventsRow> {
  @override
  String get tableName => 'branch_recurring_events';

  @override
  BranchRecurringEventsRow createRow(Map<String, dynamic> data) =>
      BranchRecurringEventsRow(data);
}

class BranchRecurringEventsRow extends SupabaseDataRow {
  BranchRecurringEventsRow(super.data);

  @override
  SupabaseTable get table => BranchRecurringEventsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get branchId => getField<String>('branch_id')!;
  set branchId(String value) => setField<String>('branch_id', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String get recurrenceType => getField<String>('recurrence_type')!;
  set recurrenceType(String value) => setField<String>('recurrence_type', value);

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

  String? get featuredUrl => getField<String>('featured_url');
  set featuredUrl(String? value) => setField<String>('featured_url', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
