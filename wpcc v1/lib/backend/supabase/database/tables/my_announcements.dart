import '../database.dart';

class MyAnnouncementsTable extends SupabaseTable<MyAnnouncementsRow> {
  @override
  String get tableName => 'my_announcements';

  @override
  MyAnnouncementsRow createRow(Map<String, dynamic> data) =>
      MyAnnouncementsRow(data);
}

class MyAnnouncementsRow extends SupabaseDataRow {
  MyAnnouncementsRow(super.data);

  @override
  SupabaseTable get table => MyAnnouncementsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  String? get scope => getField<String>('scope');
  set scope(String? value) => setField<String>('scope', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get mediaurl => getField<String>('mediaurl');
  set mediaurl(String? value) => setField<String>('mediaurl', value);

  bool? get hasmedia => getField<bool>('hasmedia');
  set hasmedia(bool? value) => setField<bool>('hasmedia', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get scopePriority => getField<int>('scope_priority');
  set scopePriority(int? value) => setField<int>('scope_priority', value);
}
