import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/note_model.dart';
import '../domain/note_notifier.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController titleController;
  late final TextEditingController bodyController;

  bool isEditMode = false;
  String colorLabel = '#1A1A1A';
  Note? existingNote;

  final List<String> colorOptions = const [
    '#1A1A1A',
    '#378ADD',
    '#7F77DD',
    '#BA7517',
    '#1D9E75',
    '#D85A30',
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    bodyController = TextEditingController();
    isEditMode = widget.noteId == 'new';

    if (widget.noteId != 'new') {
      _loadExistingNote();
    }
  }

  void _loadExistingNote() {
    final notes = ref.read(notesProvider);
    final note = notes.where((n) => n.id == widget.noteId).firstOrNull;
    if (note == null) return;

    existingNote = note;
    titleController.text = note.title;
    bodyController.text = note.body;
    colorLabel = note.colorLabel;
  }

  String get _displayTitle {
    final title = titleController.text.trim();
    if (title.isNotEmpty) return title;
    return existingNote?.title.isNotEmpty == true
        ? existingNote!.title
        : 'Untitled';
  }

  Future<void> _saveNote() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (existingNote == null) {
      final note = Note.create(
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
        colorLabel: colorLabel,
      );
      await ref.read(notesProvider.notifier).addNote(note);
      existingNote = note;
    } else {
      existingNote!
        ..title = title.isEmpty ? 'Untitled' : title
        ..body = body
        ..colorLabel = colorLabel;
      await ref.read(notesProvider.notifier).updateNote(existingNote!);
    }

    if (!mounted) return;
    setState(() => isEditMode = false);
  }

  Future<void> _deleteNote() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete note?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || existingNote == null) return;

    await ref.read(notesProvider.notifier).deleteNote(existingNote!.id);
    if (mounted) context.pop();
  }

  Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = existingNote?.updatedAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
        ),
        actions: [
          if (isEditMode)
            TextButton(
              onPressed: _saveNote,
              child: Text(
                'Done',
                style: TextStyle(
                  color: AppColors.notes,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => setState(() => isEditMode = true),
                  icon: Icon(Icons.edit_outlined, color: AppColors.notes),
                ),
                IconButton(
                  onPressed: _deleteNote,
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ),
        ],
        title: Text(
          _displayTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isEditMode
              ? _buildEditMode(updatedAt)
              : _buildViewMode(updatedAt),
        ),
      ),
    );
  }

  Widget _buildViewMode(DateTime updatedAt) {
    final title = _displayTitle;
    final body = bodyController.text.trim().isEmpty
        ? 'No content yet.'
        : bodyController.text.trim();

    return GestureDetector(
      key: const ValueKey('view-mode'),
      onTap: () => setState(() => isEditMode = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('hh:mm a').format(updatedAt),
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border, height: 1),
          ),
          Expanded(
            child: SelectableText(
              body,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(DateTime updatedAt) {
    return Column(
      key: const ValueKey('edit-mode'),
      children: [
        TextField(
          controller: titleController,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Title',
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            border: InputBorder.none,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: AppColors.border, height: 1),
        ),
        Expanded(
          child: TextField(
            controller: bodyController,
            onChanged: (_) => setState(() {}),
            expands: true,
            maxLines: null,
            minLines: null,
            textCapitalization: TextCapitalization.sentences,
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontLg,
            ),
            decoration: InputDecoration(
              hintText: 'Start writing...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontLg,
              ),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
        Row(
          children: [
            ...colorOptions.map((hex) {
              final isSelected = colorLabel == hex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    colorLabel = hex;
                  });
                },
                child: Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.only(right: AppSizes.sm),
                  decoration: BoxDecoration(
                    color: _parseColor(hex),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              DateFormat('hh:mm a').format(updatedAt),
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
