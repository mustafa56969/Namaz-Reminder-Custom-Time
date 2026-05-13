import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<PrayerProvider, ThemeProvider>(
      builder: (context, prayerProvider, themeProvider, child) {
        final nextPrayer = prayerProvider.nextPrayer;
        final colorScheme = Theme.of(context).colorScheme;

        // Update theme based on current/next prayer
        if (nextPrayer != null) {
          final hue = prayerHues[nextPrayer.name] ?? 210;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            themeProvider.setPrimaryHue(hue);
          });
        }

        return Column(
          children: [
            if (nextPrayer != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildHeroWidget(nextPrayer, colorScheme),
              ),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView.separated(
                  itemCount: prayerProvider.prayers.length,
                  padding: const EdgeInsets.only(bottom: 120),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final prayer = prayerProvider.prayers[index];
                    final isNext = nextPrayer?.id == prayer.id;
                    return _buildPrayerItem(prayer, isNext, colorScheme, prayerProvider);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroWidget(Prayer prayer, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(200),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(20),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'NEXT PRAYER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: colorScheme.onPrimaryContainer.withAlpha(180),
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prayer.arabicName,
              style: GoogleFonts.cairo(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: colorScheme.onPrimaryContainer,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('h:mm a').format(prayer.time),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(Prayer prayer, bool isNext, ColorScheme colorScheme, PrayerProvider provider) {
    return GestureDetector(
      onTap: () => _editPrayerTime(context, prayer, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isNext ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isNext ? colorScheme.primary : colorScheme.outlineVariant.withAlpha(100),
            width: isNext ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isNext ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getPrayerIcon(prayer.name),
                color: isNext ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isNext ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    prayer.arabicName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isNext ? colorScheme.onPrimaryContainer.withAlpha(180) : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('h:mm a').format(prayer.time),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isNext ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => provider.updatePrayer(prayer.copyWith(isEnabled: !prayer.isEnabled)),
                  child: Icon(
                    prayer.isEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    size: 16,
                    color: isNext 
                      ? colorScheme.onPrimaryContainer.withAlpha(200) 
                      : colorScheme.primary.withAlpha(150),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String name) {
    switch (name) {
      case 'Fajr': return Icons.wb_twilight_rounded;
      case 'Dhuhr': return Icons.light_mode_rounded;
      case 'Asr': return Icons.wb_cloudy_rounded;
      case 'Maghrib': return Icons.nights_stay_rounded;
      case 'Isha': return Icons.bedtime_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  Future<void> _editPrayerTime(BuildContext context, Prayer prayer, PrayerProvider provider) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(prayer.time),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final now = DateTime.now();
      final newTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      await provider.updatePrayer(prayer.copyWith(time: newTime));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${prayer.name} time updated to ${picked.format(context)}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }
}
