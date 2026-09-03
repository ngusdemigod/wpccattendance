import '../database.dart';

class GlobalEventsTable extends SupabaseTable<GlobalEventsRow> {
  @override
  String get tableName => 'global_events';

  @override
  GlobalEventsRow createRow(Map<String, dynamic> data) => GlobalEventsRow(data);
}

class GlobalEventsRow extends SupabaseDataRow {
  GlobalEventsRow(super.data);

  @override
  SupabaseTable get table => GlobalEventsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  DateTime get eventStartAt => getField<DateTime>('event_start_at')!;
  set eventStartAt(DateTime value) => setField<DateTime>('event_start_at', value);

  DateTime? get eventEndAt => getField<DateTime>('event_end_at');
  set eventEndAt(DateTime? value) => setField<DateTime>('event_end_at', value);

  String? get featuredUrl => getField<String>('featured_url');
  set featuredUrl(String? value) => setField<String>('featured_url', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  double? get latitude => getField<double>('latitude');
  set latitude(double? value) => setField<double>('latitude', value);

  double? get longitude => getField<double>('longitude');
  set longitude(double? value) => setField<double>('longitude', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get sourceRecurringEventId =>
      getField<String>('source_recurring_event_id');
  set sourceRecurringEventId(String? value) =>
      setField<String>('source_recurring_event_id', value);

  String? get sourceRecurringScope =>
      getField<String>('source_recurring_scope');
  set sourceRecurringScope(String? value) =>
      setField<String>('source_recurring_scope', value);
}
