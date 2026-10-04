import '../database.dart';

class PostsTable extends SupabaseTable<PostsRow> {
  @override
  String get tableName => 'posts';

  @override
  PostsRow createRow(Map<String, dynamic> data) => PostsRow(data);
}

class PostsRow extends SupabaseDataRow {
  PostsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PostsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get targetType => getField<String>('target_type');
  set targetType(String? value) => setField<String>('target_type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String? get body => getField<String>('body');
  set body(String? value) => setField<String>('body', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get modifiedBy => getField<String>('modified_by');
  set modifiedBy(String? value) => setField<String>('modified_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get modifiedAt => getField<DateTime>('modified_at');
  set modifiedAt(DateTime? value) => setField<DateTime>('modified_at', value);

  bool? get isPinned => getField<bool>('is_pinned');
  set isPinned(bool? value) => setField<bool>('is_pinned', value);

  bool? get isArchived => getField<bool>('is_archived');
  set isArchived(bool? value) => setField<bool>('is_archived', value);

  dynamic? get reactionCounts => getField<dynamic>('reaction_counts');
  set reactionCounts(dynamic? value) =>
      setField<dynamic>('reaction_counts', value);

  int? get commentsCount => getField<int>('comments_count');
  set commentsCount(int? value) => setField<int>('comments_count', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  dynamic? get more => getField<dynamic>('more');
  set more(dynamic? value) => setField<dynamic>('more', value);
}
