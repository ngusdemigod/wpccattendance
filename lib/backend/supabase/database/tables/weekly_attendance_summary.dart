import '../database.dart';

class WeeklyAttendanceSummaryTable
    extends SupabaseTable<WeeklyAttendanceSummaryRow> {
  @override
  String get tableName => 'weekly_attendance_summary';

  @override
  WeeklyAttendanceSummaryRow createRow(Map<String, dynamic> data) =>
      WeeklyAttendanceSummaryRow(data);
}

class WeeklyAttendanceSummaryRow extends SupabaseDataRow {
  WeeklyAttendanceSummaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WeeklyAttendanceSummaryTable();

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  int? get totalAttendance => getField<int>('total_attendance');
  set totalAttendance(int? value) => setField<int>('total_attendance', value);

  int? get uniqueAttendees => getField<int>('unique_attendees');
  set uniqueAttendees(int? value) => setField<int>('unique_attendees', value);

  DateTime? get weekStart => getField<DateTime>('week_start');
  set weekStart(DateTime? value) => setField<DateTime>('week_start', value);
}
