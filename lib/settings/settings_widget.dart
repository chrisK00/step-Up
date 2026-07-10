import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsWidget extends StatefulWidget {
  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  var _secureStorageMsg = 'Loading Secure storage...';

  @override
  void initState() {
    super.initState();
    secureStorage();
  }

  Future<void> secureStorage() async {
    const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: false));
    final k = await storage.read(key: "key");
    final e = await storage.read(key: "error");

    if ((k == null || k == '') && (e == null || e == '')) {
      _secureStorageMsg = '';
    } else {
      setState(() {
        _secureStorageMsg = 'Key: $k\n Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        child: Column(children: [
          Text(_secureStorageMsg),
        ]));
  }
}
