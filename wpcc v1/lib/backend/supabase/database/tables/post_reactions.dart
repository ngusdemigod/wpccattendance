import '../database.dart';

class PostReactionsTable extends SupabaseTable<PostReactionsRow> {
  @override
  String get tableName => 'post_reactions';

  @override
  PostReactionsRow createRow(Map<String, dynamic> data) =>
      PostReactionsRow(data);
}

class PostReactionsRow extends SupabaseDataRow {
  PostReactionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PostReactionsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get postId => getField<String>('post_id')!;
  set postId(String value) => setField<String>('post_id', value);

  String get reactionType => getField<String>('reaction_type')!;
  set reactionType(String value) => setField<String>('reaction_type', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
