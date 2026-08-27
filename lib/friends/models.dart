class UsersSearchResponse {
  final String username;
  final String id;

  UsersSearchResponse({required this.username, required this.id});

  factory UsersSearchResponse.fromJson(Map<String, dynamic> json) {
    return UsersSearchResponse(
      username: (json['username'] ?? json['Username'] ?? json['firstName'] ?? '').toString(),
      id: (json['id'] ?? json['Id'] ?? json['userId'] ?? '').toString(),
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
    final rawDate = json['sentDateTime'] ?? json['SentDateTime'];
    DateTime parsedDate;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return FriendRequestsResponse(
      fromUserId: (json['fromUserId'] ?? json['FromUserId'] ?? '').toString(),
      toUserId: (json['toUserId'] ?? json['ToUserId'] ?? '').toString(),
      fromUsername: (json['fromUsername'] ?? json['FromUsername'] ?? '').toString(),
      toUsername: (json['toUsername'] ?? json['ToUsername'] ?? '').toString(),
      sentDateTime: parsedDate,
    );
  }
}

class FriendsResponse {
  final String id;
  final String username;

  FriendsResponse({required this.id, required this.username});

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      id: (json['userId'] ?? json['UserId'] ?? json['id'] ?? '').toString(),
      username: (json['firstName'] ?? json['FirstName'] ?? json['username'] ?? '').toString(),
    );
  }
}

class ReceivedReactionResponse {
  final String fromUsername;

  ReceivedReactionResponse({required this.fromUsername});

  factory ReceivedReactionResponse.fromJson(Map<String, dynamic> json) {
    return ReceivedReactionResponse(
      fromUsername: (json['fromUsername'] ?? json['FromUsername'] ?? '').toString(),
    );
  }
}
