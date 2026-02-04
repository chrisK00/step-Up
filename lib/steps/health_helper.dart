import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

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
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime(now.year, now.month, now.day, 0, 0, 0),
        endTime: DateTime.now());

    var nonSystemHealthData = healthData.where((d) => d.sourceName != "android");
    final totalSteps =
        nonSystemHealthData.fold<num>(0, (sum, point) => sum + (point.value as NumericHealthValue).numericValue);
    return totalSteps;
  }
}
