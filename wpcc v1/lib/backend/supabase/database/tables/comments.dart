import '../database.dart';

class CommentsTable extends SupabaseTable<CommentsRow> {
  @override
  String get tableName => 'comments';

  @override
  CommentsRow createRow(Map<String, dynamic> data) => CommentsRow(data);
}

class CommentsRow extends SupabaseDataRow {
  CommentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CommentsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get postId => getField<String>('post_id')!;
  set postId(String value) => setField<String>('post_id', value);

  String? get parentCommentId => getField<String>('parent_comment_id');
  set parentCommentId(String? value) =>
      setField<String>('parent_comment_id', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get modifiedAt => getField<DateTime>('modified_at');
  set modifiedAt(DateTime? value) => setField<DateTime>('modified_at', value);

  bool? get isEdited => getField<bool>('is_edited');
  set isEdited(bool? value) => setField<bool>('is_edited', value);

  bool? get isDeleted => getField<bool>('is_deleted');
  set isDeleted(bool? value) => setField<bool>('is_deleted', value);

  dynamic? get more => getField<dynamic>('more');
  set more(dynamic? value) => setField<dynamic>('more', value);

  String? get commentorName => getField<String>('commentor name');
  set commentorName(String? value) => setField<String>('commentor name', value);
}
