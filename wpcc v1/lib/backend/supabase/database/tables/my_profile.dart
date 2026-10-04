import '../database.dart';

class MyProfileTable extends SupabaseTable<MyProfileRow> {
  @override
  String get tableName => 'my_profile';

  @override
  MyProfileRow createRow(Map<String, dynamic> data) => MyProfileRow(data);
}

class MyProfileRow extends SupabaseDataRow {
  MyProfileRow(super.data);

  @override
  SupabaseTable get table => MyProfileTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  String? get avatar => getField<String>('avatar');
  set avatar(String? value) => setField<String>('avatar', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  String? get membershipCode => getField<String>('membership_code');
  set membershipCode(String? value) =>
      setField<String>('membership_code', value);

  String? get memberIdDisplay => getField<String>('member_id_display');
  set memberIdDisplay(String? value) =>
      setField<String>('member_id_display', value);

  DateTime? get memberSince => getField<DateTime>('member_since');
  set memberSince(DateTime? value) => setField<DateTime>('member_since', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get branchName => getField<String>('branch_name');
  set branchName(String? value) => setField<String>('branch_name', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentName => getField<String>('department_name');
  set departmentName(String? value) =>
      setField<String>('department_name', value);

  String? get roleName => getField<String>('role_name');
  set roleName(String? value) => setField<String>('role_name', value);

  String? get leadershipTitle => getField<String>('leadership_title');
  set leadershipTitle(String? value) =>
      setField<String>('leadership_title', value);

  bool? get isVerified => getField<bool>('is_verified');
  set isVerified(bool? value) => setField<bool>('is_verified', value);

  String? get statusLabel => getField<String>('status_label');
  set statusLabel(String? value) => setField<String>('status_label', value);

  int? get coursesCompletedCount => getField<int>('courses_completed_count');
  set coursesCompletedCount(int? value) =>
      setField<int>('courses_completed_count', value);

  int? get classesInProgressCount => getField<int>('classes_in_progress_count');
  set classesInProgressCount(int? value) =>
      setField<int>('classes_in_progress_count', value);

  int? get pendingClassesCount => getField<int>('pending_classes_count');
  set pendingClassesCount(int? value) =>
      setField<int>('pending_classes_count', value);

  int? get queriesCount => getField<int>('queries_count');
  set queriesCount(int? value) => setField<int>('queries_count', value);

  int? get attendanceRatePercent => getField<int>('attendance_rate_percent');
  set attendanceRatePercent(int? value) =>
      setField<int>('attendance_rate_percent', value);

  String? get nextPendingClassTitle =>
      getField<String>('next_pending_class_title');
  set nextPendingClassTitle(String? value) =>
      setField<String>('next_pending_class_title', value);

  String? get nextPendingClassMeta =>
      getField<String>('next_pending_class_meta');
  set nextPendingClassMeta(String? value) =>
      setField<String>('next_pending_class_meta', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get occupation => getField<String>('occupation');
  set occupation(String? value) => setField<String>('occupation', value);

  String? get residentialAddress => getField<String>('residential_address');
  set residentialAddress(String? value) =>
      setField<String>('residential_address', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  String? get maritalStatus => getField<String>('marital_status');
  set maritalStatus(String? value) => setField<String>('marital_status', value);

  DateTime? get dateOfBirth => getField<DateTime>('date_of_birth');
  set dateOfBirth(DateTime? value) => setField<DateTime>('date_of_birth', value);

  String? get emergencyContact => getField<String>('emergency_contact');
  set emergencyContact(String? value) =>
      setField<String>('emergency_contact', value);

  DateTime? get waterBaptismDate =>
      getField<DateTime>('water_baptism_date');
  set waterBaptismDate(DateTime? value) =>
      setField<DateTime>('water_baptism_date', value);

  String? get maturityClassCompleted =>
      getField<String>('maturity_class_completed');
  set maturityClassCompleted(String? value) =>
      setField<String>('maturity_class_completed', value);

  String? get ministryClassCompleted =>
      getField<String>('ministry_class_completed');
  set ministryClassCompleted(String? value) =>
      setField<String>('ministry_class_completed', value);

  String? get missionClassCompleted =>
      getField<String>('mission_class_completed');
  set missionClassCompleted(String? value) =>
      setField<String>('mission_class_completed', value);
}
