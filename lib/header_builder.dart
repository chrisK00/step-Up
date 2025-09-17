import 'package:firebase_auth/firebase_auth.dart';

class HeaderBuilder {
  final Map<String, String> _headers = {};

  static Future<String> getToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final token = await currentUser!.getIdToken();
    return token!;
  }

  HeaderBuilder jsonContent() {
    _headers['Content-Type'] = 'application/json';
    return this;
  }

  Future<HeaderBuilder> auth() async {
    final token = await getToken();
    _headers['Authorization'] = token;
    return this;
  }

  Future<HeaderBuilder> authWithToken(String? token) async {
    token ??= await getToken();

    _headers['Authorization'] = token;
    return this;
  }

  Map<String, String> build() => _headers;
}
