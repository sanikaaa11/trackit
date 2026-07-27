import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/note_model.dart';
import '../domain/note_notifier.dart';

final notesSearchModeProvider = StateProvider<bool>((ref) => false);

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(filteredNotesProvider);
    final isSearchMode = ref.watch(notesSearchModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: isSearchMode
            ? TextField(
                autofocus: true,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            onPressed: () {
              final nextMode = !isSearchMode;
              ref.read(notesSearchModeProvider.notifier).state = nextMode;
              if (!nextMode) {
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
            icon: Icon(
              isSearchMode ? Icons.close : Icons.search,
              color: AppColors.notes,
            ),
          ),
        ],
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: AppSizes.md),
                  Text(
                    'Start capturing thoughts',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _NoteCard(note: note);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.notes,
        onPressed: () => context.push('/notes/edit/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.parse(normalized, radix: 16));
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete note?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(notesProvider.notifier).deleteNote(note.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/notes/edit/${note.id}'),
      onLongPress: () => _showDeleteDialog(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border(left: BorderSide(color: _parseColor(note.colorLabel), width: 3)),
        ),
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: note.isPinned
                  ? Icon(Icons.push_pin, color: AppColors.notes, size: AppSizes.iconSm)
                  : const SizedBox(height: 16),
            ),
            Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            Expanded(
              child: Text(
                note.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(height: AppSizes.sm),
            Text(
              DateFormat('dd MMM yyyy').format(note.updatedAt),
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
