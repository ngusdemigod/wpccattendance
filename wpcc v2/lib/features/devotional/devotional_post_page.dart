import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/initials_avatar.dart';
import 'devotional_repository.dart';

class DevotionalPostPage extends StatefulWidget {
  const DevotionalPostPage({super.key, required this.postId, this.seed});

  final String postId;
  final Map<String, dynamic>? seed;

  @override
  State<DevotionalPostPage> createState() => _DevotionalPostPageState();
}

class _DevotionalPostPageState extends State<DevotionalPostPage> {
  static const commentsPageSize = 20;
  final DevotionalRepository repo = DevotionalRepository();
  final TextEditingController comment = TextEditingController();
  late Future<Map<String, dynamic>?> post;
  late Future<Set<String>> mine;
  final comments = <Map<String, dynamic>>[];
  bool loadingComments = true;
  bool loadingMoreComments = false;
  bool hasMoreComments = true;
  bool sending = false;
  final Set<String> updatingReactions = {};
  Object? commentsError;

  @override
  void initState() {
    super.initState();
    _reloadPost();
    _reloadComments();
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  void _reloadPost() {
    post = widget.seed != null
        ? Future.value(widget.seed)
        : repo.post(widget.postId);
    mine = repo.myReactions(widget.postId);
  }

  Future<void> _reloadComments() async {
    if (mounted) {
      setState(() {
        comments.clear();
        loadingComments = true;
        hasMoreComments = true;
        commentsError = null;
      });
    }
    try {
      final rows = await repo.comments(widget.postId, limit: commentsPageSize);
      if (!mounted) return;
      setState(() {
        comments.addAll(rows);
        hasMoreComments = rows.length == commentsPageSize;
      });
    } catch (error) {
      if (mounted) setState(() => commentsError = error);
    } finally {
      if (mounted) setState(() => loadingComments = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (loadingMoreComments || !hasMoreComments) return;
    setState(() => loadingMoreComments = true);
    try {
      final rows = await repo.comments(
        widget.postId,
        offset: comments.length,
        limit: commentsPageSize,
      );
      if (!mounted) return;
      setState(() {
        comments.addAll(rows);
        hasMoreComments = rows.length == commentsPageSize;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load more comments. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loadingMoreComments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Devotional',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: post,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final current = snapshot.data;
          if (snapshot.hasError || current == null) {
            return const Center(child: Text('Devotional unavailable'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reloadPost);
              await Future.wait([post, _reloadComments()]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(19, 4, 19, 30),
              children: [
                Text(
                  'Wisdom Devotional',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Short devotionals to help you pray, reflect, and stay rooted through the week.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WpccColors.inkSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: WpccColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        current['body']?.toString() ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.65,
                          color: WpccColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<Set<String>>(
                  future: mine,
                  builder: (context, reactionSnapshot) {
                    final selected = reactionSnapshot.data ?? <String>{};
                    final counts = Map<String, dynamic>.from(
                      (current['reaction_counts'] as Map?) ?? const {},
                    );
                    return Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: ['amen', 'helpful', 'inspired']
                          .map(
                            (type) => FilterChip(
                              selected: selected.contains(type),
                              showCheckmark: false,
                              label: Text(
                                '${_label(type)} ${counts[type] ?? 0}',
                              ),
                              onSelected: updatingReactions.contains(type)
                                  ? null
                                  : (_) =>
                                        _toggle(type, selected.contains(type)),
                              selectedColor: WpccColors.ink,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: selected.contains(type)
                                    ? Colors.white
                                    : WpccColors.inkSoft,
                              ),
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (current['comments_count'] != null)
                      Text(
                        current['comments_count'].toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: WpccColors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (loadingComments)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (commentsError != null)
                  Text(
                    'Unable to load comments.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                  )
                else if (comments.isEmpty)
                  Text(
                    'No comments yet.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WpccColors.muted),
                  )
                else ...[
                  ...comments.map(_commentRow),
                  if (hasMoreComments)
                    Center(
                      child: TextButton(
                        onPressed: loadingMoreComments
                            ? null
                            : _loadMoreComments,
                        child: loadingMoreComments
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Load more comments'),
                      ),
                    ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: comment,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: sending ? null : _send,
                      style: IconButton.styleFrom(
                        backgroundColor: WpccColors.ink,
                      ),
                      icon: sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(PhosphorIcons.arrowUp(), size: 18),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _commentRow(Map<String, dynamic> entry) {
    final name = entry['commentor name']?.toString().trim();
    final resolvedName = name?.isNotEmpty == true ? name! : 'Member';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(initials: _initials(resolvedName), size: 34),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolvedName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry['body']?.toString() ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(String type, bool active) async {
    if (updatingReactions.contains(type)) return;
    setState(() => updatingReactions.add(type));
    try {
      await repo.toggleReaction(widget.postId, type, active);
      if (mounted) {
        setState(() {
          mine = repo.myReactions(widget.postId);
          post = repo.post(widget.postId);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update your reaction. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => updatingReactions.remove(type));
    }
  }

  Future<void> _send() async {
    final value = comment.text.trim();
    if (value.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await repo.addComment(widget.postId, value);
      comment.clear();
      if (mounted) {
        setState(() => post = repo.post(widget.postId));
        await _reloadComments();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to post your comment. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  String _label(String type) => switch (type) {
    'amen' => 'Amen',
    'helpful' => 'Helpful',
    'inspired' => 'Inspired',
    _ => type,
  };

  String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
