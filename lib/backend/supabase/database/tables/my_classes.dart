import '../database.dart';

class MyClassesTable extends SupabaseTable<MyClassesRow> {
  @override
  String get tableName => 'my_classes';

  @override
  MyClassesRow createRow(Map<String, dynamic> data) => MyClassesRow(data);
}

class MyClassesRow extends SupabaseDataRow {
  MyClassesRow(super.data);

  @override
  SupabaseTable get table => MyClassesTable();

  String? get publicationId => getField<String>('publication_id');
  set publicationId(String? value) => setField<String>('publication_id', value);

  String? get courseId => getField<String>('course_id');
  set courseId(String? value) => setField<String>('course_id', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get scopeType => getField<String>('scope_type');
  set scopeType(String? value) => setField<String>('scope_type', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  int? get progressPercent => getField<int>('progress_percent');
  set progressPercent(int? value) => setField<int>('progress_percent', value);

  int? get moduleIndex => getField<int>('module_index');
  set moduleIndex(int? value) => setField<int>('module_index', value);

  int? get moduleTotal => getField<int>('module_total');
  set moduleTotal(int? value) => setField<int>('module_total', value);

  int? get remainingLessons => getField<int>('remaining_lessons');
  set remainingLessons(int? value) => setField<int>('remaining_lessons', value);

  bool? get certificateAvailable => getField<bool>('certificate_available');
  set certificateAvailable(bool? value) =>
      setField<bool>('certificate_available', value);

  DateTime? get dueAt => getField<DateTime>('due_at');
  set dueAt(DateTime? value) => setField<DateTime>('due_at', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get iconKey => getField<String>('icon_key');
  set iconKey(String? value) => setField<String>('icon_key', value);

  DateTime? get availableFrom => getField<DateTime>('available_from');
  set availableFrom(DateTime? value) =>
      setField<DateTime>('available_from', value);

  DateTime? get assignedAt => getField<DateTime>('assigned_at');
  set assignedAt(DateTime? value) => setField<DateTime>('assigned_at', value);
}
