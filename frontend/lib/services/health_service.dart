import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  final Health _health = Health();

  // Define the data types we want to access for the AI assessment
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
  ];

  /// --- MANDATORY ANDROID SETUP ---
  /// The "Authorization Denied" error in your logs is likely because
  /// the following is missing from your AndroidManifest.xml:
  ///
  /// <activity android:name="com.health_connect.PermissionTrampolineActivity" android:exported="true">
  ///    <intent-filter>
  ///      <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
  ///    </intent-filter>
  /// </activity>
  /// <meta-data android:name="health_permissions" android:resource="@array/health_permissions" />

  /// Fetches total steps for today.
  Future<int> fetchStepsToday() async {
    try {
      // 1. Request Physical Activity permission (Android 10+)
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        print("❌ Health Service: Physical Activity Permission missing.");
        return -1;
      }

      // 2. Check if Health Connect is installed/supported on this device
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
        print(
            "⚠️ Health Service: Health Connect not available (Status: $sdkStatus).");
      }

      // 3. Request Authorization from the OS
      // This will trigger the system UI IF the Manifest is configured correctly.
      bool authorized = await _health.requestAuthorization(_types);

      if (authorized) {
        DateTime now = DateTime.now();
        DateTime midnight = DateTime(now.year, now.month, now.day);

        int? steps = await _health.getTotalStepsInInterval(midnight, now);
        return steps ?? 0;
      } else {
        print(
            "❌ Health Service: OS Authorization Denied. Check AndroidManifest.xml");
        return -1;
      }
    } catch (e) {
      print("❌ Health Service Error: $e");
      return 0;
    }
  }

  /// Fetches sleep hours from the last 24 hours
  Future<double> fetchSleepHoursToday() async {
    try {
      bool authorized = await _health.requestAuthorization(_types);
      if (authorized) {
        DateTime now = DateTime.now();
        DateTime yesterday = now.subtract(const Duration(hours: 24));

        List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_SESSION],
          startTime: yesterday,
          endTime: now,
        );

        double totalMinutes = 0;
        for (var point in data) {
          totalMinutes += (point.dateTo.difference(point.dateFrom).inMinutes);
        }

        return double.parse((totalMinutes / 60.0).toStringAsFixed(1));
      }
      return 0.0;
    } catch (e) {
      print("❌ Health Service Sleep Error: $e");
      return 0.0;
    }
  }

  /// Forces the OS to open the Health data settings
  Future<void> openHealthSettings() async {
    try {
      // If Android 14, try reaching Health Connect directly
      await _health.installHealthConnect();
    } catch (e) {
      // Fallback: Open general app settings
      openAppSettings();
    }
  }
}
