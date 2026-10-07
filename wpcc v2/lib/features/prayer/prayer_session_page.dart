import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/member_theme.dart';
import 'prayer_repository.dart';
import '../rewards/rewards_repository.dart';
import '../../core/widgets/member_back.dart';

class PrayerSessionPage extends StatefulWidget {
  const PrayerSessionPage({super.key, required this.payload});
  final Map<String, dynamic> payload;

  @override
  State<PrayerSessionPage> createState() => _PrayerSessionPageState();
}

class _PrayerSessionPageState extends State<PrayerSessionPage>
    with WidgetsBindingObserver {
  final repo = PrayerRepository();
  final rewards = RewardsRepository();
  bool foreground = true;
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

  Future<void> _rewardHeartbeat() async {
    if (!foreground) return;
    try {
      await rewards.heartbeat(session['id'].toString());
    } catch (_) {
      // A later heartbeat retries; the display timer never grants points.
    }
  }

  Future<void> _syncServerClock() async {
    if (foreground && !finishing) unawaited(_rewardHeartbeat());
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
    foreground = state == AppLifecycleState.resumed;
    if (foreground) _syncServerClock();
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
      await _rewardHeartbeat();
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

    // A session is always calm and dark, whatever the app theme is.
    final theme = buildMemberTheme(buildWpccTheme(brightness: Brightness.dark));
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final gradient = MemberPagePalette.colors('/prayer-session', true);

    return MemberBackOverride(
      onBack: finishing ? () {} : () => finish('abandoned'),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) finish('abandoned');
        },
        child: Theme(
          data: theme,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: DecoratedBox(
              decoration: BoxDecoration(
                color: gradient.last,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                  stops: const [0, .35, .8, 1],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (MemberBackScope.active(context))
                                const SizedBox(width: 48, height: 48)
                              else
                                IconButton(
                                  tooltip: 'End session',
                                  onPressed: finishing
                                      ? null
                                      : () => finish('abandoned'),
                                  icon:
                                      Icon(PhosphorIcons.arrowLeft(), size: 21),
                                ),
                              Expanded(
                                child: Text(
                                  'Prayer session',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, box) => SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(minHeight: box.maxHeight),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 12),
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          alert['title']?.toString() ??
                                              'Prayer',
                                          textAlign: TextAlign.center,
                                          style: text.headlineSmall,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      _Clock(
                                        seconds: shown,
                                        progress: progress,
                                        counting: total != null,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        total == null
                                            ? 'Prayer time'
                                            : 'Countdown · ${math.max(1, total ~/ 60)} min',
                                        style: text.bodyMedium?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      if (tracks.isEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              PhosphorIconsRegular.musicNotes,
                                              size: 18,
                                              color: colors.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'No prayer audio attached',
                                                style:
                                                    text.bodyMedium?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        for (final track in tracks)
                                          _SongRow(track: track),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  finishing ? null : () => finish('abandoned'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(48, 56),
                              ),
                              child: finishing
                                  ? SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.onPrimary,
                                      ),
                                    )
                                  : const Text('End session'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Large time numerals, inside a progress ring when the session counts down.
class _Clock extends StatelessWidget {
  const _Clock({
    required this.seconds,
    required this.progress,
    required this.counting,
  });
  final int seconds;
  final double? progress;
  final bool counting;

  static String spoken(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return [
      if (h > 0) '$h ${h == 1 ? 'hour' : 'hours'}',
      if (m > 0) '$m ${m == 1 ? 'minute' : 'minutes'}',
      '$s ${s == 1 ? 'second' : 'seconds'}',
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final value = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final scaler = MediaQuery.textScalerOf(context);
    final numerals = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          textScaler: scaler.scale(56) / 56 > 1.3
              ? const TextScaler.linear(1.3)
              : scaler,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 56,
            height: 1.1,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: counting ? 'Time remaining' : 'Time prayed',
      value: spoken(seconds),
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: progress == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.onSurface.withValues(alpha: .14),
                            width: 6,
                          ),
                        ),
                      )
                    : TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: AppMotion.duration(
                          context,
                          const Duration(seconds: 1),
                        ),
                        curve: Curves.linear,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                          value: value,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor:
                              colors.onSurface.withValues(alpha: .14),
                          color: colors.onSurface,
                        ),
                      ),
              ),
              numerals,
            ],
          ),
        ),
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final playing = state == PlayerState.playing;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.track.title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text('Prayer audio', style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            tooltip: playing
                ? 'Pause ${widget.track.title}'
                : 'Play ${widget.track.title}',
            onPressed: toggle,
            style: IconButton.styleFrom(
              backgroundColor: colors.onSurface,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(48, 48),
            ),
            icon: Icon(
              playing ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
