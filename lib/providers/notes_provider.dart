import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Note color options
const List<String> noteColors = [
  '#F28B82', // Red
  '#FBBC04', // Yellow
  '#FFF475', // Light Yellow
  '#CCFF90', // Lime
  '#A7FFEB', // Teal
  '#CBF0F8', // Cyan
  '#AECBFA', // Blue
  '#D7AEFB', // Purple
  '#FDCFE8', // Pink
  '#E6C9A8', // Brown
];

class Note {
  final String id;
  final String title;
  final String content;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      color: map['color'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class NotesProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NotesProvider({required SharedPreferences prefs}) {
    _prefs = prefs;
    loadNotes();
  }

  set prefs(SharedPreferences prefs) {
    _prefs = prefs;
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final notesData = _prefs!.getString('notes') ?? '[]';
      final List<dynamic> decoded = jsonDecode(notesData);

      _notes = (decoded as List)
          .map((e) => Note.fromMap(e as Map<String, dynamic>))
          .toList();

      // Sort by updated date (newest first)
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveNote(Note note) async {
    final now = DateTime.now();
    final updatedNote = note.copyWith(
      updatedAt: now,
    );

    final index = _notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
    } else {
      final newNote = updatedNote.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      _notes.insert(0, newNote);
    }

    await _saveNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> _saveNotes() async {
    final encoded = jsonEncode(_notes.map((n) => n.toMap()).toList());
    await _prefs!.setString('notes', encoded);
  }
}
