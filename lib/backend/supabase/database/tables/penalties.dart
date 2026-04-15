import '../database.dart';

class PenaltiesTable extends SupabaseTable<PenaltiesRow> {
  @override
  String get tableName => 'penalties';

  @override
  PenaltiesRow createRow(Map<String, dynamic> data) => PenaltiesRow(data);
}

class PenaltiesRow extends SupabaseDataRow {
  PenaltiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PenaltiesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get reportedBy => getField<String>('reported_by');
  set reportedBy(String? value) => setField<String>('reported_by', value);

  String? get reason => getField<String>('reason');
  set reason(String? value) => setField<String>('reason', value);

  String? get punishment => getField<String>('punishment');
  set punishment(String? value) => setField<String>('punishment', value);

  bool? get active => getField<bool>('active');
  set active(bool? value) => setField<bool>('active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
