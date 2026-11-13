import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _permissionGranted = false;

  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      debugPrint('NotificationService: Local notifications are not supported on Flutter Web');
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (e) {
        debugPrint('Could not set local timezone: $e');
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Check / request initial permission
      _permissionGranted = await requestPermission();
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission() ?? false;
        try {
          await androidImpl?.requestExactAlarmsPermission();
        } catch (_) {}
        _permissionGranted = granted;
        return granted;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final darwinImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await darwinImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        _permissionGranted = granted;
        return granted;
      }
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
    }
    return false;
  }

  Future<bool> checkPermission() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await androidImpl?.areNotificationsEnabled() ?? false;
        _permissionGranted = enabled;
        return enabled;
      }
    } catch (_) {}
    return _permissionGranted;
  }

  NotificationDetails _buildDetails() {
    const androidDetails = AndroidNotificationDetails(
      'ecommerce_channel_id',
      'E-Commerce Notifications',
      channelDescription: 'Notifications for store deals, updates, and reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  Future<bool> showNotification({
    String title = 'HI FROM FLUTTER',
    String body = 'THIS IS THE BODY OF THE NOTIFICATION',
    int id = 0,
  }) async {
    if (kIsWeb) {
      debugPrint('NotificationService: Local notifications are not supported on Flutter Web');
      return false;
    }

    try {
      if (!_permissionGranted) {
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('NotificationService: Permission not granted to show notification');
          return false;
        }
      }

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _buildDetails(),
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService showNotification error: $e');
      return false;
    }
  }

  Future<bool> showNow({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    return await showNotification(title: title, body: body, id: id);
  }

  Future<bool> scheduleNotification({
    String title = 'HI FROM FLUTTER',
    String body = 'THIS IS THE BODY OF THE NOTIFICATION',
    int seconds = 5,
    int id = 1,
  }) async {
    if (kIsWeb) {
      debugPrint('NotificationService: Local notifications are not supported on Flutter Web');
      return false;
    }

    try {
      if (!_permissionGranted) {
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('NotificationService: Permission not granted to schedule notification');
          return false;
        }
      }

      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _buildDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService scheduleNotification error: $e');
      return false;
    }
  }

  Future<bool> schedule({
    required String title,
    required String body,
    required int seconds,
    int id = 1,
    String? payload,
  }) async {
    return await scheduleNotification(title: title, body: body, seconds: seconds, id: id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
