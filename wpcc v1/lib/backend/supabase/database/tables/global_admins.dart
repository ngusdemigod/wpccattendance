import '../database.dart';

class GlobalAdminsTable extends SupabaseTable<GlobalAdminsRow> {
  @override
  String get tableName => 'global_admins';

  @override
  GlobalAdminsRow createRow(Map<String, dynamic> data) => GlobalAdminsRow(data);
}

class GlobalAdminsRow extends SupabaseDataRow {
  GlobalAdminsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GlobalAdminsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
