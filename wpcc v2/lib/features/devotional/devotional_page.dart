import 'package:flutter/material.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/adaptive_layout.dart';
import '../../core/widgets/member_components.dart';
import '../../core/theme/member_theme.dart';
import '../../core/utils/wpcc_time.dart';
import 'devotional_repository.dart';

class DevotionalPage extends StatefulWidget {
  const DevotionalPage({super.key, this.loadPosts});
  final Future<List<Map<String, dynamic>>> Function({int offset, int limit})?
      loadPosts;

  @override
  State<DevotionalPage> createState() => _DevotionalPageState();
}

class _DevotionalPageState extends State<DevotionalPage> {
  static const pageSize = 20;
  late final DevotionalRepository repo = DevotionalRepository();
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
      final next = await (widget.loadPosts ?? repo.posts)(
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
  Widget build(BuildContext context) => Scaffold(
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: memberPagePadding(context),
            children: [
              MemberPageHeader(
                  title: 'Devotional',
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  actions: [
                    MemberIconButton(
                      icon: PhosphorIconsRegular.export,
                      label: 'Share devotional',
                      plain: true,
                      onPressed: rows.isEmpty ? null : () => _share(rows.first),
                    ),
                  ]),
              if (loading)
                const Padding(
                    padding: EdgeInsets.all(40), child: MemberSkeleton())
              else if (rows.isEmpty)
                MemberStatus(
                  icon: error == null
                      ? PhosphorIconsRegular.bookOpenText
                      : PhosphorIconsRegular.warningCircle,
                  message: error == null
                      ? 'No devotional posts yet'
                      : 'Unable to load devotionals',
                  onRetry: error == null ? null : _refresh,
                )
              else ...[
                _reading(rows.first),
                if (rows.length > 1) ...[
                  const SizedBox(height: 28),
                  const MemberSectionHeader(title: 'More devotionals'),
                  AdaptiveCards(
                      minimumWidth: 340,
                      maximumColumns: 2,
                      children: rows.skip(1).map(_post).toList()),
                ],
                if (error != null)
                  MemberStatus(
                      message: 'Unable to load more devotionals',
                      onRetry: () => _load(reset: false)),
                if (hasMore)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                          child: TextButton(
                        onPressed:
                            loadingMore ? null : () => _load(reset: false),
                        child: loadingMore
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Load more'),
                      ))),
              ],
            ],
          ),
        ),
      );

  Future<void> _share(Map<String, dynamic> post) async {
    await Clipboard.setData(ClipboardData(
        text: [post['title'], post['body']]
            .where((value) => value?.toString().isNotEmpty == true)
            .join('\n\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Devotional copied')));
  }

  Widget _reading(Map<String, dynamic> post) {
    final metadata =
        Map<String, dynamic>.from((post['more'] as Map?) ?? const {});
    final text = Theme.of(context).textTheme;
    final detail = _metadata(post);
    final artwork = LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.clamp(0.0, 680.0);
      final height = (width * .75).clamp(0.0, 430.0);
      return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
              width: width,
              height: height,
              child: MemberArtwork(
                  imageUrl: metadata['image_url']?.toString(),
                  size: width,
                  radius: 20,
                  icon: PhosphorIconsRegular.bookOpenText)));
    });
    return AdaptiveSections(gap: 40, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        artwork,
        const SizedBox(height: 22),
        if (metadata['tag']?.toString().isNotEmpty == true) ...[
          Text(metadata['tag'].toString(), style: text.bodySmall),
          const SizedBox(height: 9),
        ],
        Text(post['title']?.toString() ?? 'Devotional',
            style: MemberVisuals.display(context)),
      ]),
      Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (detail.isNotEmpty)
              Text(detail,
                  style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (post['body']?.toString().trim().isNotEmpty == true) ...[
              const SizedBox(height: 18),
              Text(post['body'].toString(),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 22),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/devotional/${post['id']}', extra: post),
                    icon:
                        const Icon(PhosphorIconsRegular.bookOpenText, size: 20),
                    label: const Text('Read devotional'))),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                    onPressed: () => context.push('/prayer-alerts'),
                    style: TextButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerLow),
                    icon: const Icon(PhosphorIconsRegular.heart, size: 20),
                    label: const Text('Prayer'))),
          ]),
        ),
      ),
    ]);
  }

  String _metadata(Map<String, dynamic> post) {
    final metadata =
        Map<String, dynamic>.from((post['more'] as Map?) ?? const {});
    return [
      if (post['created_at'] != null) _date(post['created_at']),
      if (metadata['author']?.toString().isNotEmpty == true)
        metadata['author'].toString(),
      if (metadata['read_time']?.toString().isNotEmpty == true)
        metadata['read_time'].toString(),
    ].where((value) => value.isNotEmpty).join(' · ');
  }

  Widget _post(Map<String, dynamic> post) {
    final metadata =
        Map<String, dynamic>.from((post['more'] as Map?) ?? const {});
    final title = post['title']?.toString() ?? 'Devotional';
    final detail = _metadata(post);
    void open() => context.push('/devotional/${post['id']}', extra: post);
    return MemberListRow(
      title: title,
      subtitle: detail,
      leading: MemberArtwork(
          imageUrl: metadata['image_url']?.toString(),
          size: 52,
          icon: PhosphorIconsRegular.bookOpenText),
      onTap: open,
    );
  }

  String _date(dynamic value) =>
      WpccTime.transactionDate(value).split(' · ').first;
}
