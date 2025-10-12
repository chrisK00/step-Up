import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:step_up/step_up_api_service.dart';
import 'package:step_up/steps/daily_steps.dart';
import 'package:step_up/steps/health_helper.dart';

class HealthStepsWidget extends StatefulWidget {
  const HealthStepsWidget({super.key});

  @override
  State<HealthStepsWidget> createState() => _HealthStepsWidgetState();
}

class _HealthStepsWidgetState extends State<HealthStepsWidget> {
  List<DailySteps> _usersDailySteps = [];
  String? firstPlaceId = null; // TODO maybe sort on backend, and just pick out yourself/own endpoint
  String? secondPlaceId = null;
  var _status = 'Loading...';

  Health _health = Health();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initSteps();
  }

  Future<void> _initSteps() async {
    // final authHealthResult = await HealthHelper.authenticateHealth(_health);
    // if (!authHealthResult) {
    //   safeSetState(() => _status = 'Permission Denied: ${Random().nextInt(999)}');
    //   return;
    // }

    final healthSteps = await HealthHelper.getStepsFromHealth(_health);
    final updateStepsResponse = await StepUpApiService.postSteps(healthSteps);

    if (updateStepsResponse == null || updateStepsResponse.statusCode != 201) {
      safeSetState(() => _status = 'Error sending steps to API: ${updateStepsResponse?.statusCode.toString()}');
    } else {
      safeSetState(() => _status = '');
    }

    var steps = await StepUpApiService.getSteps();
    steps ??= [];
    var friendsSteps = await StepUpApiService.getFriendsSteps();
    friendsSteps ??= [];

    final combinedList = [...steps, ...friendsSteps];
    combinedList.sort((a, b) => b.steps.compareTo(a.steps));
    firstPlaceId = combinedList.isNotEmpty ? combinedList[0].userId : null;
    secondPlaceId = combinedList.length > 1 ? combinedList[1].userId : null;

    safeSetState(() {
      _usersDailySteps = steps!;
      _usersDailySteps.addAll(friendsSteps!);
    });
  }

// TODO API request to fetch friends steps once i have sent my steps for today
// TODO create a background job to report the steps every X, and when opening this screen ofc (får såklart ha någon form av refresh time så man ej spammar steg)
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(_status),
          Expanded(
              child: ListView.builder(
                  itemCount: _usersDailySteps.length,
                  itemBuilder: (context, index) {
                    final userSteps = _usersDailySteps[index];

                    return ListTile(
                      title: Row(
                        children: [
                          Text(userSteps.firstName.split(" ")[0]),
                          const SizedBox(width: 5),
                          userSteps.userId == firstPlaceId
                              ? const Icon(Icons.emoji_events, color: Colors.amber)
                              : userSteps.userId == secondPlaceId
                                  ? const Icon(Icons.emoji_events, color: Colors.grey)
                                  : const SizedBox.shrink(),
                        ],
                      ), // TODO remove once have usernames in place
                      subtitle: Text('${userSteps.steps} steps'),
                    );
                  }))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (_isDisposed || !mounted) return;
    setState(fn);
  }
}
