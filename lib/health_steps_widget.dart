import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthStepsWidget extends StatefulWidget {
  const HealthStepsWidget({super.key});

  @override
  State<HealthStepsWidget> createState() => _HealthStepsWidgetState();
}

class _HealthStepsWidgetState extends State<HealthStepsWidget> {
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

    final now = DateTime.now();
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime(now.year, now.month, now.day, 0, 0, 0),
        endTime: DateTime.now());

    if (!auth) {
      setState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
    } else {
      setState(
          () => _status = 'Access granted (RND${Random().nextInt(999)})\n Found ${healthData.length} steps entries');
    }

// TODO api request send my steps for today
    return;
  }

// TODO API request to fetch friends steps once i have sent my steps for today
// TODO create a background job to report the steps every X, and when opening this screen ofc
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Column(
        children: [
          Text(_status),
        ],
      ),
    );
  }
}
