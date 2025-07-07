import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/note.dart';
import '../../state/providers/providers.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final int moodIndex;
  final Color moodColor;
  final Note? noteToEdit;
  
  const NoteEditScreen({
    Key? key,
    required this.moodIndex,
    required this.moodColor,
    this.noteToEdit,
  }) : super(key: key);

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // If editing an existing note, pre-fill the content
    if (widget.noteToEdit != null) {
      _controller.text = widget.noteToEdit!.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Helper method to validate form and save note
  Future<void> _validateAndSave() async {
    if (_formKey.currentState!.validate()) {
      await _saveNote();
    }
  }

  // Helper method to show exit confirmation dialog
  Future<bool> _onWillPop() async {
    if (_controller.text.trim().isEmpty) return true;
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Tienes cambios sin guardar. ¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard before saving
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final isEditing = widget.noteToEdit != null;
      final now = DateTime.now();
      
      // Create the updated note
      final updatedNote = Note(
        id: isEditing ? widget.noteToEdit!.id : const Uuid().v4(),
        content: _controller.text.trim(),
        date: now, // Always update the date when saving
        moodIndex: widget.moodIndex,
        color: widget.moodColor,
      );

      // Get the current notes
      final notesNotifier = ref.read(notesProvider.notifier);
      
      // Only remove the old note if we're editing and the note exists
      if (isEditing && widget.noteToEdit != null) {
        try {
          await notesNotifier.removeNote(widget.noteToEdit!);
        } catch (e) {
          debugPrint('Error removing old note: $e');
          // Continue with adding the new note even if removal fails
        }
      }
      
      // Add the updated/new note
      await notesNotifier.addNote(updatedNote);
      
      // Show success feedback
      if (!mounted) return;
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
      
      // Show success message
      final snackBar = SnackBar(
        content: Text(isEditing ? 'Nota actualizada' : 'Nota guardada correctamente'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
      
      // Navigate back to home screen
      if (mounted) {
        // Return the updated note to trigger animation if it's a new note
        Navigator.of(context).pop(!isEditing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la nota: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Method to handle note deletion
  Future<void> _deleteNote() async {
    if (widget.noteToEdit == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(notesProvider.notifier).removeNote(widget.noteToEdit!);
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate note was deleted
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar la nota')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final moodEmojis = ['😄', '🙂', '😐', '🙁', '😞'];
    final moodDescriptions = [
      '¡Excelente!',
      'Bien',
      'Neutral',
      'No muy bien',
      'Mal'
    ];
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.noteToEdit == null ? 'Nueva nota' : 'Editar nota'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop(false);
              }
            },
          ),
          elevation: 0,
          scrolledUnderElevation: 1,
          actions: [
            if (widget.noteToEdit != null && !_isSubmitting)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _deleteNote,
                tooltip: 'Eliminar nota',
              ),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood indicator
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mood_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tu estado de ánimo',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: widget.moodColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.moodColor.withAlpha(150),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.moodColor.withAlpha(50),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                moodEmojis[widget.moodIndex],
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                moodDescriptions[widget.moodIndex],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Note content field
                TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: '¿Qué te hace sentir así?',
                    hintText: 'Describe brevemente qué te hace sentir así...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor escribe algo sobre cómo te sientes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _validateAndSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Guardar nota',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}