import '../database.dart';

class MyQueriesTable extends SupabaseTable<MyQueriesRow> {
  @override
  String get tableName => 'my_queries';

  @override
  MyQueriesRow createRow(Map<String, dynamic> data) => MyQueriesRow(data);
}

class MyQueriesRow extends SupabaseDataRow {
  MyQueriesRow(super.data);

  @override
  SupabaseTable get table => MyQueriesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get details => getField<String>('details');
  set details(String? value) => setField<String>('details', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get raisedByUserId => getField<String>('raised_by_user_id');
  set raisedByUserId(String? value) =>
      setField<String>('raised_by_user_id', value);

  String? get raisedByName => getField<String>('raised_by_name');
  set raisedByName(String? value) => setField<String>('raised_by_name', value);

  String? get raisedByDepartment => getField<String>('raised_by_department');
  set raisedByDepartment(String? value) =>
      setField<String>('raised_by_department', value);

  DateTime? get openedAt => getField<DateTime>('opened_at');
  set openedAt(DateTime? value) => setField<DateTime>('opened_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  DateTime? get closedAt => getField<DateTime>('closed_at');
  set closedAt(DateTime? value) => setField<DateTime>('closed_at', value);

  DateTime? get escalatesAt => getField<DateTime>('escalates_at');
  set escalatesAt(DateTime? value) => setField<DateTime>('escalates_at', value);

  bool? get requiresAcknowledgement =>
      getField<bool>('requires_acknowledgement');
  set requiresAcknowledgement(bool? value) =>
      setField<bool>('requires_acknowledgement', value);

  bool? get requiresResponse => getField<bool>('requires_response');
  set requiresResponse(bool? value) =>
      setField<bool>('requires_response', value);

  String? get responseText => getField<String>('response_text');
  set responseText(String? value) => setField<String>('response_text', value);

  DateTime? get acknowledgedAt => getField<DateTime>('acknowledged_at');
  set acknowledgedAt(DateTime? value) =>
      setField<DateTime>('acknowledged_at', value);

  DateTime? get respondedAt => getField<DateTime>('responded_at');
  set respondedAt(DateTime? value) => setField<DateTime>('responded_at', value);

  bool? get needsAttention => getField<bool>('needs_attention');
  set needsAttention(bool? value) => setField<bool>('needs_attention', value);
}
