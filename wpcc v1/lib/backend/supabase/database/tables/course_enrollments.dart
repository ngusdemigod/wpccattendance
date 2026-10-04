import '../database.dart';

class CourseEnrollmentsTable extends SupabaseTable<CourseEnrollmentsRow> {
  @override
  String get tableName => 'course_enrollments';

  @override
  CourseEnrollmentsRow createRow(Map<String, dynamic> data) =>
      CourseEnrollmentsRow(data);
}

class CourseEnrollmentsRow extends SupabaseDataRow {
  CourseEnrollmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CourseEnrollmentsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get courseId => getField<String>('course_id');
  set courseId(String? value) => setField<String>('course_id', value);

  bool? get completed => getField<bool>('completed');
  set completed(bool? value) => setField<bool>('completed', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
