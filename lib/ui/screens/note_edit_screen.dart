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
  final Note? noteToEdit;
  
  const NoteEditScreen({
    Key? key,
    required this.initialMoodIndex,
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
  late int _currentMoodIndex;

  @override
  void initState() {
    super.initState();
    _currentMoodIndex = widget.initialMoodIndex;
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
      
      // Get current user ID from auth provider
      final auth = ref.read(authProvider);
      final userId = int.tryParse(auth.userId ?? '');
      
      if (userId == null) {
        throw Exception('No se pudo obtener el ID de usuario válido');
      }
      
      // Create the updated note
      final note = Note(
        id: widget.noteToEdit?.id,
        userId: userId,
        content: _controller.text.trim(),
        moodIndex: _currentMoodIndex,
        date: widget.noteToEdit?.date ?? now,
        color: widget.noteToEdit?.color ?? Colors.blue,
      );

      // Get the notes notifier
      final notesNotifier = ref.read(notesProvider.notifier);
      
      // Save to database
      if (isEditing) {
        await notesNotifier.updateNote(note);
      } else {
        await notesNotifier.addNote(note);
      }
      
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
        await ref.read(notesProvider.notifier).deleteNote(widget.noteToEdit!);
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate note was deleted
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final weatherIcons = [
      Icons.wb_sunny,  // Sunny
      Icons.wb_cloudy,  // Partly Cloudy
      Icons.cloud,      // Cloudy
      Icons.grain,     // Rainy
      Icons.thunderstorm, // Stormy
    ];
    
    final weatherDescriptions = [
      '¡Soleado!',
      'Parcialmente nublado',
      'Nublado',
      'Lluvioso',
      'Tormentoso'
    ];
    
    final weatherColors = [
      Colors.orange,
      Colors.blueGrey[400]!,
      Colors.grey[600]!,
      Colors.blue[400]!,
      Colors.deepPurple[400]!,
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
                        SizedBox(
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: List.generate(
                              weatherIcons.length,
                              (index) => Positioned(
                                left: index * 70.0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _currentMoodIndex = index),
                                  child: _FloatingWeatherIcon(
                              icon: weatherIcons[index],
                                    isSelected: _currentMoodIndex == index,
                              color: weatherColors[index],
                              index: index,
                            ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weatherDescriptions[_currentMoodIndex],
                          style: TextStyle(
                            fontSize: 16,
                            color: weatherColors[_currentMoodIndex],
                            fontWeight: FontWeight.w600,
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