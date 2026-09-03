import 'package:flutter/material.dart';

import '../../app/theme/app_typography.dart';
import '../../app/theme/design_tokens.dart';
import '../../backend/supabase/supabase.dart';
import '../../flutter_flow/custom_icons.dart';
import '../../shared/widgets/wpcc_shimmer.dart';

class WisdomDevotionalPost {
  const WisdomDevotionalPost({required this.id, required this.title, required this.body, required this.createdAt, required this.author, required this.category, required this.readMinutes, required this.reactionCount, required this.commentCount});
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final String author;
  final String category;
  final int readMinutes;
  final int reactionCount;
  final int commentCount;

  factory WisdomDevotionalPost.fromMap(Map<String, dynamic> row) {
    final more = row['more'];
    final metadata = more is Map ? Map<String, dynamic>.from(more) : const <String, dynamic>{};
    final reactions = row['reaction_counts'];
    final reactionMap = reactions is Map ? Map<String, dynamic>.from(reactions) : const <String, dynamic>{};
    final reactionCount = reactionMap.values.fold<int>(0, (total, value) => total + (value is int ? value : int.tryParse('$value') ?? 0));
    final words = (row['body']?.toString() ?? '').trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    return WisdomDevotionalPost(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? 'Devotional',
      body: row['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      author: metadata['author_name']?.toString() ?? metadata['source_name']?.toString() ?? 'WPCC Devotional Desk',
      category: metadata['category']?.toString() ?? metadata['tag']?.toString() ?? 'Devotional',
      readMinutes: (words / 200).ceil().clamp(1, 99),
      reactionCount: reactionCount,
      commentCount: row['comments_count'] is int ? row['comments_count'] as int : int.tryParse('${row['comments_count']}') ?? 0,
    );
  }
}

class WisdomDevotionalRepository {
  const WisdomDevotionalRepository();

  Future<List<WisdomDevotionalPost>> fetchPage() async {
    final response = await SupaFlow.client.from('posts').select().order('created_at', ascending: false).limit(50);
    final rows = (response as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).where(_isDevotional).map(WisdomDevotionalPost.fromMap).toList(growable: false);
    return rows;
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final response = await SupaFlow.client.from('comments').select().eq('post_id', postId).eq('is_deleted', false).order('created_at').limit(50);
    return (response as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  static bool _isDevotional(Map row) {
    final more = row['more'];
    if (more is! Map) return false;
    final values = <Object?>[more['category'], more['type'], more['tag'], more['tags']];
    return values.any((value) => value?.toString().toLowerCase().contains('devotional') == true || value?.toString().toLowerCase().contains('wisdom') == true);
  }
}

class WisdomDevotionalScreen extends StatefulWidget {
  const WisdomDevotionalScreen({super.key, this.onOpenPost});
  final ValueChanged<WisdomDevotionalPost>? onOpenPost;
  @override State<WisdomDevotionalScreen> createState() => _WisdomDevotionalScreenState();
}

class _WisdomDevotionalScreenState extends State<WisdomDevotionalScreen> {
  final _repository = const WisdomDevotionalRepository();
  late Future<List<WisdomDevotionalPost>> _future;
  @override void initState() { super.initState(); _future = _repository.fetchPage(); }
  void _retry() => setState(() => _future = _repository.fetchPage());
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: FutureBuilder<List<WisdomDevotionalPost>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const WpccScreenShimmer();
        if (snapshot.hasError) return _MessageState(icon: FFIcons.karrowClockwise, title: 'Devotionals are unavailable', message: 'Please check your connection and try again.', action: _retry, actionLabel: 'Retry');
        final posts = snapshot.data ?? const [];
        if (posts.isEmpty) return const _MessageState(icon: FFIcons.kbookOpen, title: 'No devotionals yet', message: 'New devotional posts will appear here when they are published.');
        return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 112), children: [
          const WisdomFeatureTopBar(title: 'Devotional'),
          const SizedBox(height: 20),
          Text('Wisdom Devotional', style: context.appText.pageName()),
          const SizedBox(height: 6),
          Text('Short devotionals to help you pray, reflect, and stay rooted through the week.', style: context.appText.supportText()),
          const SizedBox(height: 16),
          ...posts.map((post) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _DevotionalCard(post: post, onTap: () => widget.onOpenPost?.call(post)))),
        ]);
      },
    )),
  );
}

