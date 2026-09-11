import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import 'prayer_repository.dart';

class PrayerSessionPage extends StatefulWidget {
  const PrayerSessionPage({super.key, required this.payload});
  final Map<String, dynamic> payload;

  @override
  State<PrayerSessionPage> createState() => _PrayerSessionPageState();
}

class _PrayerSessionPageState extends State<PrayerSessionPage>
    with WidgetsBindingObserver {
  final repo = PrayerRepository();
  Timer? timer;
  Timer? serverSyncTimer;
  int elapsed = 0;
  bool finishing = false;

  late final Map<String, dynamic> alert = Map<String, dynamic>.from(
    (widget.payload['alert'] as Map?) ?? const {},
  );
  late final Map<String, dynamic> session = Map<String, dynamic>.from(
    (widget.payload['session'] as Map?) ?? const {},
  );

  int? get target =>
      int.tryParse(session['target_duration_seconds']?.toString() ?? '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncServerClock();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || finishing) return;
      setState(() => elapsed++);
      final duration = target;
      if (duration != null && elapsed >= duration) finish('completed');
    });
    serverSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncServerClock(),
    );
  }

  Future<void> _syncServerClock() async {
    try {
      final active = await repo.activeSession();
      if (mounted && active != null) {
        setState(
          () => elapsed = (active['elapsed_seconds'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (_) {
      // Display timer keeps moving locally until the next server sync succeeds.
      // It is never persisted as authoritative time.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncServerClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    serverSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> finish(String status) async {
    if (finishing) return;
    setState(() => finishing = true);
    try {
      await repo.endSession(session['id'].toString(), status: status);
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to end the prayer session. Please try again.'),
        ),
      );
    }
  }

  List<_PrayerTrack> get tracks {
    final audioUrl = alert['audio_url']?.toString().trim() ?? '';
    if (audioUrl.isEmpty) return const [];
    return [
      _PrayerTrack(
        title: alert['audio_title']?.toString().trim().isNotEmpty == true
            ? alert['audio_title'].toString().trim()
            : 'Prayer audio',
        url: audioUrl,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final total = target;
    final remaining = total == null ? null : math.max(0, total - elapsed);
    final shown = remaining ?? elapsed;
    final progress = total == null ? null : (elapsed / total).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) finish('abandoned');
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(19, 12, 19, 22),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: finishing ? null : () => finish('abandoned'),
                      icon: Icon(PhosphorIcons.arrowLeft(), size: 21),
                    ),
                    Expanded(
                      child: Text(
                        alert['title']?.toString() ?? 'Prayer',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 26),
                if (progress != null)
                  SizedBox(
                    width: 228,
                    height: 228,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 16,
                            backgroundColor: WpccColors.line,
                            color: WpccColors.lavender,
                          ),
                        ),
                        _TimerText(seconds: shown),
                      ],
                    ),
                  )
                else
                  _TimerText(seconds: shown),
                const SizedBox(height: 16),
                Text(
                  total == null
                      ? 'Prayer time'
                      : 'Countdown · ${math.max(1, total ~/ 60)} min',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: WpccColors.muted),
                ),
                const SizedBox(height: 38),
                Expanded(
                  child: tracks.isEmpty
                      ? SectionEmptyState(
                          icon: PhosphorIcons.musicNotes(),
                          message: 'No prayer audio attached',
                          height: 170,
                        )
                      : ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: [0, .78, 1],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            itemCount: tracks.length,
                            itemBuilder: (context, index) =>
                                _SongRow(track: tracks[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerText extends StatelessWidget {
  const _TimerText({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final value = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Text(
      value,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -2,
      ),
    );
  }
}

class _PrayerTrack {
  const _PrayerTrack({required this.title, required this.url});
  final String title;
  final String url;
}

class _SongRow extends StatefulWidget {
  const _SongRow({required this.track});
  final _PrayerTrack track;

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  final AudioPlayer player = AudioPlayer();
  PlayerState state = PlayerState.stopped;
  StreamSubscription<PlayerState>? stateSubscription;

  @override
  void initState() {
    super.initState();
    stateSubscription = player.onPlayerStateChanged.listen((value) {
      if (mounted) setState(() => state = value);
    });
  }

  @override
  void dispose() {
    stateSubscription?.cancel();
    player.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    try {
      if (state == PlayerState.playing) {
        await player.pause();
      } else if (state == PlayerState.paused) {
        await player.resume();
      } else {
        await player.play(UrlSource(widget.track.url));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to play this prayer audio. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    constraints: const BoxConstraints(minHeight: 102),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Prayer audio',
                style: TextStyle(fontSize: 12, color: WpccColors.muted),
              ),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: state == PlayerState.playing
              ? 'Pause ${widget.track.title}'
              : 'Play ${widget.track.title}',
          onPressed: toggle,
          style: IconButton.styleFrom(
            backgroundColor: WpccColors.ink,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
          ),
          icon: Icon(
            state == PlayerState.playing
                ? PhosphorIcons.pause()
                : PhosphorIcons.play(),
            size: 18,
          ),
        ),
      ],
    ),
  );
}
