import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  late final FocusNode bodyFocus;
  String colorLabel = '#1A1A1A';
  Note? existingNote;
  bool isEditMode = false;
  bool _isDirty = false;

  static const List<String> _colorOptions = [
    '#1A1A1A',
    '#1A2A3A',
    '#1A2A1A',
    '#2A1A2A',
    '#2A1A1A',
    '#2A2A1A',
  ];

  static const List<Color> _colorDisplay = [
    Color(0xFF1A1A1A),
    Color(0xFF1A2A3A),
    Color(0xFF1A2A1A),
    Color(0xFF2A1A2A),
    Color(0xFF2A1A1A),
    Color(0xFF2A2A1A),
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    bodyController = TextEditingController();
    bodyFocus = FocusNode();

    if (widget.noteId == 'new') {
      isEditMode = true;
    } else {
      _loadExistingNote();
    }

    titleController.addListener(() => setState(() => _isDirty = true));
    bodyController.addListener(() => setState(() => _isDirty = true));
  }

  void _loadExistingNote() {
    final notes = ref.read(notesProvider);
    try {
      existingNote = notes.firstWhere((n) => n.id == widget.noteId);
      titleController.text = existingNote!.title;
      bodyController.text = existingNote!.body;
      colorLabel = existingNote!.colorLabel;
      isEditMode = false;
    } catch (_) {
      isEditMode = true;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (titleController.text.trim().isEmpty &&
        bodyController.text.trim().isEmpty) {
      context.pop();
      return;
    }

    final notifier = ref.read(notesProvider.notifier);

    if (existingNote != null) {
      existingNote!.title = titleController.text.trim();
      existingNote!.body = bodyController.text.trim();
      existingNote!.colorLabel = colorLabel;
      existingNote!.updatedAt = DateTime.now();
      await notifier.updateNote(existingNote!);
    } else {
      final note = Note.create(
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        colorLabel: colorLabel,
      );
      await notifier.addNote(note);
    }

    if (mounted) {
      setState(() => isEditMode = false);
      if (widget.noteId == 'new') context.pop();
    }
  }

  // Insert bullet point at cursor position
  void _insertBullet() {
    final controller = bodyController;
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      // Just append bullet at end
      final newText = text.isEmpty ? '• ' : '$text\n• ';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }

    // Find start of current line
    final cursorPos = selection.baseOffset;
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    final currentLine = text.substring(lineStart, cursorPos);
    final alreadyHasBullet = currentLine.startsWith('• ');

    if (alreadyHasBullet) {
      // Remove bullet from current line
      final newText = text.substring(0, lineStart) +
          text.substring(lineStart + 2);
      final newCursor = (cursorPos - 2).clamp(0, newText.length);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    } else {
      // Add bullet to start of current line
      final newText = text.substring(0, lineStart) +
          '• ' +
          text.substring(lineStart);
      controller.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: cursorPos + 2),
      );
    }

    bodyFocus.requestFocus();
  }

  // Handle enter key to auto-continue bullet list
  void _onBodyChanged(String value) {
    final text = bodyController.text;
    final selection = bodyController.selection;
    if (!selection.isValid) return;

    // Check if user just pressed enter after a bullet line
    final cursorPos = selection.baseOffset;
    if (cursorPos < 1) return;

    if (text[cursorPos - 1] == '\n' && cursorPos >= 3) {
      // Find the previous line
      int prevLineStart = cursorPos - 2;
      while (prevLineStart > 0 && text[prevLineStart - 1] != '\n') {
        prevLineStart--;
      }
      final prevLine = text.substring(prevLineStart, cursorPos - 1);

      if (prevLine == '• ') {
        // Empty bullet — remove it and stop the list
        final newText = text.substring(0, prevLineStart) +
            text.substring(cursorPos - 1);
        bodyController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: prevLineStart,
          ),
        );
      } else if (prevLine.startsWith('• ')) {
        // Continue bullet list
        final newText = text.substring(0, cursorPos) +
            '• ' +
            text.substring(cursorPos);
        bodyController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: cursorPos + 2,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isDirty && isEditMode) {
              _save();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (!isEditMode)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: AppColors.notes,
              ),
              onPressed: () {
                setState(() => isEditMode = true);
                bodyFocus.requestFocus();
              },
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Done',
                style: TextStyle(
                  color: AppColors.notes,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!isEditMode)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  isEditMode
                      ? TextField(
                          controller: titleController,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Title',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        )
                      : Text(
                          titleController.text.isEmpty
                              ? 'Untitled'
                              : titleController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                  Divider(color: AppColors.border, height: 24),

                  // Body
                  isEditMode
                      ? TextField(
                          controller: bodyController,
                          focusNode: bodyFocus,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Start writing...',
                            hintStyle: TextStyle(
                              color: AppColors.textHint,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: _onBodyChanged,
                        )
                      : SelectableText(
                          bodyController.text,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                ],
              ),
            ),
          ),

          // Toolbar — only in edit mode
          if (isEditMode)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Bold
                  _ToolbarButton(
                    label: 'B',
                    bold: true,
                    onTap: () {
                      final sel = bodyController.selection;
                      if (!sel.isValid || sel.isCollapsed) return;
                      final selected = bodyController.text
                          .substring(sel.start, sel.end);
                      final newText =
                          bodyController.text.substring(0, sel.start) +
                              '**$selected**' +
                              bodyController.text.substring(sel.end);
                      bodyController.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: sel.end + 4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // Italic
                  _ToolbarButton(
                    label: 'I',
                    italic: true,
                    onTap: () {
                      final sel = bodyController.selection;
                      if (!sel.isValid || sel.isCollapsed) return;
                      final selected = bodyController.text
                          .substring(sel.start, sel.end);
                      final newText =
                          bodyController.text.substring(0, sel.start) +
                              '_${selected}_' +
                              bodyController.text.substring(sel.end);
                      bodyController.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: sel.end + 2,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // Bullet point — THE NEW BUTTON
                  _ToolbarButton(
                    icon: Icons.format_list_bulleted,
                    onTap: _insertBullet,
                    tooltip: 'Bullet point',
                  ),
                  const SizedBox(width: 4),
                  // Checkbox item
                  _ToolbarButton(
                    icon: Icons.check_box_outline_blank,
                    onTap: () {
                      final controller = bodyController;
                      final text = controller.text;
                      final sel = controller.selection;
                      final pos =
                          sel.isValid ? sel.baseOffset : text.length;
                      final newText =
                          text.substring(0, pos) +
                              '☐ ' +
                              text.substring(pos);
                      controller.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: pos + 2,
                        ),
                      );
                      bodyFocus.requestFocus();
                    },
                    tooltip: 'Checkbox',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 8),
                  // Color dots
                  ...List.generate(_colorOptions.length, (index) {
                    final isSelected = colorLabel == _colorOptions[index];
                    return GestureDetector(
                      onTap: () => setState(
                        () => colorLabel = _colorOptions[index],
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _colorDisplay[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete note?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'This note will be permanently deleted.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (existingNote != null) {
        await ref.read(notesProvider.notifier).deleteNote(existingNote!.id);
      }
      if (mounted) context.pop();
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    this.label,
    this.icon,
    required this.onTap,
    this.bold = false,
    this.italic = false,
    this.tooltip,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool bold;
  final bool italic;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget child = icon != null
        ? Icon(icon, color: AppColors.textSecondary, size: 18)
        : Text(
            label ?? '',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          );

    return Tooltip(
      message: tooltip ?? label ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}