import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  static const _colors = [
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFFBBC05),
    Color(0xFFEA4335),
    Color(0xFF673AB7),
    Color(0xFF009688),
  ];

  Color get _color => _colors[reminder.colorIndex % _colors.length];
  
  bool get _isOverdue => 
      !reminder.isCompleted && reminder.dateTime.isBefore(DateTime.now());

  String get _timeText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (DateTime(reminder.dateTime.year, reminder.dateTime.month, reminder.dateTime.day) == today) {
      return 'Today, ${DateFormat('h:mm a').format(reminder.dateTime)}';
    }
    return DateFormat('MMM d, h:mm a').format(reminder.dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(Icons.delete_rounded, color: colorScheme.onErrorContainer),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: reminder.isCompleted 
                ? colorScheme.surfaceContainerHigh.withAlpha(100)
                : _color.withAlpha(30),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: reminder.isCompleted 
                ? colorScheme.outline.withAlpha(100)
                : _color.withAlpha(80),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reminder.isCompleted ? _color : Colors.transparent,
                    border: Border.all(
                      color: reminder.isCompleted ? _color : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: reminder.isCompleted
                      ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        decoration: reminder.isCompleted 
                            ? TextDecoration.lineThrough : null,
                        color: reminder.isCompleted 
                            ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          decoration: reminder.isCompleted 
                              ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _isOverdue ? Icons.warning_rounded : Icons.access_time_filled_rounded,
                          size: 16,
                          color: _isOverdue ? colorScheme.error : colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isOverdue ? 'Overdue' : _timeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (reminder.repeatType != 'none')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reminder.repeatType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
