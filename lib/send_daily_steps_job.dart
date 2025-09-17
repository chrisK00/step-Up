import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:step_up/main.dart';
import 'package:step_up/step_up_api_service.dart';
import 'package:workmanager/workmanager.dart';

import 'steps/health_helper.dart';

class SendDailyStepsJob {
  static const jobName = "sendDailyStepsJob";

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      debugPrint("Job running");
      if (task != SendDailyStepsJob.jobName) {
        return true;
      }

      final health = MainAppState.mainHealth;
      try {
        final idToken = inputData?['idToken']?.toString();
        final healthSteps = await HealthHelper.getStepsFromHealth(health);
        final updateStepsResponse = await StepUpApiService.postSteps(healthSteps, token: idToken);
      } catch (e) {
        debugPrint("Error during $SendDailyStepsJob.jobName, $e");
        Fluttertoast.showToast(msg: 'Could not execute job. $e');
      }
      return true;
    });
  }
}
