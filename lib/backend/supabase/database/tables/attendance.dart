import '../database.dart';

class AttendanceTable extends SupabaseTable<AttendanceRow> {
  @override
  String get tableName => 'attendance';

  @override
  AttendanceRow createRow(Map<String, dynamic> data) => AttendanceRow(data);
}

class AttendanceRow extends SupabaseDataRow {
  AttendanceRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AttendanceTable();

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

  String get fullname => getField<String>('fullname')!;
  set fullname(String value) => setField<String>('fullname', value);

  String? get confirmedby => getField<String>('confirmedby');
  set confirmedby(String? value) => setField<String>('confirmedby', value);

  String? get confirmedbyName => getField<String>('confirmedby_name');
  set confirmedbyName(String? value) =>
      setField<String>('confirmedby_name', value);

  DateTime? get clockout => getField<DateTime>('clockout');
  set clockout(DateTime? value) => setField<DateTime>('clockout', value);
}
