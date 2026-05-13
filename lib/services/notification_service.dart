import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    
    final prefs = await SharedPreferences.getInstance();
    
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      await prefs.setBool('notificationPermissionAsked', true);
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await prefs.setBool('notificationPermissionAsked', true);
      return result ?? false;
    }
    return true;
  }

  Future<bool> checkPermissionStatus() async {
    if (kIsWeb) return true;
    
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('notificationPermissionAsked') ?? false;
    
    if (!asked) return false;
    
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  Future<void> scheduleNotification(Reminder reminder) async {
    if (kIsWeb || !reminder.isEnabled) return;

    final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.description ?? 'You have a reminder!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: reminder.repeatType == 'daily' 
          ? DateTimeComponents.time 
          : (reminder.repeatType == 'weekly' ? DateTimeComponents.dayOfWeekAndTime : null),
    );
  }

  Future<void> cancelNotification(String id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id.hashCode);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }
}
