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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text("step up"),
      ),
      body: Center(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasData) {
              return const HealthStepsWidget();
            }

            return SignInWidget();
          },
        ),
      ),
    ));
  }
}

class SignInWidget extends StatelessWidget {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn.instance;

  @override
  Widget build(BuildContext context) {
    return Column(
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
      // bearer token
      final idToken = await userCredential.user!.getIdToken(false);

      return userCredential;
    } catch (e) {
      debugPrint("ERROR: $e");
      auth.signOut();
      await googleSignIn.signOut();
      throw FirebaseException(plugin: "Google");
    }
  }
}
