class UsersSearchResponse {
  final String username;
  final String id;

  UsersSearchResponse({required this.username, required this.id});

  factory UsersSearchResponse.fromJson(Map<String, dynamic> json) {
    return UsersSearchResponse(
      username: json['username'],
      id: json["id"],
    );
  }
}

class FriendRequestsResponse {
  final String fromUserId;
  final String fromUsername;
  final String toUsername;
  final String toUserId;
  final DateTime sentDateTime;

  FriendRequestsResponse(
      {required this.fromUserId,
      required this.toUserId,
      required this.fromUsername,
      required this.toUsername,
      required this.sentDateTime});

  factory FriendRequestsResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestsResponse(
      fromUserId: json['fromUserId'],
      toUserId: json["toUserId"],
      fromUsername: json["fromUsername"],
      toUsername: json["toUsername"],
      sentDateTime: DateTime.parse(json["sentDateTime"]),
    );
  }
}

class FriendsResponse {
  final String id;
  final String username;

  FriendsResponse({required this.id, required this.username});

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      id: json['userId'],
      username: json["firstName"],
    );
  }
}

class ReceivedReactionResponse {
  final String fromUsername;

  ReceivedReactionResponse({required this.fromUsername});

  factory ReceivedReactionResponse.fromJson(Map<String, dynamic> json) {
    return ReceivedReactionResponse(
      fromUsername: (json['fromUsername'] ?? json['FromUsername'] ?? '') as String,
    );
  }
}
