import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:step_up/step_up_api_service.dart';
import 'package:step_up/steps/daily_steps.dart';

class HealthStepsWidget extends StatefulWidget {
  const HealthStepsWidget({super.key});

  @override
  State<HealthStepsWidget> createState() => _HealthStepsWidgetState();
}

class _HealthStepsWidgetState extends State<HealthStepsWidget> {
  List<DailySteps> _usersDailySteps = [DailySteps(firstName: "a", steps: 2500, userId: "x")]; // TODO
  var _status = 'Loading...';
  final _health = Health();

  @override
  void initState() {
    super.initState();
    _initSteps();
  }

  Future<void> _initSteps() async {
    await _health.configure();
    // TODO handle declined
    final locationPermissionStatus = await Permission.location.request();
    final activityRecognitionPermissionStatus = await Permission.activityRecognition.request();

    // TODO This method may block if permissions are already granted. Hence, check [hasPermissions] before calling this method.
    final auth = await _health.requestAuthorization([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);

    if (!auth) {
      setState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
      return;
    }

    // TODO move this upon launching the app (opening the app should cause a steps refresh)
    final now = DateTime.now();
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime(now.year, now.month, now.day, 0, 0, 0),
        endTime: DateTime.now());
    final totalSteps = healthData.fold<num>(0, (sum, point) => sum + (point.value as NumericHealthValue).numericValue);

    final updateStepsResponse = await StepUpApiService.postSteps(totalSteps);
    final steps = await StepUpApiService.fetchSteps();

    setState(() {
      _usersDailySteps = steps ?? [];
      _status =
          'Access granted (RND${Random().nextInt(999)})\nFound ${healthData.length} steps entries and ${totalSteps.toInt()} steps!';
    });
  }

// TODO API request to fetch friends steps once i have sent my steps for today
// TODO create a background job to report the steps every X, and when opening this screen ofc (får såklart ha någon form av refresh time så man ej spammar steg)
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: const Color.fromARGB(255, 255, 255, 255),
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
                      subtitle: Text(userSteps.steps.toString()),
                    );
                  }))
        ],
      ),
    );
  }
}
