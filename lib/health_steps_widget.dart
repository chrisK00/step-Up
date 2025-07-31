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
    final auth = await health.requestAuthorization([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);

    final now = DateTime.now();
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime(now.year, now.month, now.day, 0, 0, 0),
        endTime: DateTime.now());

    if (!auth) {
      setState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
    } else {
      setState(
          () => _status = 'Access granted (RND${Random().nextInt(999)})\n. Found ${healthData.length} steps entries');
    }

// TODO api request send my steps for today
    return;
  }

  Future signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

// TODO API request to fetch friends steps
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Column(
        children: [
          Text(_status),

          // TODO move this
          ElevatedButton.icon(
              label: const Text("Sign Out"), icon: const Icon(FontAwesomeIcons.signOut), onPressed: signOut)
        ],
      ),
    );
  }
}
