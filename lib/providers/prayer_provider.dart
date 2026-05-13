import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../models/reminder.dart';

// Prayer time configuration
const List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const List<String> prayerArabicNames = [
  'الفجر',
  'الظهر',
  'العصر',
  'المغرب',
  'العشاء',
];
const List<String> prayerIcons = [
  'wb_twilight',
  'light_mode',
  'wb_cloudy',
  'nights_stay',
  'bedtime',
];

// Hue values for dynamic theming based on prayer time
const Map<String, int> prayerHues = {
  'Fajr': 210,
  'Dhuhr': 45,
  'Asr': 25,
  'Maghrib': 340,
  'Isha': 260,
};

class Prayer {
  final String id;
  final String name;
  final String arabicName;
  final DateTime time;
  final bool isEnabled;
  final bool isCompleted;

  Prayer({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.time,
    this.isEnabled = true,
    this.isCompleted = false,
  });

  Prayer copyWith({
    String? id,
    String? name,
    String? arabicName,
    DateTime? time,
    bool? isEnabled,
    bool? isCompleted,
  }) {
    return Prayer(
      id: id ?? this.id,
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'arabicName': arabicName,
      'time': time.toIso8601String(),
      'isEnabled': isEnabled ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Prayer.fromMap(Map<String, dynamic> map) {
    return Prayer(
      id: map['id'] as String,
      name: map['name'] as String,
      arabicName: map['arabicName'] as String,
      time: DateTime.parse(map['time'] as String),
      isEnabled: map['isEnabled'] == 1,
      isCompleted: map['isCompleted'] == 1,
    );
  }
}

class PrayerProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  final NotificationService _notificationService;

  List<Prayer> _prayers = [];
  bool _isLoading = false;

  List<Prayer> get prayers => _prayers;
  bool get isLoading => _isLoading;

  // Get next prayer
  Prayer? get nextPrayer {
    final now = DateTime.now();
    
    // Normalize prayers to today's date for comparison
    final normalizedPrayers = _prayers.map((p) {
      return p.copyWith(
        time: DateTime(now.year, now.month, now.day, p.time.hour, p.time.minute)
      );
    }).toList();
    
    // Find prayers that are still upcoming today
    final upcomingToday = normalizedPrayers
        .where((p) => p.time.isAfter(now) && p.isEnabled)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    
    if (upcomingToday.isNotEmpty) {
      return upcomingToday[0];
    }
    
    // If no more prayers today, return the first enabled prayer (which will be tomorrow's Fajr)
    final allEnabled = normalizedPrayers.where((p) => p.isEnabled).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
      
    if (allEnabled.isNotEmpty) {
      // Return the first one but indicate it's for tomorrow by adding 1 day to the time for display/calculations
      final first = allEnabled[0];
      return first.copyWith(time: first.time.add(const Duration(days: 1)));
    }
    
    return null;
  }

  set prefs(SharedPreferences prefs) {
    _prefs = prefs;
    loadPrayers();
  }

  PrayerProvider({required SharedPreferences prefs, required NotificationService notificationService}) : _notificationService = notificationService {
    _prefs = prefs;
    // Load prayers when provider is created
    loadPrayers();
  }

  Future<void> loadPrayers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prayerData = _prefs!.getString('prayers') ?? '[]';
      final List<dynamic> decoded = jsonDecode(prayerData);

      _prayers = (decoded as List)
          .map((e) => Prayer.fromMap(e as Map<String, dynamic>))
          .toList();

      // Ensure we have all 5 prayers
      if (_prayers.isEmpty) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final defaultTimes = [
          today.add(const Duration(hours: 5, minutes: 12)), // Fajr
          today.add(const Duration(hours: 12, minutes: 30)), // Dhuhr
          today.add(const Duration(hours: 15, minutes: 45)), // Asr
          today.add(const Duration(hours: 18, minutes: 10)), // Maghrib
          today.add(const Duration(hours: 19, minutes: 40)), // Isha
        ];

        _prayers = List.generate(
          5,
          (i) => Prayer(
            id: const Uuid().v4(),
            name: prayerNames[i],
            arabicName: prayerArabicNames[i],
            time: defaultTimes[i],
            isEnabled: true,
          ),
        );

        await _savePrayers();
      }

      // Schedule notifications
      for (final prayer in _prayers) {
        if (prayer.isEnabled) {
          await _schedulePrayerNotification(prayer);
        }
      }
    } catch (e) {
      debugPrint('Error loading prayers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _savePrayers() async {
    final encoded = jsonEncode(_prayers.map((p) => p.toMap()).toList());
    await _prefs!.setString('prayers', encoded);
  }

  Future<void> updatePrayer(Prayer prayer) async {
    final index = _prayers.indexWhere((p) => p.id == prayer.id);
    if (index != -1) {
      _prayers[index] = prayer;
      await _savePrayers();

      // Update notification
      await _notificationService.cancelNotification(prayer.id);
      if (prayer.isEnabled) {
        await _schedulePrayerNotification(prayer);
      }

      notifyListeners();
    }
  }

  Future<void> _schedulePrayerNotification(Prayer prayer) async {
    var scheduledDate = tz.TZDateTime.from(prayer.time, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      // For past times, schedule for tomorrow
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'prayer_notifications',
      'Prayer Notifications',
      channelDescription: 'Notifications for prayer times',
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

    // Create a temporary reminder-like object for scheduling
    await _notificationService.scheduleNotification(Reminder(
      id: prayer.id,
      title: '${prayer.name} Time',
      description:
          "It's time for ${prayer.name}. Consider performing your prayer.",
      dateTime: scheduledDate.toLocal(),
      isCompleted: false,
      isEnabled: prayer.isEnabled,
      repeatType: 'daily',
      colorIndex: 0,
    ));
  }
}
