import '../database.dart';

class ProfileAttendanceViewTable
    extends SupabaseTable<ProfileAttendanceViewRow> {
  @override
  String get tableName => 'profile_attendance_view';

  @override
  ProfileAttendanceViewRow createRow(Map<String, dynamic> data) =>
      ProfileAttendanceViewRow(data);
}

class ProfileAttendanceViewRow extends SupabaseDataRow {
  ProfileAttendanceViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProfileAttendanceViewTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get eventId => getField<String>('event_id');
  set eventId(String? value) => setField<String>('event_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  double? get latitude => getField<double>('latitude');
  set latitude(double? value) => setField<double>('latitude', value);

  double? get longitude => getField<double>('longitude');
  set longitude(double? value) => setField<double>('longitude', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get fullname => getField<String>('fullname');
  set fullname(String? value) => setField<String>('fullname', value);

  String? get profileFullName => getField<String>('profile_full_name');
  set profileFullName(String? value) =>
      setField<String>('profile_full_name', value);

  String? get profileAvatar => getField<String>('profile_avatar');
  set profileAvatar(String? value) => setField<String>('profile_avatar', value);

  String? get profileDepartmentId => getField<String>('profile_department_id');
  set profileDepartmentId(String? value) =>
      setField<String>('profile_department_id', value);

  String? get profileBranchId => getField<String>('profile_branch_id');
  set profileBranchId(String? value) =>
      setField<String>('profile_branch_id', value);

  String? get profileMembershipCode =>
      getField<String>('profile_membership_code');
  set profileMembershipCode(String? value) =>
      setField<String>('profile_membership_code', value);
}
