import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FriendsWidgetState extends StatefulWidget {
  const FriendsWidgetState({super.key});

  @override
  State<FriendsWidgetState> createState() => _FriendsWidgetState();
}

// TODO en knapp med copy your username to clipboard
class _FriendsWidgetState extends State<FriendsWidgetState> {
  final _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: const EdgeInsetsGeometry.all(16),
      child: Column(children: [
        Row(
          children: [
            Expanded(child: TextField(controller: _usernameController)),
            IconButton(onPressed: () => {}, icon: Icon(FontAwesomeIcons.plus))
          ],
        ),
        const SizedBox(height: 20),
        ExpansionPanelList(
          children: [
            ExpansionPanel(
              isExpanded: true,
              headerBuilder: (context, isOpen) => const ListTile(title: Text("Friend Requests (2)")),
              body: const Column(
                children: [ListTile(title: Text("Req1")), ListTile(title: Text("Req2"))],
              ),
            ),
            ExpansionPanel(
              isExpanded: true,
              headerBuilder: (context, isOpen) => const ListTile(title: Text("Friends (1)")),
              body: const Column(
                children: [ListTile(title: Text("Friend1"))],
              ),
            ),
            ExpansionPanel(
              isExpanded: false,
              headerBuilder: (context, isOpen) => const ListTile(title: Text("Sent Friend Requests (0)")),
              body: const Column(
                children: [],
              ),
            )
          ],
        )
      ]),
    );
  }
}
