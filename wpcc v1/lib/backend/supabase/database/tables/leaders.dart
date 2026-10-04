import '../database.dart';

class LeadersTable extends SupabaseTable<LeadersRow> {
  @override
  String get tableName => 'leaders';

  @override
  LeadersRow createRow(Map<String, dynamic> data) => LeadersRow(data);
}

class LeadersRow extends SupabaseDataRow {
  LeadersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LeadersTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get departmentId => getField<String>('department_id')!;
  set departmentId(String value) => setField<String>('department_id', value);

  String get branchId => getField<String>('branch_id')!;
  set branchId(String value) => setField<String>('branch_id', value);

  String get position => getField<String>('position')!;
  set position(String value) => setField<String>('position', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
