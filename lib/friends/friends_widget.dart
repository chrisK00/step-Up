import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:step_up/friends/models.dart';
import 'package:step_up/step_up_api_service.dart';

class FriendsWidgetState extends StatefulWidget {
  const FriendsWidgetState({super.key});

  @override
  State<FriendsWidgetState> createState() => _FriendsWidgetState();
}

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

  void _copyUsernameToClipboard() {
    final username = FirebaseAuth.instance.currentUser?.displayName ?? '';
    if (username.isEmpty) {
      Fluttertoast.showToast(msg: 'No username found to copy');
      return;
    }
    Clipboard.setData(ClipboardData(text: username));
    Fluttertoast.showToast(msg: 'Username copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUsername = FirebaseAuth.instance.currentUser?.displayName ?? '';

    return RefreshIndicator(
      onRefresh: _reload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 48),
        child: Column(children: [
          if (currentUsername.isNotEmpty) ...[
            Card(
              child: ListTile(
                leading: const Icon(FontAwesomeIcons.user),
                title: Text(currentUsername),
                trailing: IconButton(
                  icon: const Icon(FontAwesomeIcons.copy),
                  tooltip: 'Copy username',
                  onPressed: _copyUsernameToClipboard,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Search username to add...',
                  ),
                ),
              ),
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
              FontAwesomeIcons.xmark,
              color: Colors.red,
            )));
  }

  ListTile createFriendTile(FriendsResponse fr, ThemeData theme) {
    return ListTile(
        title: Text(fr.username),
        trailing: IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove friend'),
                  content: Text('Remove ${fr.username} from your friends?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await deleteFriendship(fr);
            },
            icon: const Icon(
              FontAwesomeIcons.xmark,
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
    await _reload();
  }

  Future<void> acceptFriendRequest(String fromUserId) async {
    await StepUpApiService.acceptFriendRequest(fromUserId);
    await _reload();
  }
}
