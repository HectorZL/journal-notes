import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notas_animo/providers/auth_provider.dart';
import '../../models/note.dart';
import '../../state/providers/providers.dart';

class _FloatingWeatherIcon extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final Color color;
  final int index;

  const _FloatingWeatherIcon({
    Key? key,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.index,
  }) : super(key: key);

  @override
  _FloatingWeatherIconState createState() => _FloatingWeatherIconState();
}

class _FloatingWeatherIconState extends State<_FloatingWeatherIcon> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3 + widget.index),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation for selection
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
    
    if (widget.isSelected) {
      _scaleController.forward();
    }
  }
  
  @override
  void didUpdateWidget(_FloatingWeatherIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.isSelected 
                    ? widget.color.withValues(alpha: 25)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected 
                      ? widget.color 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 32,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}


class NoteEditScreen extends ConsumerStatefulWidget {
  final int initialMoodIndex;
  final Color moodColor;
  final String moodDescription;
  final String moodEmoji;
  final Note? noteToEdit;
  
  const NoteEditScreen({
    Key? key,
    required this.initialMoodIndex,
    required this.moodColor,
    this.moodDescription = '',
    this.moodEmoji = '😊',
    this.noteToEdit,
  }) : super(key: key);

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  late int _currentMoodIndex;

  @override
  void initState() {
    super.initState();
    _currentMoodIndex = widget.initialMoodIndex;
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
      
      // Get current user ID from auth provider
      final auth = ref.read(authProvider);
      final userId = int.tryParse(auth.userId ?? '');
      
      if (userId == null) {
        throw Exception('No se pudo obtener el ID de usuario válido');
      }
      
      // Create the updated note with all necessary fields
      final note = Note(
        id: widget.noteToEdit?.id,  // This will be null for new notes
        userId: userId,
        content: _controller.text.trim(),
        moodIndex: _currentMoodIndex,
        date: widget.noteToEdit?.date ?? now,
        color: widget.noteToEdit?.color ?? widget.moodColor,
      );

      final notesNotifier = ref.read(notesProvider.notifier);
      
      if (isEditing) {
        if (widget.noteToEdit?.id == null) {
          throw Exception('No se pudo actualizar la nota: ID no válido');
        }
        await notesNotifier.updateNote(note);
      } else {
        await notesNotifier.addNote(note);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Nota actualizada' : 'Nota guardada correctamente'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
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
    if (widget.noteToEdit == null || widget.noteToEdit!.id == null) return;
    
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
        await ref.read(notesProvider.notifier).deleteNote(widget.noteToEdit!.id!);
        if (mounted) {
          // Show snackbar with undo option
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars(); // Clear any existing snackbars
          
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Nota eliminada'),
              action: SnackBarAction(
                label: 'DESHACER',
                textColor: Colors.yellow,
                onPressed: () async {
                  try {
                    final success = await ref.read(notesProvider.notifier).undoLastDelete();
                    if (success && mounted) {
                      // Show confirmation that undo was successful
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Acción deshecha correctamente'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      // If we're still on this screen after undo, pop it
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.of(context).pop(false);
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Error al deshacer la acción'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          
          // Only pop the screen after showing the snackbar
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar la nota: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteToEdit != null;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar Nota' : 'Nueva Nota'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (isEditing && !_isSubmitting)
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected mood display
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: widget.moodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: widget.moodColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.moodEmoji.isNotEmpty 
                            ? widget.moodEmoji 
                            : '😊', // Fallback emoji
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.moodDescription.isNotEmpty
                            ? widget.moodDescription
                            : 'Sin estado de ánimo', // Fallback text
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.moodColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Reason input
                Text(
                  isEditing ? '¿Por qué te sentiste así?' : '¿Por qué te sientes así?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Escribe aquí...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Actualizar nota' : 'Guardar nota',
                            style: const TextStyle(fontSize: 16),
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