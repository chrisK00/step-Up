import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
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

    if (!auth) {
      setState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
      return;
    }

    final now = DateTime.now();
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime(now.year, now.month, now.day, 0, 0, 0),
        endTime: DateTime.now());
    final totalSteps = healthData.fold<num>(0, (sum, point) => sum + (point.value as NumericHealthValue).numericValue);

    // TODO
    const apiUrl = "http://10.0.2.2:5208";

    final currentUser = FirebaseAuth.instance.currentUser;
    final token = await currentUser!.getIdToken();
    try {
      await http.post(Uri.parse('$apiUrl/users'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': token.toString()
          },
          body: jsonEncode(<String, String>{
            "FirstName": currentUser.displayName.toString(),
          }));
    } catch (e) {
      final m = e.toString();
    }

    final updateStepsResponse = await http.post(Uri.parse('$apiUrl/steps'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8', 'Authorization': token.toString()},
        body: jsonEncode(<String, num>{'steps': totalSteps}));

    final fetchStepsResponse = await http.get(Uri.parse('$apiUrl/steps'), headers: {'Authorization': token.toString()});
    final steps = (jsonDecode(fetchStepsResponse.body) as List).map((e) => e as Map<String, dynamic>).toList();
    setState(() => _status =
        'Access granted (RND${Random().nextInt(999)})\nFound ${healthData.length} steps entries and ${totalSteps.toInt()} steps!');

// TODO api request send my steps for today
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
        ],
      ),
    );
  }
}
