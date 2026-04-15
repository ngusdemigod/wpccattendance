import '../database.dart';

class WeeklyBranchStatsTable extends SupabaseTable<WeeklyBranchStatsRow> {
  @override
  String get tableName => 'weekly_branch_stats';

  @override
  WeeklyBranchStatsRow createRow(Map<String, dynamic> data) =>
      WeeklyBranchStatsRow(data);
}

class WeeklyBranchStatsRow extends SupabaseDataRow {
  WeeklyBranchStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WeeklyBranchStatsTable();

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  int? get workersAttended => getField<int>('workers_attended');
  set workersAttended(int? value) => setField<int>('workers_attended', value);

  int? get eventsThisWeek => getField<int>('events_this_week');
  set eventsThisWeek(int? value) => setField<int>('events_this_week', value);
}
