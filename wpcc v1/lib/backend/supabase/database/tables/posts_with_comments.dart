import '../database.dart';

class PostsWithCommentsTable extends SupabaseTable<PostsWithCommentsRow> {
  @override
  String get tableName => 'posts_with_comments';

  @override
  PostsWithCommentsRow createRow(Map<String, dynamic> data) =>
      PostsWithCommentsRow(data);
}

class PostsWithCommentsRow extends SupabaseDataRow {
  PostsWithCommentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PostsWithCommentsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get targetType => getField<String>('target_type');
  set targetType(String? value) => setField<String>('target_type', value);

  String? get branchId => getField<String>('branch_id');
  set branchId(String? value) => setField<String>('branch_id', value);

  String? get branchName => getField<String>('branch_name');
  set branchName(String? value) => setField<String>('branch_name', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get departmentName => getField<String>('department_name');
  set departmentName(String? value) =>
      setField<String>('department_name', value);

  String? get body => getField<String>('body');
  set body(String? value) => setField<String>('body', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get createdByName => getField<String>('created_by_name');
  set createdByName(String? value) =>
      setField<String>('created_by_name', value);

  String? get modifiedBy => getField<String>('modified_by');
  set modifiedBy(String? value) => setField<String>('modified_by', value);

  String? get modifiedByName => getField<String>('modified_by_name');
  set modifiedByName(String? value) =>
      setField<String>('modified_by_name', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get modifiedAt => getField<DateTime>('modified_at');
  set modifiedAt(DateTime? value) => setField<DateTime>('modified_at', value);

  bool? get isPinned => getField<bool>('is_pinned');
  set isPinned(bool? value) => setField<bool>('is_pinned', value);

  dynamic? get reactions => getField<dynamic>('reactions');
  set reactions(dynamic? value) => setField<dynamic>('reactions', value);

  int? get commentsCount => getField<int>('comments_count');
  set commentsCount(int? value) => setField<int>('comments_count', value);

  dynamic? get postMore => getField<dynamic>('post_more');
  set postMore(dynamic? value) => setField<dynamic>('post_more', value);

  bool? get postArchived => getField<bool>('post_archived');
  set postArchived(bool? value) => setField<bool>('post_archived', value);

  dynamic? get comments => getField<dynamic>('comments');
  set comments(dynamic? value) => setField<dynamic>('comments', value);
}
