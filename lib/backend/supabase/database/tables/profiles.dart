import '../database.dart';

class ProfilesTable extends SupabaseTable<ProfilesRow> {
  @override
  String get tableName => 'profiles';

  @override
  ProfilesRow createRow(Map<String, dynamic> data) => ProfilesRow(data);
}

class ProfilesRow extends SupabaseDataRow {
  ProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProfilesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get branchId => getField<String>('branch_id')!;
  set branchId(String value) => setField<String>('branch_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String get fullName => getField<String>('full_name')!;
  set fullName(String value) => setField<String>('full_name', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get membershipCode => getField<String>('membership_code');
  set membershipCode(String? value) =>
      setField<String>('membership_code', value);

  DateTime? get dateJoined => getField<DateTime>('date_joined');
  set dateJoined(DateTime? value) => setField<DateTime>('date_joined', value);

  bool? get verified => getField<bool>('verified');
  set verified(bool? value) => setField<bool>('verified', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get avatar => getField<String>('avatar');
  set avatar(String? value) => setField<String>('avatar', value);

  String? get lastname => getField<String>('lastname');
  set lastname(String? value) => setField<String>('lastname', value);

  String? get firstname => getField<String>('firstname');
  set firstname(String? value) => setField<String>('firstname', value);

  String? get prefix => getField<String>('prefix');
  set prefix(String? value) => setField<String>('prefix', value);
}
