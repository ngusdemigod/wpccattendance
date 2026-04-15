import '../database.dart';

class SystemreportsTable extends SupabaseTable<SystemreportsRow> {
  @override
  String get tableName => 'systemreports';

  @override
  SystemreportsRow createRow(Map<String, dynamic> data) =>
      SystemreportsRow(data);
}

class SystemreportsRow extends SupabaseDataRow {
  SystemreportsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SystemreportsTable();

  String? get reportType => getField<String>('report_type');
  set reportType(String? value) => setField<String>('report_type', value);

  dynamic? get dataField => getField<dynamic>('data');
  set dataField(dynamic? value) => setField<dynamic>('data', value);

  DateTime? get calculatedAt => getField<DateTime>('calculated_at');
  set calculatedAt(DateTime? value) =>
      setField<DateTime>('calculated_at', value);
}
