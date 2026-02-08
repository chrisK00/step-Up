import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:step_up/friends/models.dart';
import 'package:step_up/header_builder.dart';
import 'package:step_up/steps/daily_steps.dart';

extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;

    return split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

extension EnumToStringExtension on Enum {
  String get asString => toString().split('.').last;
}

enum FriendRequestType { incoming, outgoing }

class StepUpApiService {
  // static const String _apiUrl = 'http://10.0.2.2:5208';
  static const String _apiUrl = 'https://step-up.racknerd.chrispys.top';
  static const String _usersEndpoint = '$_apiUrl/users';
  static const String _friendRequestsEndpoint = '$_apiUrl/friend-requests';
  static const String _friendshipsEndpoint = '$_apiUrl/friends';
  static const String _stepsEndpoint = '$_apiUrl/steps';

  static Future<http.Response?> postSteps(
    num totalSteps, {
    String? token,
  }) async {
    try {
      var response = await http.post(Uri.parse(_stepsEndpoint),
          headers: (await HeaderBuilder().jsonContent().authWithToken(token)).build(),
          body: jsonEncode(<String, num>{'steps': totalSteps}));

      return response;
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
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
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
    }
  }

  static Future<List<DailySteps>?> getSteps() async {
    try {
      final response = await http.get(Uri.parse(_stepsEndpoint), headers: (await HeaderBuilder().auth()).build());
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => DailySteps.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
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
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      return null;
    }
  }

  static Future sendFriendRequest(String toUserId) async {
    try {
      final body = jsonEncode({"toUserId": toUserId});
      await http.post(Uri.parse(_friendRequestsEndpoint),
          headers: (await HeaderBuilder().jsonContent().auth()).build(), body: body);
      Fluttertoast.showToast(msg: 'Sent friend request');
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
    }
  }

  static Future acceptFriendRequest(String fromUserId) async {
    final url = Uri.parse('$_friendRequestsEndpoint/accept');
    try {
      await http.post(url,
          headers: (await HeaderBuilder().jsonContent().auth()).build(), body: jsonEncode({"fromUserId": fromUserId}));
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
    }
  }

  static Future deleteFriendRequest() async {
    final url = Uri.parse(_friendRequestsEndpoint);
    final headers = (await HeaderBuilder().auth()).build();
    // delete
  }

  static Future<List<FriendRequestsResponse>?> getFriendRequests(FriendRequestType frType) async {
    final url = Uri.parse("$_friendRequestsEndpoint?friendRequestType=${frType.asString.toTitleCase()}");

    try {
      final response = await http.get(url, headers: (await HeaderBuilder().auth()).build());
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => FriendRequestsResponse.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
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
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      return null;
    }
  }

  static Future deleteFriendship(String userId) async {
    final url = Uri.parse("$_friendshipsEndpoint/$userId");
    final headers = (await HeaderBuilder().auth()).build();

    try {
      final response = await http.delete(url, headers: headers);
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
    }
  }

  static Future<List<DailySteps>?> getFriendsSteps() async {
    try {
      final response =
          await http.get(Uri.parse("$_stepsEndpoint/friends"), headers: (await HeaderBuilder().auth()).build());
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => DailySteps.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      return null;
    }
  }
}
