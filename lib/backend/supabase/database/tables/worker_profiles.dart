import '../database.dart';

class WorkerProfilesTable extends SupabaseTable<WorkerProfilesRow> {
  @override
  String get tableName => 'worker_profiles';

  @override
  WorkerProfilesRow createRow(Map<String, dynamic> data) =>
      WorkerProfilesRow(data);
}

class WorkerProfilesRow extends SupabaseDataRow {
  WorkerProfilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WorkerProfilesTable();

  String? get workerId => getField<String>('worker_id');
  set workerId(String? value) => setField<String>('worker_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get branchName => getField<String>('branch_name');
  set branchName(String? value) => setField<String>('branch_name', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentName => getField<String>('department_name');
  set departmentName(String? value) =>
      setField<String>('department_name', value);

  String? get workerMembershipcode => getField<String>('worker_membershipcode');
  set workerMembershipcode(String? value) =>
      setField<String>('worker_membershipcode', value);

  DateTime? get workerCreatedAt => getField<DateTime>('worker_created_at');
  set workerCreatedAt(DateTime? value) =>
      setField<DateTime>('worker_created_at', value);

  String? get profileId => getField<String>('profile_id');
  set profileId(String? value) => setField<String>('profile_id', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get profileMembershipCode =>
      getField<String>('profile_membership_code');
  set profileMembershipCode(String? value) =>
      setField<String>('profile_membership_code', value);

  DateTime? get dateJoined => getField<DateTime>('date_joined');
  set dateJoined(DateTime? value) => setField<DateTime>('date_joined', value);

  bool? get verified => getField<bool>('verified');
  set verified(bool? value) => setField<bool>('verified', value);

  String? get avatar => getField<String>('avatar');
  set avatar(String? value) => setField<String>('avatar', value);

  String? get lastname => getField<String>('lastname');
  set lastname(String? value) => setField<String>('lastname', value);

  String? get firstname => getField<String>('firstname');
  set firstname(String? value) => setField<String>('firstname', value);

  DateTime? get profileCreatedAt => getField<DateTime>('profile_created_at');
  set profileCreatedAt(DateTime? value) =>
      setField<DateTime>('profile_created_at', value);
}
