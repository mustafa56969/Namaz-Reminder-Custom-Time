import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';

class AddReminderScreen extends StatefulWidget {
  final Reminder? reminder;
  const AddReminderScreen({super.key, this.reminder});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  late DateTime _date;
  late TimeOfDay _time;
  String _repeat = 'none';
  int _colorIndex = 0;
  bool _saving = false;

  bool get _isEditing => widget.reminder != null;

  final _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.reminder!.title;
      _descController.text = widget.reminder!.description ?? '';
      _date = widget.reminder!.dateTime;
      _time = TimeOfDay.fromDateTime(widget.reminder!.dateTime);
      _repeat = widget.reminder!.repeatType;
      _colorIndex = widget.reminder!.colorIndex;
    } else {
      final now = DateTime.now().add(const Duration(hours: 1));
      _date = now;
      _time = TimeOfDay(hour: now.hour, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime get _dateTime => DateTime(
    _date.year, _date.month, _date.day, _time.hour, _time.minute,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future time')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<ReminderProvider>();
      
      if (_isEditing) {
        await provider.updateReminder(widget.reminder!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty 
              ? null : _descController.text.trim(),
          dateTime: _dateTime,
          repeatType: _repeat,
          colorIndex: _colorIndex,
        ));
      } else {
        await provider.addReminder(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty 
              ? null : _descController.text.trim(),
          dateTime: _dateTime,
          repeatType: _repeat,
          colorIndex: _colorIndex,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reminder' : 'New Reminder', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              onPressed: _saving ? null : _save,
              icon: _saving 
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                labelText: 'Title',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                prefixIcon: const Icon(Icons.title_rounded),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty 
                  ? 'Enter a title' : null,
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                hintText: 'Add some more details...',
                labelText: 'Description',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            Text('SCHEDULE', 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildPickerButton(
                    onTap: _pickDate,
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('EEE, MMM d').format(_date),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerButton(
                    onTap: _pickTime,
                    icon: Icons.access_time_rounded,
                    label: _time.format(context),
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Text('REPEAT', 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _customChoiceChip('none', 'Never', colorScheme),
                  const SizedBox(width: 8),
                  _customChoiceChip('daily', 'Daily', colorScheme),
                  const SizedBox(width: 8),
                  _customChoiceChip('weekly', 'Weekly', colorScheme),
                  const SizedBox(width: 8),
                  _customChoiceChip('monthly', 'Monthly', colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text('PRIORITY COLOR', 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _colors[i].withAlpha(_colorIndex == i ? 255 : 100),
                        shape: BoxShape.circle,
                        border: _colorIndex == i 
                            ? Border.all(color: colorScheme.onSurface, width: 3)
                            : null,
                      ),
                      child: _colorIndex == i 
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, 
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customChoiceChip(String value, String label, ColorScheme colorScheme) {
    final isSelected = _repeat == value;
    return GestureDetector(
      onTap: () => setState(() => _repeat = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
