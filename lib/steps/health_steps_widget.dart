import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:step_up/step_up_api_service.dart';
import 'package:step_up/steps/daily_steps.dart';
import 'package:step_up/steps/health_helper.dart';

class HealthStepsWidget extends StatefulWidget {
  const HealthStepsWidget({super.key});

  @override
  State<HealthStepsWidget> createState() => _HealthStepsWidgetState();
}

class _HealthStepsWidgetState extends State<HealthStepsWidget> {
  List<DailySteps> _usersDailySteps = [];
  var _status = 'Loading...';
  final _health = Health();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initSteps();
  }

  Future<void> _initSteps() async {
    final authHealthResult = await HealthHelper.authenticateHealth(_health);

    if (!authHealthResult) {
      safeSetState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
      return;
    }

    final healthSteps = await HealthHelper.getStepsFromHealth(_health);
    final updateStepsResponse = await StepUpApiService.postSteps(healthSteps);

    final steps = await StepUpApiService.getSteps();

    final friendsSteps = await StepUpApiService.getFriendsSteps();

    safeSetState(() {
      _usersDailySteps = steps ?? [];
      _usersDailySteps.addAll(friendsSteps ?? []);
      _status = '';
    });
  }

// TODO API request to fetch friends steps once i have sent my steps for today
// TODO create a background job to report the steps every X, and when opening this screen ofc (får såklart ha någon form av refresh time så man ej spammar steg)
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(_status),
          Expanded(
              child: ListView.builder(
                  itemCount: _usersDailySteps.length,
                  itemBuilder: (context, index) {
                    final userSteps = _usersDailySteps[index];
                    return ListTile(
                      title: Text(userSteps.firstName),
                      subtitle: Text('${userSteps.steps} steps'),
                    );
                  }))
        ],
      ),
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
