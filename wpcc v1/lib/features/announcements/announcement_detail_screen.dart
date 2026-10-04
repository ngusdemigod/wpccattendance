import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/widgets/wpcc_shimmer.dart';
import '../home/home_feed_models.dart';
import 'announcement_repository.dart';
import 'widgets/announcement_card.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  static const String routeName = 'AnnouncementDetail';
  static const String routePath = '/announcements/:announcementId';

  final String announcementId;

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final AnnouncementRepository _repository = AnnouncementRepository();
  final TextEditingController _commentController = TextEditingController();
  bool _loading = true;
  bool _posting = false;
  HomeAnnouncement? _announcement;
  List<AnnouncementComment> _comments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final announcement =
        await _repository.fetchAnnouncementById(widget.announcementId);
    final comments = announcement == null
        ? const <AnnouncementComment>[]
        : await _repository.fetchComments(widget.announcementId);
    if (!mounted) {
      return;
    }
    setState(() {
      _announcement = announcement;
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _acknowledge() async {
    await _repository.acknowledgeAnnouncement(widget.announcementId);
    await _load();
  }

  Future<void> _shareAnnouncement() async {
    final announcement = _announcement;
    if (announcement == null) {
      return;
    }
    final payload =
        '${announcement.title}\n${announcement.body}\n${announcement.deepLinkPath}';
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement link copied')),
    );
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _posting) {
      return;
    }
    setState(() => _posting = true);
    try {
      await _repository.createComment(
        announcementId: widget.announcementId,
        body: body,
      );
      _commentController.clear();
      await _load();
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: WpccScreenShimmer(includeBottomNavSpace: false),
        ),
      );
    }

    final announcement = _announcement;
    if (announcement == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailHeader(onBack: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 24),
                const Text(
                  'Announcement not found.',
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  AnnouncementCardWidget(
                    announcement: announcement,
                    onShare: _shareAnnouncement,
                    onGotIt: _acknowledge,
                  ),
                  const SizedBox(height: 18),
                  if (announcement.allowComments) ...[
                    Row(
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 12,
                            color: Color(0xFF8A8F98),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CommentComposer(
                      controller: _commentController,
                      busy: _posting,
                      onSubmit: _submitComment,
                    ),
                    const SizedBox(height: 16),
                    if (_comments.isEmpty)
                      const _DetailMessage(
                        message: 'No comments yet for this announcement.',
                      )
                    else
                      ..._comments.map(
                        (comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CommentCard(comment: comment),
                        ),
                      ),
                  ] else
                    const _DetailMessage(
                      message: 'Comments are disabled for this announcement.',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFCFBF9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x1A111827)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Announcement',
              style: TextStyle(
                fontFamily: 'Instrument Serif',
                fontSize: 28,
                color: Color(0xFF111827),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1A111827)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add a comment',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 13,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: busy ? null : onSubmit,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111113),
                borderRadius: BorderRadius.circular(999),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(
                        fontFamily: 'Instrument Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
  });

  final AnnouncementComment comment;

  @override
  Widget build(BuildContext context) {
    final background = _avatarBackgroundFor(comment.fullName);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1A111827)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              comment.initials,
              style: const TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.fullName,
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeLabel(comment.createdAt),
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 10,
                    color: Color(0xFF8A8F98),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.body,
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _avatarBackgroundFor(String seed) {
    const palette = [
      Color(0xFFF1EADD),
      Color(0xFFE4F0FB),
      Color(0xFFE3F5E9),
      Color(0xFFF3E8E5),
      Color(0xFFECEFF3),
    ];
    final index =
        seed.codeUnits.fold<int>(0, (sum, char) => sum + char) % palette.length;
    return palette[index];
  }

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1A111827)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Instrument Sans',
          fontSize: 12,
          color: Color(0xFF4B5563),
          height: 1.5,
        ),
      ),
    );
  }
}
