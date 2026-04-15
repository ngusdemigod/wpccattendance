import '../database.dart';

class EventsTable extends SupabaseTable<EventsRow> {
  @override
  String get tableName => 'events';

  @override
  EventsRow createRow(Map<String, dynamic> data) => EventsRow(data);
}

class EventsRow extends SupabaseDataRow {
  EventsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EventsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  DateTime? get eventDate => getField<DateTime>('event_date');
  set eventDate(DateTime? value) => setField<DateTime>('event_date', value);

  String get scope => getField<String>('scope')!;
  set scope(String value) => setField<String>('scope', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  bool? get isactive => getField<bool>('isactive');
  set isactive(bool? value) => setField<bool>('isactive', value);

  String? get closedBy => getField<String>('closed by');
  set closedBy(String? value) => setField<String>('closed by', value);

  DateTime? get endtime => getField<DateTime>('endtime');
  set endtime(DateTime? value) => setField<DateTime>('endtime', value);

  String? get featuredUrl => getField<String>('featured_url');
  set featuredUrl(String? value) => setField<String>('featured_url', value);
}
