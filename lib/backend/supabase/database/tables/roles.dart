import '../database.dart';

class RolesTable extends SupabaseTable<RolesRow> {
  @override
  String get tableName => 'roles';

  @override
  RolesRow createRow(Map<String, dynamic> data) => RolesRow(data);
}

class RolesRow extends SupabaseDataRow {
  RolesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RolesTable();

  String get memberid => getField<String>('memberid')!;
  set memberid(String value) => setField<String>('memberid', value);

  String get fullName => getField<String>('full_name')!;
  set fullName(String value) => setField<String>('full_name', value);

  String get roleid => getField<String>('roleid')!;
  set roleid(String value) => setField<String>('roleid', value);

  String? get rolename => getField<String>('rolename');
  set rolename(String? value) => setField<String>('rolename', value);
}
