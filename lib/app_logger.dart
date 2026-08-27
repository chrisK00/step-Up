import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static const String _logFileName = 'step_up.txt';
  static const String _legacyLogFileName = 'step_up.log';
  static IOSink? _sink;

  static const int _maxFileSizeBytes = 1024 * 1024; // 1 MB
  static const int _keepLinesOnTrim = 1500;

  static Future<File> _logFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_logFileName');
  }

  static Future<void> _migrateLegacyLogFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final legacyFile = File('${dir.path}/$_legacyLogFileName');
      if (await legacyFile.exists()) {
        final targetFile = File('${dir.path}/$_logFileName');
        final legacyContent = await legacyFile.readAsString();
        if (legacyContent.isNotEmpty) {
          await targetFile.writeAsString(legacyContent, mode: FileMode.append);
        }
        await legacyFile.delete();
      }
    } catch (e) {
      debugPrint('AppLogger failed to migrate legacy log file: $e');
    }
  }

  static Future<void> _trimIfNeeded(File file) async {
    try {
      if (!await file.exists()) return;
      final size = await file.length();
      if (size <= _maxFileSizeBytes) return;

      final lines = await file.readAsLines();
      if (lines.length > _keepLinesOnTrim) {
        final trimmed = lines.sublist(lines.length - _keepLinesOnTrim);
        await file.writeAsString('${trimmed.join('\n')}\n');
      }
    } catch (e) {
      debugPrint('AppLogger failed to trim log file: $e');
    }
  }

  static Future<void> init() async {
    await _migrateLegacyLogFile();
    final file = await _logFile();
    await _trimIfNeeded(file);
    _sink = file.openWrite(mode: FileMode.append);
    log('--- app start ---');
  }

  static Future<void> log(String message) async {
    final line = '${DateTime.now().toIso8601String()} $message';
    debugPrint(line);
    _sink?.writeln(line);
    await _sink?.flush();
  }

  static Future<void> logError(Object error, [StackTrace? stackTrace]) async {
    await log('ERROR: $error');
    if (stackTrace != null) {
      await log(stackTrace.toString());
    }
  }

  static Future<File> getLogFile() async {
    final file = await _logFile();
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  static Future<void> clear() async {
    final file = await _logFile();
    if (await file.exists()) {
      await file.writeAsString('');
    }
  }

  static Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}
