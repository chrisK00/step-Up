import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:step_up/app_logger.dart';
import 'package:step_up/app_settings.dart';
import 'package:step_up/step_up_api_service.dart';

class HealthHelper {
  static Future<bool> authenticateHealth(Health health) async {
    try {
      await health.configure();

      final healthDataInbackgroundPermissionStatus =
          await health.requestHealthDataInBackgroundAuthorization();
      final locationPermissionStatus = await Permission.location.request();
      final activityRecognitionPermissionStatus = await Permission.activityRecognition.request();

      final isHealthAvailable = await health.isHealthConnectAvailable();
      final isHealthDataInBackgroundAvailable = await health.isHealthDataInBackgroundAuthorized();
      final hasStepsPermission =
          await health.hasPermissions([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);

      if (healthDataInbackgroundPermissionStatus &&
          locationPermissionStatus.isGranted &&
          activityRecognitionPermissionStatus.isGranted &&
          isHealthAvailable &&
          isHealthDataInBackgroundAvailable &&
          (hasStepsPermission != null && hasStepsPermission)) {
        return true;
      }

      final auth = await health.requestAuthorization([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);
      return auth;
    } catch (e, st) {
      debugPrint('authenticateHealth error: $e');
      await AppLogger.logError(e, st);
      return false;
    }
  }

  static Future<num> getStepsFromHealth(Health health) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      final sourceName = await AppSettings.getHealthSourceName();

      var totalSteps = healthData.fold<num>(0, (sum, point) {
        final value = point.value;
        final pointSourceName = point.sourceName;
        final matchesSource = sourceName.trim().isEmpty ||
            pointSourceName.toLowerCase().contains(sourceName.trim().toLowerCase());

        if (matchesSource && value is NumericHealthValue) {
          return sum + value.numericValue;
        }

        return sum;
      });

      return totalSteps;
    } catch (e, st) {
      debugPrint('getStepsFromHealth error: $e');
      await AppLogger.logError(e, st);
      return 0;
    }
  }

  /// Reads steps for each day from the 1st of the current month up to (but not
  /// including) today, then POSTs all days in a single bulk request. Today's
  /// steps are excluded because the regular background/foreground sync handles today.
  static Future<void> syncMonthHistory(Health health, {String? token}) async {
    try {
      final now = DateTime.now();
      final sourceName = await AppSettings.getHealthSourceName();

      final entries = <Map<String, dynamic>>[];

      for (int day = 1; day < now.day; day++) {
        final date = DateTime(now.year, now.month, day);
        final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final healthData = await health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startOfDay,
          endTime: endOfDay,
        );

        final steps = healthData.fold<num>(0, (sum, point) {
          final value = point.value;
          final pointSourceName = point.sourceName;
          final matchesSource = sourceName.trim().isEmpty ||
              pointSourceName.toLowerCase().contains(sourceName.trim().toLowerCase());

          if (matchesSource && value is NumericHealthValue) {
            return sum + value.numericValue;
          }
          return sum;
        });

        // Skip days with zero steps to avoid cluttering the DB with empty rows.
        if (steps <= 0) continue;

        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        entries.add({'steps': steps.toInt(), 'date': dateStr});
      }

      if (entries.isEmpty) return;

      await StepUpApiService.postStepsBulk(entries, token: token);
    } catch (e, st) {
      debugPrint('syncMonthHistory error: $e');
      await AppLogger.logError(e, st);
    }
  }
}

  //   final totalSteps = await health.getTotalStepsInInterval(startOfDay, now, includeManualEntry: true);
  //   if (totalSteps != null) {
  //     return totalSteps;
  //   }

  //   List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
  //     types: [HealthDataType.STEPS],
  //     startTime: startOfDay,
  //     endTime: now,
  //   );

  //   final nonSystemHealthData = healthData.where((d) => d.sourceName != "android");
  //   return nonSystemHealthData.fold<num>(0, (sum, point) {
  //     final value = point.value;
  //     if (value is NumericHealthValue) {
  //       return sum + value.numericValue;
  //     }
  //     return sum;
  //   });
  // }
