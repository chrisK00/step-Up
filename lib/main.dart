import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: HealthSteps(),
        ),
      ),
    );
  }
}

class HealthSteps extends StatefulWidget {
  const HealthSteps({super.key});

  @override
  State<HealthSteps> createState() => _HealthStepsState();
}

class _HealthStepsState extends State<HealthSteps> {
  String _status = 'Initializing...';
  final health = Health();

  @override
  void initState() {
    super.initState();
    _initHealth();
  }

  Future<void> _initHealth() async {
    await health.configure();
    // Request activity recognition permission (Android)
    final b = await Permission.location.request();
    final a = await Permission.activityRecognition.request();
    final auth = await health.requestAuthorization([HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ]);

    final auth2 = await health.requestAuthorization([HealthDataType.STEPS]);

    final now = DateTime.now();
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime(now.year, now.month, now.day, 0, 0, 0),
        endTime: DateTime.now());

    // final c = await Health().isHealthDataHistoryAvailable();
    final f = await health.isHealthConnectAvailable();

    // final activityStatus = await Permission.activityRecognition.request();
    if (!auth || healthData.isNotEmpty) {
      setState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
    } else {
      setState(() => _status = 'Access granted ${Random().nextInt(999)}');
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFE306),
      child: Text(_status),
    );
  }
}
