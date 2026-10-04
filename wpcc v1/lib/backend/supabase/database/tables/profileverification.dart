import '../database.dart';

class ProfileverificationTable extends SupabaseTable<ProfileverificationRow> {
  @override
  String get tableName => 'profileverification';

  @override
  ProfileverificationRow createRow(Map<String, dynamic> data) =>
      ProfileverificationRow(data);
}

class ProfileverificationRow extends SupabaseDataRow {
  ProfileverificationRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProfileverificationTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get memberid => getField<String>('memberid')!;
  set memberid(String value) => setField<String>('memberid', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  String? get verifiedby => getField<String>('verifiedby');
  set verifiedby(String? value) => setField<String>('verifiedby', value);
}
