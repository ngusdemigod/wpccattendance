import '../database.dart';

class CoursesTable extends SupabaseTable<CoursesRow> {
  @override
  String get tableName => 'courses';

  @override
  CoursesRow createRow(Map<String, dynamic> data) => CoursesRow(data);
}

class CoursesRow extends SupabaseDataRow {
  CoursesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CoursesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
