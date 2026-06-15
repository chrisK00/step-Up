import 'package:flutter/material.dart';
import 'package:health/health.dart';
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
  String _status = 'Loading...';
  bool _isDisposed = false;
  final Health _health = Health();

  @override
  void initState() {
    super.initState();
    _initSteps();
  }

  Future<void> _initSteps() async {
    final healthSteps = await HealthHelper.getStepsFromHealth(_health);
    final updateStepsResponse = await StepUpApiService.postSteps(healthSteps);

    if (updateStepsResponse == null || updateStepsResponse.statusCode != 201) {
      safeSetState(() => _status = 'Error sending steps: ${updateStepsResponse?.statusCode}');
    } else {
      safeSetState(() => _status = '');
    }

    final players = await StepUpApiService.getRaceLeaderboard();
    safeSetState(() => _players = players);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_status.isNotEmpty) Text(_status),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _initSteps,
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) => _RaceLane(
                rank: index + 1,
                player: _players[index],
              ),
            ),
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

  static const double _laneHeight = 90.0;
  static const double _iconSize = 36.0;
  static const double _trackLineHeight = 1.5;
  static const double _lineBottomOffset = 2.0;

  const _RaceLane({required this.rank, required this.player});

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

    return Container(
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
              // ── Label: [medal?] username    steps ───────────────────
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
    );
  }
}
