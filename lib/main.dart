import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';
import 'package:step_up/firebase_options.dart';
import 'package:step_up/friends/friends_widget.dart';
import 'package:step_up/settings/settings_widget.dart';
import 'package:step_up/steps/health_helper.dart';
import 'package:step_up/step_up_api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:step_up/steps/health_steps_widget.dart';
import 'package:workmanager/workmanager.dart';

const jobName = "sendDailyStepsJob";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Job running");

    if (task != jobName) {
      return true;
    }

    const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: false));
    final start = DateTime.now();
    String text = start.toString();
    await storage.write(key: "key", value: text);

    final health = Health();

    try {
      final x = await health.isHealthDataInBackgroundAuthorized();
      text += '\n isHealthDataInBackgroundAuthorized: $x';

      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
      final currentUser = FirebaseAuth.instance.currentUser!;

      final idToken = await currentUser.getIdToken(true);
      text += '\n Got id token';
      await storage.write(key: "key", value: text);

      final y = await health.isHealthConnectAvailable();
      final yy = await health.hasPermissions([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);

      text += '\n Health available: $y  Has permission: $yy';
      await storage.write(key: "key", value: text);
      final healthSteps = await HealthHelper.getStepsFromHealth(health);

      text += '\n  Sending Steps: $healthSteps';
      await storage.write(key: "key", value: text);
      final updateStepsResponse = await StepUpApiService.postSteps(healthSteps, token: idToken);

      // await storage.write(
      //     key: "error", value: 'No Errors. Statuscode from API ${updateStepsResponse!.statusCode.toString()}');

      final end = DateTime.now();
      await storage.write(
          key: 'key',
          value: 'Job ran successfully. Started: $start ended $end. Ran for ${end.difference(start).inSeconds}');
    } catch (e) {
      await storage.write(key: 'key', value: text);
      await storage.write(key: "error", value: '$start: $e');
      debugPrint("Error during $jobName, $e");
    }
    return true;
  });
}

Future<void> registerPeriodicTasks() async {
  await Workmanager().registerPeriodicTask(jobName, jobName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
          requiresCharging: false,
          requiresBatteryNotLow: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
          networkType: NetworkType.notRoaming));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Workmanager().initialize(callbackDispatcher);

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final health = Health();
    HealthHelper.authenticateHealth(health);

// For testing
    // await Workmanager().registerOneOffTask("unique", jobName, initialDelay: Duration.zero);
    await registerPeriodicTasks();
  }

  runApp(const MainAppState());
}

class MainAppState extends StatefulWidget {
  const MainAppState({super.key});

  @override
  State<MainAppState> createState() => _MainAppState();
}

class _MainAppState extends State<MainAppState> {
  final primaryColor = const Color.fromARGB(255, 211, 248, 211);
  final backgroundColor = const Color.fromARGB(255, 242, 242, 242);
  final iconColor = const Color.fromARGB(255, 75, 88, 75);

  int currentPageIndex = 0;
  final List<Widget> pages = [
    const HealthStepsWidget(),
    const FriendsWidgetState(),
    SettingsWidget(),
  ];

  Future signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          foregroundColor: iconColor,
          // backgroundColor: Colors.white,
        )),
        secondaryHeaderColor: const Color.fromARGB(255, 242, 242, 242),
        scaffoldBackgroundColor: backgroundColor,
      ),
      title: "Step Up",
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            appBar: AppBar(
                backgroundColor: const Color.fromARGB(255, 242, 242, 242),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Step Up"),
                    if (userSnapshot.hasData)
                      ElevatedButton.icon(
                        label: const Text("Sign Out"),
                        icon: const Icon(FontAwesomeIcons.signOut),
                        onPressed: signOut,
                      )
                  ],
                )),
            body: Center(child: userSnapshot.hasData ? pages[currentPageIndex] : SignInWidget()),
            bottomNavigationBar: userSnapshot.hasData ? navBar() : null,
          );
        },
      ),
    );
  }

  NavigationBar navBar() {
    return NavigationBar(
      backgroundColor: primaryColor,
      indicatorColor: const Color.fromARGB(255, 177, 207, 177),
      onDestinationSelected: (int index) {
        if (!mounted) return;
        setState(() => currentPageIndex = index);
      },
      selectedIndex: currentPageIndex,
      destinations: const [
        NavigationDestination(
          icon: Icon(FontAwesomeIcons.house),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(FontAwesomeIcons.userGroup),
          label: 'Friends',
        ),
        NavigationDestination(
          icon: Icon(FontAwesomeIcons.gear),
          label: 'Settings',
        ),
      ],
    );
  }
}

class SignInWidget extends StatelessWidget {
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;

  SignInWidget({super.key});

  Future<void> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final gauthtoken = googleAuth.idToken;
      await _firebaseAuth.signInWithCredential(credential);

      // TODO add username select screen and handle username is taken / error messages
      final currentUser = FirebaseAuth.instance.currentUser;
      final signUpResult = await StepUpApiService.signUp(currentUser!.displayName!);

      if (signUpResult == null || signUpResult.statusCode != 201) {
        Fluttertoast.showToast(msg: "${signUpResult?.reasonPhrase}");
        _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        return;
      }

      final health = Health();
      await HealthHelper.authenticateHealth(health);
      await registerPeriodicTasks();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint("ERROR: $e");
      _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
            label: const Text("Sign in"), icon: const Icon(FontAwesomeIcons.google), onPressed: signInWithGoogle)
      ],
    );
  }
}
