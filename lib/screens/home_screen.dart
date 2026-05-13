import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/prayer_provider.dart';
import 'prayer_screen.dart';
import 'notes_screen.dart';
import 'reminders_screen.dart';
import 'add_note_screen.dart';
import 'add_reminder_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const PrayerScreen(),
    const NotesScreen(),
    const RemindersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false, // Prevents FAB from jumping up with keyboard
      floatingActionButton: _currentIndex == 0 
        ? null 
        : FloatingActionButton.large(
            onPressed: () {
              if (_currentIndex == 1) {
                // Add Note
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNoteScreen()),
                );
              } else if (_currentIndex == 2) {
                // Add Reminder
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddReminderScreen()),
                );
              }
            },
            child: Icon(
              _currentIndex == 1 ? Icons.add_rounded : Icons.alarm_add_rounded,
              size: 32,
            ),
          ),
      body: Stack(
        children: [
          // Background Blobs (similar to prayer.html)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withAlpha(40),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withAlpha(40),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Modern Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () => themeProvider.toggleTheme(),
                        icon: Icon(
                          themeProvider.mode == ThemeMode.system 
                            ? Icons.brightness_auto_rounded 
                            : (themeProvider.mode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _screens[_currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.schedule_rounded), 
                selectedIcon: Icon(Icons.schedule_rounded, fill: 1),
                label: 'Prayer',
              ),
              NavigationDestination(
                icon: Icon(Icons.notes_rounded), 
                selectedIcon: Icon(Icons.notes_rounded, fill: 1),
                label: 'Notes',
              ),
              NavigationDestination(
                icon: Icon(Icons.alarm_rounded), 
                selectedIcon: Icon(Icons.alarm_rounded, fill: 1),
                label: 'Alarms',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
