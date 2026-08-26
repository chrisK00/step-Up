import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:step_up/friends/models.dart';
import 'package:step_up/race/race_player.dart';
import 'package:step_up/step_up_api_service.dart';
import 'package:step_up/steps/health_helper.dart';

const int dailyStepGoal = 10000;

class HealthStepsWidget extends StatefulWidget {
  const HealthStepsWidget({super.key});

  @override
  State<HealthStepsWidget> createState() => _HealthStepsWidgetState();
}

class _HealthStepsWidgetState extends State<HealthStepsWidget> {
  List<RacePlayer> _players = [];
  List<ReceivedReactionResponse> _receivedReactions = [];
  String _status = 'Loading...';
  bool _isDisposed = false;
  final Health _health = Health();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initSteps();
  }

  Future<void> _initSteps() async {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;

    if (isToday) {
      final healthSteps = await HealthHelper.getStepsFromHealth(_health);
      final updateStepsResponse = await StepUpApiService.postSteps(healthSteps);

      if (updateStepsResponse == null || updateStepsResponse.statusCode != 201) {
        safeSetState(() => _status = 'Error sending steps: ${updateStepsResponse?.statusCode}');
      } else {
        safeSetState(() => _status = '');
      }
    } else {
      safeSetState(() => _status = '');
    }

    final results = await Future.wait([
      StepUpApiService.getRaceLeaderboard(date: _selectedDate),
      StepUpApiService.getReceivedReactions(),
    ]);

    safeSetState(() {
      _players = results[0] as List<RacePlayer>;
      _receivedReactions = results[1] as List<ReceivedReactionResponse>;
    });
  }

  void _onPlayerTap(RacePlayer player) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrent = player.isCurrent ||
        (currentUserId != null && player.userId.trim().toLowerCase() == currentUserId.trim().toLowerCase());
    if (isCurrent || !_isToday) return;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => _ThumbsUpSheet(
        username: player.username,
        hasSent: player.hasSentThumbsUp,
        onThumbsUp: () async {
          await StepUpApiService.sendThumbsUpToFriend(player.userId);
          await _initSteps();
        },
      ),
    );
  }

  void _showReceivedReactionsSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => _ReceivedReactionsSheet(reactions: _receivedReactions),
    );
  }

  String get _dayLabel {
    final now = DateTime.now();
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (selected == today) return 'Today';
    if (selected == yesterday) return 'Yesterday';
    return '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}';
  }

  void _showPreviousDay() {
    safeSetState(() {
      _selectedDate =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).subtract(const Duration(days: 1));
      _status = 'Loading...';
    });
    _initSteps();
  }

  void _showToday() {
    safeSetState(() {
      _selectedDate = DateTime.now();
      _status = 'Loading...';
    });
    _initSteps();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _dayLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_isToday && _receivedReactions.isNotEmpty)
                GestureDetector(
                  onTap: _showReceivedReactionsSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 243, 204),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${_receivedReactions.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 179, 116, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_status.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(_status),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _initSteps,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final isCurrent = player.isCurrent ||
                    (currentUserId != null &&
                        player.userId.trim().toLowerCase() == currentUserId.trim().toLowerCase());

                final int likesCount = _isToday
                    ? (isCurrent
                        ? (_receivedReactions.isNotEmpty ? _receivedReactions.length : player.thumbsUpCount)
                        : player.thumbsUpCount)
                    : 0;

                return _RaceLane(
                  rank: index + 1,
                  player: player,
                  likesCount: likesCount,
                  onTap: () => _onPlayerTap(player),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              TextButton.icon(
                onPressed: _selectedDate.day == DateTime.now().day &&
                        _selectedDate.month == DateTime.now().month &&
                        _selectedDate.year == DateTime.now().year
                    ? _showPreviousDay
                    : _showToday,
                icon: Icon(
                  _isToday ? Icons.chevron_left : Icons.today,
                  size: 18,
                ),
                label: Text(
                  _isToday ? 'Previous Day' : 'Back to Today',
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                  iconColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (_isDisposed || !mounted) return;
    setState(fn);
  }
}

class _RaceLane extends StatelessWidget {
  final int rank;
  final RacePlayer player;
  final int likesCount;
  final VoidCallback onTap;

  static const double _laneHeight = 90.0;
  static const double _iconSize = 36.0;
  static const double _trackLineHeight = 1.5;
  static const double _lineBottomOffset = 2.0;

  const _RaceLane({
    required this.rank,
    required this.player,
    required this.likesCount,
    required this.onTap,
  });

  /// Returns a medal icon for top 3, null otherwise.
  Widget? _medal() {
    return switch (rank) {
      1 => const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
      2 => const Icon(Icons.emoji_events, color: Colors.grey, size: 24),
      3 => const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 24),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (player.steps / dailyStepGoal).clamp(0.0, 1.0);
    final medal = _medal();

    return InkWell(
      onTap: onTap,
      child: Container(
        height: _laneHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final double leftPosition = progress * (constraints.maxWidth - _iconSize);
          const double lineTop = _laneHeight - _lineBottomOffset - _trackLineHeight;
          const double iconTop = lineTop - _iconSize;

          return Stack(
            children: [
              // ── Label: [medal?] username    steps [👍 (x)?] ───────────────────
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    if (medal != null) ...[medal, const SizedBox(width: 4)],
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: '${player.username.split(" ").first}  ',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: '${player.steps} steps',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (likesCount > 0) ...[
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.thumb_up,
                            size: 24,
                            color: Colors.amber,
                          ),
                          if (likesCount > 1) ...[
                            const SizedBox(width: 3),
                            Text(
                              '($likesCount)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Track line ───────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                top: lineTop,
                child: Container(height: _trackLineHeight, color: const Color.fromARGB(255, 177, 207, 177)),
              ),

              // ── Animated runner icon ─────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                left: leftPosition,
                top: iconTop,
                child: Icon(
                  Icons.directions_run,
                  size: _iconSize,
                  color: player.color,
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _ThumbsUpSheet extends StatefulWidget {
  final String username;
  final bool hasSent;
  final Future<void> Function() onThumbsUp;

  const _ThumbsUpSheet({
    required this.username,
    required this.hasSent,
    required this.onThumbsUp,
  });

  @override
  State<_ThumbsUpSheet> createState() => _ThumbsUpSheetState();
}

class _ThumbsUpSheetState extends State<_ThumbsUpSheet> {
  bool _loading = false;
  late bool _alreadySent;

  @override
  void initState() {
    super.initState();
    _alreadySent = widget.hasSent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 36 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            widget.username,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: _alreadySent || _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    final navigator = Navigator.of(context);
                    await widget.onThumbsUp();
                    if (!mounted) return;
                    setState(() {
                      _loading = false;
                      _alreadySent = true;
                    });
                    navigator.pop();
                  },
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_alreadySent ? Icons.thumb_up : Icons.thumb_up_alt_outlined),
            label: Text(_alreadySent ? 'Already sent today' : 'Send thumbs up'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReceivedReactionsSheet extends StatelessWidget {
  final List<ReceivedReactionResponse> reactions;

  const _ReceivedReactionsSheet({required this.reactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 36 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.thumb_up, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Liked today', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: reactions
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              r.fromUsername,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
