import 'package:flutter/material.dart';
import 'package:step_up/step_up_api_service.dart';
import 'package:step_up/steps/step_history_entry.dart';

abstract class AchievementColors {
  static const Color tier5k = Color(0xFF00FF00);
  static const Color tier8_5k = Color(0xFF448AFF);
  static const Color tier10k = Color(0xFFFFB300);
  static const Color tier15k = Color(0xFFFF007F);
  static const Color tier20k = Color(0xFF00E5FF);
}

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  static const List<_AchievementTier> _tiers = [
    _AchievementTier('5k', 5000, AchievementColors.tier5k),
    _AchievementTier('8.5k', 8500, AchievementColors.tier8_5k),
    _AchievementTier('10k', 10000, AchievementColors.tier10k),
    _AchievementTier('15k', 15000, AchievementColors.tier15k),
    _AchievementTier('20k', 20000, AchievementColors.tier20k),
  ];

  List<StepHistoryEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await StepUpApiService.getStepHistory();
    if (!mounted) return;
    setState(() {
      _history = history ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final monthEntries =
        _history.where((entry) => entry.date.year == now.year && entry.date.month == now.month).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Monthly Achievements',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Last time each step tier was reached this month.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ..._tiers.map((tier) {
            final matches = monthEntries.where((entry) => entry.steps >= tier.threshold).toList();
            matches.sort((a, b) => b.date.compareTo(a.date));
            final latest = matches.isEmpty ? null : matches.first;
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: tier.color),
                title: Text('${tier.label} steps'),
                subtitle: Text(
                  latest == null ? 'Not reached this month' : '${latest.steps} steps on ${_formatDate(latest.date)}',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _AchievementTier {
  final String label;
  final int threshold;
  final Color color;

  const _AchievementTier(this.label, this.threshold, this.color);
}