class WisdomDevotionalDetailScreen extends StatefulWidget {
  const WisdomDevotionalDetailScreen({super.key, required this.post});
  final WisdomDevotionalPost post;
  @override State<WisdomDevotionalDetailScreen> createState() => _WisdomDevotionalDetailScreenState();
}
class _WisdomDevotionalDetailScreenState extends State<WisdomDevotionalDetailScreen> {
  late Future<List<Map<String, dynamic>>> _comments;
  @override void initState() { super.initState(); _comments = const WisdomDevotionalRepository().fetchComments(widget.post.id); }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: FutureBuilder<List<Map<String, dynamic>>>(future: _comments, builder: (context, snapshot) => ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 36), children: [
    WisdomFeatureTopBar(title: 'Devotional', onBack: () => Navigator.of(context).maybePop()), const SizedBox(height: 22),
    _CategoryPill(label: widget.post.category), const SizedBox(height: 14), Text(widget.post.title, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 10),
    Text('${widget.post.author} · ${widget.post.readMinutes} min read', style: context.appText.metadataText()), const SizedBox(height: 20), Text(widget.post.body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.55)), const SizedBox(height: 28),
    Row(children: [const Icon(FFIcons.kheart, size: 18), const SizedBox(width: 6), Text('${widget.post.reactionCount}', style: context.appText.metadataText()), const SizedBox(width: 18), Text('${widget.post.commentCount} comments', style: context.appText.metadataText())]), const SizedBox(height: 22),
    Text('Comments', style: context.appText.cardTitleStrong()), const SizedBox(height: 12),
    if (snapshot.connectionState != ConnectionState.done) const WpccShimmerCard(height: 80, child: SizedBox.expand()) else if (snapshot.hasError) Text('Comments could not be loaded.', style: context.appText.supportText()) else ..._commentRows(snapshot.data ?? const []),
  ]))));
  List<Widget> _commentRows(List<Map<String, dynamic>> rows) => rows.isEmpty ? [Text('No comments yet.', style: context.appText.supportText())] : rows.map((row) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _CommentCard(body: row['body']?.toString() ?? '', author: row['commentor name']?.toString() ?? 'Member'))).toList(growable: false);
}

class WisdomFeatureTopBar extends StatelessWidget { const WisdomFeatureTopBar({super.key, required this.title, this.onBack}); final String title; final VoidCallback? onBack; @override Widget build(BuildContext context) => SizedBox(height: 42, child: Row(children: [IconButton(onPressed: onBack, icon: Icon(onBack == null ? FFIcons.kcircle : FFIcons.kcaretLeft)), Expanded(child: Text(title, textAlign: TextAlign.center, style: context.appText.cardTitleStrong())), const SizedBox(width: 48)])); }
class _CategoryPill extends StatelessWidget { const _CategoryPill({required this.label}); final String label; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xFF141419), borderRadius: BorderRadius.circular(16)), child: Text(label, style: context.appText.pillLabel(color: Colors.white))); }
class _DevotionalCard extends StatelessWidget { const _DevotionalCard({required this.post, required this.onTap}); final WisdomDevotionalPost post; final VoidCallback onTap; @override Widget build(BuildContext context) => Material(color: context.tokens.surface, borderRadius: BorderRadius.circular(24), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: context.tokens.border), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_CategoryPill(label: post.category), const SizedBox(height: 12), Text(post.title, style: context.appText.cardTitleStrong()), const SizedBox(height: 7), Text(post.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.appText.supportText()), const SizedBox(height: 12), Row(children: [Expanded(child: Text('${post.author} · ${post.readMinutes} min read', style: context.appText.metadataText())), Text('Read post', style: context.appText.metadataText(color: const Color(0xFF6D3999)))])])))); }
class _CommentCard extends StatelessWidget { const _CommentCard({required this.body, required this.author}); final String body; final String author; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.tokens.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: context.tokens.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(author, style: context.appText.cardTitleStrong()), const SizedBox(height: 4), Text(body, style: context.appText.supportText())])); }
class _MessageState extends StatelessWidget { const _MessageState({required this.icon, required this.title, required this.message, this.action, this.actionLabel}); final IconData icon; final String title; final String message; final VoidCallback? action; final String? actionLabel; @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 30), const SizedBox(height: 14), Text(title, style: context.appText.cardTitleStrong()), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: context.appText.supportText()), if (action != null) Padding(padding: const EdgeInsets.only(top: 16), child: TextButton(onPressed: action, child: Text(actionLabel!)))])))); }
