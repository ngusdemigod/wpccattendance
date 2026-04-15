import '../database.dart';

class ProfileViewTable extends SupabaseTable<ProfileViewRow> {
  @override
  String get tableName => 'profile_view';

  @override
  ProfileViewRow createRow(Map<String, dynamic> data) => ProfileViewRow(data);
}

class ProfileViewRow extends SupabaseDataRow {
  ProfileViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProfileViewTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get firstname => getField<String>('firstname');
  set firstname(String? value) => setField<String>('firstname', value);

  String? get lastname => getField<String>('lastname');
  set lastname(String? value) => setField<String>('lastname', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get membershipCode => getField<String>('membership_code');
  set membershipCode(String? value) =>
      setField<String>('membership_code', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get branchName => getField<String>('branch_name');
  set branchName(String? value) => setField<String>('branch_name', value);

  String? get branchIdConfirm => getField<String>('branch_id_confirm');
  set branchIdConfirm(String? value) =>
      setField<String>('branch_id_confirm', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentName => getField<String>('department_name');
  set departmentName(String? value) =>
      setField<String>('department_name', value);

  String? get departmentIdConfirm => getField<String>('department_id_confirm');
  set departmentIdConfirm(String? value) =>
      setField<String>('department_id_confirm', value);

  String? get workerMembershipcode => getField<String>('worker_membershipcode');
  set workerMembershipcode(String? value) =>
      setField<String>('worker_membershipcode', value);
}
