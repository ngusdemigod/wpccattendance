import '../database.dart';

class AnnouncementsTable extends SupabaseTable<AnnouncementsRow> {
  @override
  String get tableName => 'announcements';

  @override
  AnnouncementsRow createRow(Map<String, dynamic> data) =>
      AnnouncementsRow(data);
}

class AnnouncementsRow extends SupabaseDataRow {
  AnnouncementsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnnouncementsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get content => getField<String>('content')!;
  set content(String value) => setField<String>('content', value);

  String get scope => getField<String>('scope')!;
  set scope(String value) => setField<String>('scope', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get mediaurl => getField<String>('mediaurl');
  set mediaurl(String? value) => setField<String>('mediaurl', value);

  bool? get hasmedia => getField<bool>('hasmedia');
  set hasmedia(bool? value) => setField<bool>('hasmedia', value);
}
