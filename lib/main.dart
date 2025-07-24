import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:step_up/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SignInWidget(),
        ),
      ),
    );
  }
}

class SignInWidget extends StatelessWidget {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ElevatedButton.icon(
            label: const Text("Sign in"), icon: const Icon(FontAwesomeIcons.google), onPressed: signInWithGoogle)
      ],
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      debugPrint("Signed in successfully: ${userCredential.user?.displayName}");
      return userCredential;
    } catch (e) {
      debugPrint("ERROR: $e");
      auth.signOut();
      await googleSignIn.signOut();
      throw FirebaseException(plugin: "Google");
    }
  }
}

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

    // final f = await health.isHealthConnectAvailable();

    if (!auth) {
      setState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
    } else {
      setState(
          () => _status = 'Access granted (RND${Random().nextInt(999)})\n. Found ${healthData.length} steps entries');
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
