import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:step_up/firebase_options.dart';
import 'package:step_up/friends/friends_widget.dart';
import 'package:step_up/steps/health_steps_widget.dart';
import 'package:step_up/step_up_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  ];

  Future signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
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
      await _firebaseAuth.signInWithCredential(credential);

      // TODO add username select screen and handle username is taken / error messages
      final currentUser = FirebaseAuth.instance.currentUser;
      await StepUpApiService.signUp(currentUser!.displayName!);
    } catch (e) {
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
