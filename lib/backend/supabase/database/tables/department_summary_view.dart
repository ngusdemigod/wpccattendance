import '../database.dart';

class DepartmentSummaryViewTable
    extends SupabaseTable<DepartmentSummaryViewRow> {
  @override
  String get tableName => 'department_summary_view';

  @override
  DepartmentSummaryViewRow createRow(Map<String, dynamic> data) =>
      DepartmentSummaryViewRow(data);
}

class DepartmentSummaryViewRow extends SupabaseDataRow {
  DepartmentSummaryViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DepartmentSummaryViewTable();

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentName => getField<String>('department_name');
  set departmentName(String? value) =>
      setField<String>('department_name', value);

  int? get personsCount => getField<int>('persons_count');
  set personsCount(int? value) => setField<int>('persons_count', value);

  int? get activeDepartmentalEvents =>
      getField<int>('active_departmental_events');
  set activeDepartmentalEvents(int? value) =>
      setField<int>('active_departmental_events', value);

  int? get pastDepartmentalEvents => getField<int>('past_departmental_events');
  set pastDepartmentalEvents(int? value) =>
      setField<int>('past_departmental_events', value);
}
