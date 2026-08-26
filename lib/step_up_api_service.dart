import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:step_up/app_logger.dart';
import 'package:step_up/app_settings.dart';
import 'package:step_up/friends/models.dart';
import 'package:step_up/header_builder.dart';
import 'package:step_up/race/race_player.dart';
import 'package:step_up/steps/daily_steps.dart';
import 'package:step_up/steps/step_history_entry.dart';

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
  static Future<Uri> _uri(String path) async {
    final base = await AppSettings.getApiUrl();
    return Uri.parse('$base$path');
  }

  static Future<http.Response?> postSteps(
    num totalSteps, {
    String? token,
  }) async {
    try {
      final response = await http.post(
        await _uri('/steps'),
        headers: (await HeaderBuilder().jsonContent().authWithToken(token)).build(),
        body: jsonEncode(<String, num>{'steps': totalSteps}),
      );
      return response;
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future<http.Response?> signUp(String displayName) async {
    try {
      return await http.post(
        await _uri('/users'),
        headers: (await HeaderBuilder().jsonContent().auth()).build(),
        body: jsonEncode(<String, String>{'FirstName': displayName}),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future<List<DailySteps>?> getSteps() async {
    try {
      final response = await http.get(await _uri('/steps'), headers: (await HeaderBuilder().auth()).build());
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.trim().isEmpty) return [];
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => DailySteps.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future<List<StepHistoryEntry>?> getStepHistory() async {
    try {
      final response = await http.get(await _uri('/steps/history'), headers: (await HeaderBuilder().auth()).build());
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.trim().isEmpty) {
        return [];
      }
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => StepHistoryEntry.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future<List<RacePlayer>> getRaceLeaderboard({DateTime? date}) async {
    try {
      final headers = (await HeaderBuilder().auth()).build();
      final dateQuery = date == null ? '' : '?date=${date.toIso8601String().substring(0, 10)}';

      final results = await Future.wait([
        http.get(await _uri('/steps$dateQuery'), headers: headers),
        http.get(await _uri('/steps/friends$dateQuery'), headers: headers),
      ]);

      List<dynamic> _decodeList(http.Response r) =>
          (r.statusCode >= 200 && r.statusCode < 300 && r.body.trim().isNotEmpty)
              ? jsonDecode(r.body) as List<dynamic>
              : [];

      final ownJson = _decodeList(results[0]);
      final friendsJson = _decodeList(results[1]);

      final all = [
        ...ownJson.map((e) => RacePlayer.fromJson(e)),
        ...friendsJson.map((e) => RacePlayer.fromJson(e)),
      ];

      all.sort((a, b) => b.steps.compareTo(a.steps));
      return all;
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return [];
    }
  }

  static Future<List<UsersSearchResponse>?> searchUsers(String username) async {
    try {
      final response = await http.get(
        await _uri('/users?username=$username'),
        headers: (await HeaderBuilder().auth()).build(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.trim().isEmpty) return [];
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => UsersSearchResponse.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future sendFriendRequest(String toUserId) async {
    try {
      final body = jsonEncode({"toUserId": toUserId});
      await http.post(
        await _uri('/friend-requests'),
        headers: (await HeaderBuilder().jsonContent().auth()).build(),
        body: body,
      );
      Fluttertoast.showToast(msg: 'Sent friend request');
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
    }
  }

  static Future acceptFriendRequest(String fromUserId) async {
    try {
      await http.post(
        await _uri('/friend-requests/accept'),
        headers: (await HeaderBuilder().jsonContent().auth()).build(),
        body: jsonEncode({"fromUserId": fromUserId}),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
    }
  }

  static Future deleteFriendRequest(String userId) async {
    final headers = (await HeaderBuilder().auth()).build();
    try {
      await http.delete(await _uri('/friend-requests/$userId'), headers: headers);
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
    }
  }

  static Future<List<FriendRequestsResponse>?> getFriendRequests(FriendRequestType frType) async {
    final url = await _uri('/friend-requests?friendRequestType=${frType.asString.toTitleCase()}');

    try {
      final response = await http.get(url, headers: (await HeaderBuilder().auth()).build());
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.trim().isEmpty) return [];
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => FriendRequestsResponse.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future<List<FriendsResponse>?> getFriends() async {
    try {
      final response = await http.get(await _uri('/friends'), headers: (await HeaderBuilder().auth()).build());
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.trim().isEmpty) return [];
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => FriendsResponse.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future<http.Response?> sendThumbsUpToFriend(String friendId) async {
    try {
      return await http.post(
        await _uri('/friends/reactions/thumbs-up'),
        headers: (await HeaderBuilder().jsonContent().auth()).build(),
        body: jsonEncode(<String, String>{'friendId': friendId}),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }

  static Future<List<ReceivedReactionResponse>> getReceivedReactions() async {
    try {
      final response = await http.get(
        await _uri('/friends/reactions/received'),
        headers: (await HeaderBuilder().auth()).build(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.trim().isEmpty) {
        return [];
      }
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => ReceivedReactionResponse.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return [];
    }
  }

  static Future deleteFriendship(String userId) async {
    final headers = (await HeaderBuilder().auth()).build();
    try {
      final response = await http.delete(await _uri('/friends/$userId'), headers: headers);
      Fluttertoast.showToast(msg: "removed: ${response.statusCode}");
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
    }
  }

  static Future<List<DailySteps>?> getFriendsSteps() async {
    try {
      final response = await http.get(await _uri('/steps/friends'), headers: (await HeaderBuilder().auth()).build());
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.trim().isEmpty) return [];
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => DailySteps.fromJson(e)).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: "ERROR: $e");
      debugPrint('HTTP Error: $e');
      await AppLogger.logError(e);
      return null;
    }
  }
}
