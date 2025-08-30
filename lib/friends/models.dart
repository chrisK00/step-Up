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
  final String toUserId;
  final DateTime sentDateTime;

  FriendRequestsResponse({required this.fromUserId, required this.toUserId, required this.sentDateTime});

  factory FriendRequestsResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestsResponse(
      fromUserId: json['fromUserId'],
      toUserId: json["id"],
      sentDateTime: json["sentDateTime"],
    );
  }
}

class FriendsResponse {
  final String id;
  final String username;

  FriendsResponse({required this.id, required this.username});

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      id: json['fromUserId'],
      username: json["firstName"],
    );
  }
}
