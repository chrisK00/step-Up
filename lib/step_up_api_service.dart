import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StepUpApiService {
  static const String _apiUrl = 'http://10.0.2.2:5208';

  static Future<String> getToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final token = await currentUser!.getIdToken();
    return token!;
  }

  static Future<http.Response?> postSteps(
    num totalSteps,
  ) async {
    try {
      var response = await http.post(Uri.parse('$_apiUrl/steps'),
          headers: <String, String>{'Content-Type': 'application/json', 'Authorization': await getToken()},
          body: jsonEncode(<String, num>{'steps': totalSteps}));

      return response;
    } catch (e) {
      debugPrint('HTTP Error: $e');
      return null;
    }
  }

  static Future<void> signUp(
    String displayName,
  ) async {
    try {
      await http.post(Uri.parse('$_apiUrl/users'),
          headers: <String, String>{'Content-Type': 'application/json', 'Authorization': await getToken()},
          body: jsonEncode(<String, String>{
            'FirstName': displayName,
          }));
    } catch (e) {
      debugPrint('HTTP Error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchSteps() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/steps'), headers: {'Authorization': await getToken()});
      final steps = (jsonDecode(response.body) as List).map((e) => e as Map<String, dynamic>).toList();
      return steps;
    } catch (e) {
      debugPrint('HTTP Error: $e');
      return null;
    }
  }
}
