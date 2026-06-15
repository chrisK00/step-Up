import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:step_up/friends/models.dart';
import 'package:step_up/step_up_api_service.dart';

class FriendsWidgetState extends StatefulWidget {
  const FriendsWidgetState({super.key});

  @override
  State<FriendsWidgetState> createState() => _FriendsWidgetState();
}

// TODO en knapp med copy your username to clipboard
class _FriendsWidgetState extends State<FriendsWidgetState> {
  final _usernameController = TextEditingController();
  List<FriendRequestsResponse> friendRequests = [];
  List<FriendsResponse> friends = [];
  List<FriendRequestsResponse> sentFriendRequests = [];

  @override
  void initState() {
    super.initState();
    initFriendRequests();
    initSentFriendRequests();
    initFriends();
  }

  Future<void> _reload() => Future.wait([
        initFriendRequests(),
        initSentFriendRequests(),
        initFriends(),
      ]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _reload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            children: [
              Expanded(child: TextField(controller: _usernameController)),
              IconButton(onPressed: sendFriendRequest, icon: const Icon(FontAwesomeIcons.plus))
            ],
          ),
          const SizedBox(height: 20),
          ExpansionPanelList(
            children: [
              ExpansionPanel(
                isExpanded: true,
                headerBuilder: (context, isOpen) => ListTile(title: Text("Friend Requests (${friendRequests.length})")),
                body: Column(children: friendRequests.map((fr) => createFriendRequestTile(fr, theme)).toList()),
              ),
              ExpansionPanel(
                isExpanded: true,
                headerBuilder: (context, isOpen) => ListTile(title: Text("Friends (${friends.length})")),
                body: Column(
                  children: friends.map((fr) => createFriendTile(fr, theme)).toList(),
                ),
              ),
              ExpansionPanel(
                isExpanded: true,
                headerBuilder: (context, isOpen) =>
                    ListTile(title: Text("Sent Friend Requests (${sentFriendRequests.length})")),
                body: Column(children: sentFriendRequests.map((fr) => createSentFriendRequestTile(fr, theme)).toList()),
              ),
            ],
          )
        ]),
      ),
    );
  }

  ListTile createFriendRequestTile(FriendRequestsResponse fr, ThemeData theme) {
    return ListTile(
        title: Text(fr.fromUsername),
        trailing: IconButton(
            onPressed: () => acceptFriendRequest(fr.fromUserId),
            icon: Icon(
              FontAwesomeIcons.check,
              color: theme.primaryColorLight,
            )));
  }

  ListTile createSentFriendRequestTile(FriendRequestsResponse fr, ThemeData theme) {
    return ListTile(
        title: Text(fr.toUsername),
        trailing: IconButton(
            onPressed: () async => await deleteFriendRequest(fr.toUserId),
            icon: const Icon(
              FontAwesomeIcons.remove,
              color: Colors.red,
            )));
  }

// TODO borde använda template för alal är typ samma förutom icon mm
  ListTile createFriendTile(FriendsResponse fr, ThemeData theme) {
    return ListTile(
        title: Text(fr.username),
        trailing: IconButton(
            onPressed: () async => await deleteFriendship(fr),
            icon: const Icon(
              FontAwesomeIcons.remove,
              color: Colors.red,
            )));
  }

  Future<void> initFriendRequests() async {
    final fr = await StepUpApiService.getFriendRequests(FriendRequestType.incoming);

    setState(() => friendRequests = fr ?? []);
  }

  Future<void> deleteFriendship(FriendsResponse friendResponse) async {
    await StepUpApiService.deleteFriendship(friendResponse.id);

    setState(() => friends.remove(friendResponse));
  }

  Future<void> deleteFriendRequest(String userId) async {
    await StepUpApiService.deleteFriendship(userId);

    setState(() => friends.removeWhere((fr) => fr.id == userId));
  }

  Future<void> initSentFriendRequests() async {
    final sfr = await StepUpApiService.getFriendRequests(FriendRequestType.outgoing);

    setState(() => sentFriendRequests = sfr ?? []);
  }

  Future<void> initFriends() async {
    final frs = await StepUpApiService.getFriends();

    setState(() => friends = frs ?? []);
  }

  Future<void> sendFriendRequest() async {
    final foundUsers = await StepUpApiService.searchUsers(_usernameController.text);
    if (foundUsers == null || foundUsers.isEmpty) {
      Fluttertoast.showToast(msg: 'The user was not found');
      return;
    }

    await StepUpApiService.sendFriendRequest(foundUsers.first.id);
    _usernameController.text = "";
  }

  Future<void> acceptFriendRequest(String fromUserId) async {
    await StepUpApiService.acceptFriendRequest(fromUserId);
    await _reload();
  }
}
