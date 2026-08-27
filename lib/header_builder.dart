import 'package:firebase_auth/firebase_auth.dart';

class HeaderBuilder {
  final Map<String, String> _headers = {};

  static Future<String?> getToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    return await currentUser.getIdToken();
  }

  HeaderBuilder jsonContent() {
    _headers['Content-Type'] = 'application/json';
    return this;
  }

  Future<HeaderBuilder> auth() async {
    final token = await getToken();
    if (token != null) {
      _headers['Authorization'] = token;
    }
    return this;
  }

  Future<HeaderBuilder> authWithToken(String? token) async {
    token ??= await getToken();
    if (token != null) {
      _headers['Authorization'] = token;
    }
    return this;
  }

  Map<String, String> build() => _headers;
}
