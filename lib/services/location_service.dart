import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// 定位服务：前台 + 后台持续定位。
///
/// 后台生效的前提（已在本项目 platform/ 补丁与 README 里写好）：
///  - iOS: Info.plist 加 UIBackgroundModes=location + Always 权限描述
///  - Android: 加 ACCESS_BACKGROUND_LOCATION / FOREGROUND_SERVICE 权限
class LocationService {
  /// 检查并请求定位权限，返回是否可用。
  static Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// 持续定位流。
  static Stream<Position> stream() {
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: '位置共享进行中',
          notificationText: '正在持续共享你的位置',
          enableWakeLock: true,
        ),
      );
    } else {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        activityType: ActivityType.other,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
