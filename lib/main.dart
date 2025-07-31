import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:step_up/firebase_options.dart';
import 'package:step_up/health_steps_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
      title: "Step Up",
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
              appBar: AppBar(
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
              body: Center(child: userSnapshot.hasData ? const HealthStepsWidget() : SignInWidget()));
        },
      ),
    );
  }
}

class SignInWidget extends StatelessWidget {
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;

  SignInWidget({super.key});

  Future<UserCredential> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      // bearer token
      final idToken = await userCredential.user!.getIdToken(false);

      return userCredential;
    } catch (e) {
      debugPrint("ERROR: $e");
      _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      throw FirebaseException(plugin: "Google");
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
