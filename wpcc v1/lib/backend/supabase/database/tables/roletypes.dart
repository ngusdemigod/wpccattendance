import '../database.dart';

class RoletypesTable extends SupabaseTable<RoletypesRow> {
  @override
  String get tableName => 'roletypes';

  @override
  RoletypesRow createRow(Map<String, dynamic> data) => RoletypesRow(data);
}

class RoletypesRow extends SupabaseDataRow {
  RoletypesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RoletypesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get rolename => getField<String>('rolename')!;
  set rolename(String value) => setField<String>('rolename', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);
}
