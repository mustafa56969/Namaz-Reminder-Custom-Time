import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/reminder_card.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withAlpha(100),
                borderRadius: BorderRadius.circular(32),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: colorScheme.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                tabs: const [
                  Tab(text: 'UPCOMING'),
                  Tab(text: 'TODAY'),
                  Tab(text: 'DONE'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<ReminderProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(provider.upcoming, 'Clear for later', Icons.calendar_today_rounded, colorScheme),
                    _buildList(provider.today, 'You are all caught up!', Icons.check_circle_rounded, colorScheme),
                    _buildCompletedList(provider, colorScheme),
                  ],
                );
              },
            ),
          ),
        ],
    );
  }

  Widget _buildList(List reminders, String emptyText, IconData icon, ColorScheme colorScheme) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        return ReminderCard(
          reminder: reminders[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddReminderScreen(reminder: reminders[index])),
          ),
          onComplete: () => context.read<ReminderProvider>().toggleComplete(reminders[index].id),
          onDelete: () => context.read<ReminderProvider>().deleteReminder(reminders[index].id),
        );
      },
    );
  }

  Widget _buildCompletedList(ReminderProvider provider, ColorScheme colorScheme) {
    if (provider.completed.isEmpty) {
      return _buildList([], 'No completed tasks', Icons.done_all_rounded, colorScheme);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => provider.deleteAllCompleted(),
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Clear all completed'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            itemCount: provider.completed.length,
            itemBuilder: (context, index) {
              return ReminderCard(
                reminder: provider.completed[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddReminderScreen(reminder: provider.completed[index])),
                ),
                onComplete: () => provider.toggleComplete(provider.completed[index].id),
                onDelete: () => provider.deleteReminder(provider.completed[index].id),
              );
            },
          ),
        ),
      ],
    );
  }
}
