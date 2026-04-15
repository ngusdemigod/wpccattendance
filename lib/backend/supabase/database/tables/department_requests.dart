import '../database.dart';

class DepartmentRequestsTable extends SupabaseTable<DepartmentRequestsRow> {
  @override
  String get tableName => 'department_requests';

  @override
  DepartmentRequestsRow createRow(Map<String, dynamic> data) =>
      DepartmentRequestsRow(data);
}

class DepartmentRequestsRow extends SupabaseDataRow {
  DepartmentRequestsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DepartmentRequestsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
