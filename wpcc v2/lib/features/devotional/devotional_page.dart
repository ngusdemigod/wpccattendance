import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/section_empty_state.dart';
import 'devotional_repository.dart';

class DevotionalPage extends StatefulWidget {
  const DevotionalPage({super.key});

  @override
  State<DevotionalPage> createState() => _DevotionalPageState();
}

class _DevotionalPageState extends State<DevotionalPage> {
  static const pageSize = 20;
  final DevotionalRepository repo = DevotionalRepository();
  final List<Map<String, dynamic>> rows = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  Object? error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        loading = true;
        error = null;
      });
    } else {
      if (loadingMore || !hasMore) return;
      setState(() => loadingMore = true);
    }

    try {
      final next = await repo.posts(
        offset: reset ? 0 : rows.length,
        limit: pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) rows.clear();
        rows.addAll(next);
        hasMore = next.length == pageSize;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() => _load(reset: true);

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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: rows.isEmpty
                  ? ListView(
                      children: [
                        SectionEmptyState(
                          icon: error == null
                              ? PhosphorIcons.bookOpenText()
                              : PhosphorIcons.warningCircle(),
                          message: error == null
                              ? 'No devotional posts yet'
                              : 'Unable to load devotionals',
                          height: 280,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(19, 4, 19, 30),
                      itemCount: rows.length + (hasMore ? 1 : 0) + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wisdom Devotional',
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -1,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Short devotionals to help you pray, reflect, and stay rooted through the week.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: WpccColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final rowIndex = index - 1;
                        if (rowIndex == rows.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 12),
                            child: Center(
                              child: TextButton(
                                onPressed: loadingMore
                                    ? null
                                    : () => _load(reset: false),
                                child: loadingMore
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Load more',
                                        style: TextStyle(fontSize: 12),
                                      ),
                              ),
                            ),
                          );
                        }
                        final post = rows[rowIndex];
                        final metadata = Map<String, dynamic>.from(
                          (post['more'] as Map?) ?? const {},
                        );
                        final tag = metadata['tag']?.toString() ??
                            (rowIndex == 0 ? 'Today' : 'Devotional');
                        final author = metadata['author']?.toString() ??
                            'WPCC Devotional Desk';
                        final readTime =
                            metadata['read_time']?.toString() ?? '3 min read';
                        return InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => context.push(
                            '/devotional/${post['id']}',
                            extra: post,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: WpccColors.ink,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _date(post['created_at']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: WpccColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  post['title']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  post['body']?.toString() ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: WpccColors.inkSoft,
                                        height: 1.5,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$author · $readTime',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: WpccColors.muted,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'Read post',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: WpccColors.primaryDeep,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _date(dynamic value) =>
      WpccTime.transactionDate(value).split(' · ').first;
}
