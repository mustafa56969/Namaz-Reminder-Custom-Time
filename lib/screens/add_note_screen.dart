import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/notes_provider.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? note;

  const AddNoteScreen({super.key, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? '#AECBFA'; // Default to a nice blue
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Choose a color based on the note's text or ID for stability
    final Color noteBackground = widget.note != null 
        ? Color(int.parse(widget.note!.color.substring(1), radix: 16))
        : colorScheme.secondaryContainer;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.note == null ? 'Take a note' : 'Edit note', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)
        ),
        actions: [
          if (widget.note != null)
            IconButton(
              onPressed: () {
                Provider.of<NotesProvider>(context, listen: false).deleteNote(widget.note!.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _saveNote,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.save_rounded, size: 22),
              tooltip: 'Save Note',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              noteBackground.withAlpha(50),
              colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withAlpha(100),
                        fontWeight: FontWeight.w900
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Note something down...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 18, 
                      height: 1.6,
                      color: colorScheme.onSurface.withAlpha(220),
                    ),
                    maxLines: null,
                    autofocus: widget.note == null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    
    // Automatic color assignment if new
    String finalColor = _selectedColor;
    if (widget.note == null) {
      final colors = ['#AECBFA', '#F28B82', '#FBBC04', '#FFF475', '#CCFF90', '#A7FFEB', '#CBF0F8', '#D7AEFB', '#FDCFE8', '#E6C9A8', '#E8EAED'];
      finalColor = colors[DateTime.now().millisecond % colors.length];
    }

    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      color: finalColor,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await notesProvider.saveNote(note);
    if (mounted) Navigator.pop(context);
  }
}
