import '../database.dart';

class LeadershipTitlesTable extends SupabaseTable<LeadershipTitlesRow> {
  @override
  String get tableName => 'leadership_titles';

  @override
  LeadershipTitlesRow createRow(Map<String, dynamic> data) =>
      LeadershipTitlesRow(data);
}

class LeadershipTitlesRow extends SupabaseDataRow {
  LeadershipTitlesRow(super.data);

  @override
  SupabaseTable get table => LeadershipTitlesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get code => getField<String>('code')!;
  set code(String value) => setField<String>('code', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String get parentRoleId => getField<String>('parent_role_id')!;
  set parentRoleId(String value) => setField<String>('parent_role_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
