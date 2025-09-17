import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthHelper {
  static Future<bool> authenticateHealth(Health health) async {
    await health.configure();
    // TODO handle declined
    final locationPermissionStatus = await Permission.location.request();
    final activityRecognitionPermissionStatus = await Permission.activityRecognition.request();

    // TODO This method may block if permissions are already granted. Hence, check [hasPermissions] before calling this method.
    final auth = await health.requestAuthorization([HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);
    return auth;
  }

  static Future<num> getStepsFromHealth(Health health) async {
    final now = DateTime.now();
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: DateTime(now.year, now.month, now.day, 0, 0, 0),
        endTime: DateTime.now());
    final totalSteps = healthData.fold<num>(0, (sum, point) => sum + (point.value as NumericHealthValue).numericValue);
    return totalSteps;
  }
}
