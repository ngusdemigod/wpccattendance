import '../database.dart';

class MembershipcodeTable extends SupabaseTable<MembershipcodeRow> {
  @override
  String get tableName => 'membershipcode';

  @override
  MembershipcodeRow createRow(Map<String, dynamic> data) =>
      MembershipcodeRow(data);
}

class MembershipcodeRow extends SupabaseDataRow {
  MembershipcodeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MembershipcodeTable();

  String get memberid => getField<String>('memberid')!;
  set memberid(String value) => setField<String>('memberid', value);

  String get membershipcode => getField<String>('membershipcode')!;
  set membershipcode(String value) => setField<String>('membershipcode', value);
}
