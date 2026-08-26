import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:step_up/app_logger.dart';
import 'package:step_up/app_settings.dart';

class SettingsWidget extends StatefulWidget {
  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final _apiUrlController = TextEditingController();
  final _healthSourceController = TextEditingController();
  String _status = 'Loading settings...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apiUrl = await AppSettings.getApiUrl();
    final healthSource = await AppSettings.getHealthSourceName();
    if (!mounted) return;
    _apiUrlController.text = apiUrl;
    _healthSourceController.text = healthSource;
    setState(() => _status = 'Settings loaded');
  }

  Future<void> _save() async {
    await AppSettings.setApiUrl(_apiUrlController.text);
    await AppSettings.setHealthSourceName(_healthSourceController.text);
    if (!mounted) return;
    setState(() => _status = 'Saved');
  }

  Future<void> _reset() async {
    await AppSettings.resetOverrides();
    await _load();
    if (!mounted) return;
    setState(() => _status = 'Reset to defaults');
  }

  Future<void> _shareLogs() async {
    final file = await AppLogger.getLogFile();
    SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'Step Up log file',
    ));
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _healthSourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_status),
          const SizedBox(height: 16),
          TextField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              labelText: 'API URL',
              hintText: 'https://stepup.racknerd.chrispys.top',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _healthSourceController,
            decoration: const InputDecoration(
              labelText: 'Health source name',
              hintText: 'com.google.android.apps.fitness',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _shareLogs,
            child: const Text('Share log file'),
          ),
        ],
      ),
    );
  }
}
