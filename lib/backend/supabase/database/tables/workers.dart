import '../database.dart';

class WorkersTable extends SupabaseTable<WorkersRow> {
  @override
  String get tableName => 'workers';

  @override
  WorkersRow createRow(Map<String, dynamic> data) => WorkersRow(data);
}

class WorkersRow extends SupabaseDataRow {
  WorkersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WorkersTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String get branchId => getField<String>('branch_id')!;
  set branchId(String value) => setField<String>('branch_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get membershipcode => getField<String>('membershipcode');
  set membershipcode(String? value) =>
      setField<String>('membershipcode', value);
}
