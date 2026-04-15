import '../database.dart';

class BranchesTable extends SupabaseTable<BranchesRow> {
  @override
  String get tableName => 'branches';

  @override
  BranchesRow createRow(Map<String, dynamic> data) => BranchesRow(data);
}

class BranchesRow extends SupabaseDataRow {
  BranchesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => BranchesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String get slug => getField<String>('slug')!;
  set slug(String value) => setField<String>('slug', value);

  String get address => getField<String>('address')!;
  set address(String value) => setField<String>('address', value);

  String? get contactnumber => getField<String>('contactnumber');
  set contactnumber(String? value) => setField<String>('contactnumber', value);

  int? get lastmember => getField<int>('lastmember');
  set lastmember(int? value) => setField<int>('lastmember', value);

  String? get prefix => getField<String>('prefix');
  set prefix(String? value) => setField<String>('prefix', value);
}
