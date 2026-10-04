import '../database.dart';

class AttendanceViewTable extends SupabaseTable<AttendanceViewRow> {
  @override
  String get tableName => 'attendance_view';

  @override
  AttendanceViewRow createRow(Map<String, dynamic> data) =>
      AttendanceViewRow(data);
}

class AttendanceViewRow extends SupabaseDataRow {
  AttendanceViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AttendanceViewTable();

  String? get attendanceId => getField<String>('attendance_id');
  set attendanceId(String? value) => setField<String>('attendance_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get profileFullName => getField<String>('profile_full_name');
  set profileFullName(String? value) =>
      setField<String>('profile_full_name', value);

  String? get attendanceFullname => getField<String>('attendance_fullname');
  set attendanceFullname(String? value) =>
      setField<String>('attendance_fullname', value);

  String? get eventId => getField<String>('event_id');
  set eventId(String? value) => setField<String>('event_id', value);

  String? get eventTitle => getField<String>('event_title');
  set eventTitle(String? value) => setField<String>('event_title', value);

  DateTime? get eventDate => getField<DateTime>('event_date');
  set eventDate(DateTime? value) => setField<DateTime>('event_date', value);

  String? get eventScope => getField<String>('event_scope');
  set eventScope(String? value) => setField<String>('event_scope', value);

  String? get attendanceStatus => getField<String>('attendance_status');
  set attendanceStatus(String? value) =>
      setField<String>('attendance_status', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get branchName => getField<String>('branch_name');
  set branchName(String? value) => setField<String>('branch_name', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentName => getField<String>('department_name');
  set departmentName(String? value) =>
      setField<String>('department_name', value);

  double? get latitude => getField<double>('latitude');
  set latitude(double? value) => setField<double>('latitude', value);

  double? get longitude => getField<double>('longitude');
  set longitude(double? value) => setField<double>('longitude', value);

  DateTime? get clockout => getField<DateTime>('clockout');
  set clockout(DateTime? value) => setField<DateTime>('clockout', value);

  String? get confirmedby => getField<String>('confirmedby');
  set confirmedby(String? value) => setField<String>('confirmedby', value);

  String? get confirmedbyName => getField<String>('confirmedby_name');
  set confirmedbyName(String? value) =>
      setField<String>('confirmedby_name', value);

  DateTime? get attendanceCreatedAt =>
      getField<DateTime>('attendance_created_at');
  set attendanceCreatedAt(DateTime? value) =>
      setField<DateTime>('attendance_created_at', value);

  String? get profileMembershipCode =>
      getField<String>('profile_membership_code');
  set profileMembershipCode(String? value) =>
      setField<String>('profile_membership_code', value);
}
