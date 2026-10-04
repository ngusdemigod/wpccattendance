import '../database.dart';

class DepartmentLeadershipViewTable
    extends SupabaseTable<DepartmentLeadershipViewRow> {
  @override
  String get tableName => 'department_leadership_view';

  @override
  DepartmentLeadershipViewRow createRow(Map<String, dynamic> data) =>
      DepartmentLeadershipViewRow(data);
}

class DepartmentLeadershipViewRow extends SupabaseDataRow {
  DepartmentLeadershipViewRow(super.data);

  @override
  SupabaseTable get table => DepartmentLeadershipViewTable();

  String? get leaderId => getField<String>('leader_id');
  set leaderId(String? value) => setField<String>('leader_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get userFullName => getField<String>('user_full_name');
  set userFullName(String? value) =>
      setField<String>('user_full_name', value);

  String? get userEmail => getField<String>('user_email');
  set userEmail(String? value) => setField<String>('user_email', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentName => getField<String>('department_name');
  set departmentName(String? value) =>
      setField<String>('department_name', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get titleId => getField<String>('title_id');
  set titleId(String? value) => setField<String>('title_id', value);

  String? get titleCode => getField<String>('title_code');
  set titleCode(String? value) => setField<String>('title_code', value);

  String? get titleName => getField<String>('title_name');
  set titleName(String? value) => setField<String>('title_name', value);

  String? get titleDescription => getField<String>('title_description');
  set titleDescription(String? value) =>
      setField<String>('title_description', value);

  String? get parentRoleId => getField<String>('parent_role_id');
  set parentRoleId(String? value) => setField<String>('parent_role_id', value);

  String? get parentRoleName => getField<String>('parent_role_name');
  set parentRoleName(String? value) =>
      setField<String>('parent_role_name', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
