import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();
  
  List<Reminder> _reminders = [];
  bool _isLoading = false;

  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;

  List<Reminder> get upcoming => _reminders
      .where((r) => !r.isCompleted && r.dateTime.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Reminder> get today {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    
    return _reminders
        .where((r) => !r.isCompleted && 
            r.dateTime.isAfter(start) && 
            r.dateTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Reminder> get completed => _reminders
      .where((r) => r.isCompleted)
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reminders = await _db.getAllReminders();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addReminder({
    required String title,
    String? description,
    required DateTime dateTime,
    String repeatType = 'none',
    int colorIndex = 0,
  }) async {
    final reminder = Reminder(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dateTime: dateTime,
      repeatType: repeatType,
      colorIndex: colorIndex,
    );

    await _db.insertReminder(reminder);
    await _notif.scheduleNotification(reminder);
    _reminders.add(reminder);
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _db.updateReminder(reminder);
    await _notif.cancelNotification(reminder.id);
    
    if (reminder.isEnabled && !reminder.isCompleted) {
      await _notif.scheduleNotification(reminder);
    }

    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      notifyListeners();
    }
  }

  Future<void> toggleComplete(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final updated = _reminders[index].copyWith(
      isCompleted: !_reminders[index].isCompleted,
    );
    await updateReminder(updated);
  }

  Future<void> deleteReminder(String id) async {
    await _db.deleteReminder(id);
    await _notif.cancelNotification(id);
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> deleteAllCompleted() async {
    for (final r in completed) {
      await _db.deleteReminder(r.id);
    }
    _reminders.removeWhere((r) => r.isCompleted);
    notifyListeners();
  }
}
