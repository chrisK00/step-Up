import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:step_up/friends/models.dart';
import 'package:step_up/header_builder.dart';
import 'package:step_up/steps/daily_steps.dart';

class StepUpApiService {
  static const String _apiUrl = 'http://10.0.2.2:5208';
  static const String _usersEndpoint = '${_apiUrl}users';
  static const String _friendRequestsEndpoint = '${_apiUrl}friend-requests';
  static const String _friendshipsEndpoint = '${_apiUrl}friends';
  static const String _stepsEndpoint = '${_apiUrl}steps';

  static Future<http.Response?> postSteps(
    num totalSteps,
  ) async {
    try {
      var response = await http.post(Uri.parse(_stepsEndpoint),
          headers: (await HeaderBuilder().jsonContent().auth()).build(),
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
      await http.post(Uri.parse(_usersEndpoint),
          headers: (await HeaderBuilder().jsonContent().auth()).build(),
          body: jsonEncode(<String, String>{
            'FirstName': displayName,
          }));
    } catch (e) {
      debugPrint('HTTP Error: $e');
    }
  }

  static Future<List<DailySteps>?> fetchSteps() async {
    try {
      final response = await http.get(Uri.parse(_stepsEndpoint), headers: (await HeaderBuilder().auth()).build());
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => DailySteps.fromJson(e)).toList();
    } catch (e) {
      debugPrint('HTTP Error: $e');
      return null;
    }
  }

  static Future<List<UsersSearchResponse>?> searchUsers(String username) async {
    final url = "$_usersEndpoint?username=$username";
    try {
      final response = await http.get(Uri.parse(url), headers: (await HeaderBuilder().auth()).build());
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => UsersSearchResponse.fromJson(e)).toList();
    } catch (e) {
      debugPrint('HTTP Error: $e');
      return null;
    }
  }

  static Future sendFriendRequest(String toUserId) async {
    try {
      await http.post(Uri.parse(_friendRequestsEndpoint),
          headers: (await HeaderBuilder().jsonContent().auth()).build(), body: jsonEncode({"toUserId": toUserId}));
    } catch (e) {
      debugPrint('HTTP Error: $e');
    }
  }

  static Future acceptFriendRequest(String fromUserId) async {
    final url = Uri.parse('$_friendRequestsEndpoint/accept');
    try {
      await http.post(url,
          headers: (await HeaderBuilder().jsonContent().auth()).build(), body: jsonEncode({"fromUserId": fromUserId}));
    } catch (e) {
      debugPrint('HTTP Error: $e');
    }
  }

  static Future deleteFriendRequest() async {
    final url = Uri.parse(_friendRequestsEndpoint);
    final headers = (await HeaderBuilder().auth()).build();
    // delete
  }

  static Future<List<FriendRequestsResponse>?> getFriendRequests() async {
    final url = Uri.parse(_friendRequestsEndpoint);

    try {
      final response = await http.get(url, headers: (await HeaderBuilder().auth()).build());
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => FriendRequestsResponse.fromJson(e)).toList();
    } catch (e) {
      debugPrint('HTTP Error: $e');
      return null;
    }
  }

  static Future<List<FriendsResponse>?> getFriends() async {
    final url = Uri.parse(_friendshipsEndpoint);

    try {
      final response = await http.get(url, headers: (await HeaderBuilder().auth()).build());
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => FriendsResponse.fromJson(e)).toList();
    } catch (e) {
      debugPrint('HTTP Error: $e');
      return null;
    }
  }

  static Future deleteFriendship() async {
    final url = Uri.parse(_friendshipsEndpoint);
    final headers = (await HeaderBuilder().auth()).build();
//delete
  }
}
