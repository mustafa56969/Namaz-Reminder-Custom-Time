import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/notes_provider.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final filteredNotes = notesProvider.notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Pixel-style Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search your notes',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh.withAlpha(150),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        Expanded(
          child: notesProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredNotes.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: filteredNotes.length,
                        padding: const EdgeInsets.only(bottom: 120),
                        itemBuilder: (context, index) {
                          return _buildNoteCard(filteredNotes[index], context, colorScheme);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notes_rounded, size: 64, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No notes yet' : 'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, BuildContext context, ColorScheme colorScheme) {
    final noteColor = Color(int.parse(note.color.substring(1), radix: 16)).withAlpha(255);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddNoteScreen(note: note),
          ),
        ).then((_) => Provider.of<NotesProvider>(context, listen: false).loadNotes());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark 
              ? Color.alphaBlend(noteColor.withAlpha(40), colorScheme.surface)
              : noteColor.withAlpha(50),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: noteColor.withAlpha(isDark ? 100 : 120),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: noteColor.withAlpha(isDark ? 5 : 15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title.isNotEmpty)
              Text(
                note.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  color: colorScheme.onSurface,
                ),
              ),
            if (note.title.isNotEmpty && note.content.isNotEmpty)
              const SizedBox(height: 16),
            Text(
              note.content,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withAlpha(200),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
                Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: noteColor.withAlpha(200),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
