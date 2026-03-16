import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class StepTrackerService {
  Stream<StepCount>? _stepCountStream;
  int _initialSteps = -1;

  /// Initializes the physical hardware sensor tracking.
  /// This bypasses Health Connect and Google Fit entirely by reading the sensor directly.
  Future<void> initStepTracking({
    required Function(int) onStepsUpdated,
    required Function(String) onError,
  }) async {
    try {
      // 1. Request the basic Activity Recognition permission from the OS.
      PermissionStatus status = await Permission.activityRecognition.request();

      if (status.isGranted) {
        // 2. Start listening to the hardware sensor stream.
        _stepCountStream = Pedometer.stepCountStream;
        
        _stepCountStream!.listen(
          (StepCount event) {
            // The hardware sensor returns total steps since the last phone reboot.
            // We record the 'initial' value when the user first taps START.
            if (_initialSteps == -1) {
              _initialSteps = event.steps;
            }
            
            // Calculate steps taken since the session started.
            int currentSessionSteps = event.steps - _initialSteps;
            onStepsUpdated(currentSessionSteps);
          },
          onError: (error) {
            onError("Hardware Sensor Error: $error");
          },
          cancelOnError: false,
        );
      } else if (status.isPermanentlyDenied) {
        onError("Permission permanently denied. Please enable 'Physical Activity' in App Settings.");
      } else {
        onError("Activity Recognition permission is required to track steps.");
      }
    } catch (e) {
      onError("Could not initialize pedometer: $e");
    }
  }

  /// Reset the counter for a new session.
  void reset() {
    _initialSteps = -1;
  }
}