import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:step_up/app_settings.dart';

class HealthHelper {
  static Future<bool> authenticateHealth(Health health) async {
    await health.configure();

    final healthDataInbackgroundPermissionStatus = await health.requestHealthDataInBackgroundAuthorization();
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
  }

  static Future<num> getStepsFromHealth(Health health) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);

    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: startOfDay,
      endTime: now,
    );

    // List<HealthDataPoint> uniqueData = health.removeDuplicates(healthData);

    final sourceName = await AppSettings.getHealthSourceName();

    var totalSteps = healthData.fold<num>(0, (sum, point) {
      final value = point.value;
      if (point.sourceName.contains(sourceName) && value is NumericHealthValue) {
        return sum + value.numericValue;
      }

      return sum;
    });

    return totalSteps;
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
