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
      final next = await repo.posts(offset: reset ? 0 : rows.length, limit: pageSize);
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
        title: const Text(
          'Wisdom Devotional',
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
                          icon: error == null ? PhosphorIcons.bookOpenText() : PhosphorIcons.warningCircle(),
                          message: error == null ? 'No devotional posts yet' : 'Unable to load devotionals',
                          height: 280,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                      itemCount: rows.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == rows.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 12),
                            child: Center(
                              child: TextButton(
                                onPressed: loadingMore ? null : () => _load(reset: false),
                                child: loadingMore
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Load more', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          );
                        }
                        final post = rows[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => context.push('/devotional/${post['id']}', extra: post),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['title']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(
                                  post['body']?.toString() ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WpccColors.inkSoft, height: 1.5),
                                ),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Icon(PhosphorIcons.calendarBlank(), size: 13, color: WpccColors.muted),
                                  const SizedBox(width: 5),
                                  Text(_date(post['created_at']), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted)),
                                  const Spacer(),
                                  Icon(PhosphorIcons.chatCircle(), size: 14, color: WpccColors.muted),
                                  const SizedBox(width: 4),
                                  Text('${post['comments_count'] ?? 0}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted)),
                                ]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _date(dynamic value) => WpccTime.transactionDate(value).split(' · ').first;
}
