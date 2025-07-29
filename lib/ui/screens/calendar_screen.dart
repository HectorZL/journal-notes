import 'package:flutter/material.dart';
import 'package:notas_animo/providers/auth_provider.dart';
import 'package:notas_animo/ui/screens/note_edit_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';
import '../../state/providers/providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUserNotes();
  }

  Future<void> _loadUserNotes() async {
    try {
      final authState = ref.read(authProvider);
      final userId = authState.userIdAsInt;
      
      if (userId == null || userId <= 0) {
        debugPrint('Error: Invalid user ID: $userId');
        return;
      }
      
      debugPrint('Loading notes for user ID: $userId');
      await ref.read(notesProvider.notifier).setCurrentUser(userId);
    } catch (e, stackTrace) {
      debugPrint('Error loading user notes: $e\n$stackTrace');
    }
  }

  Map<DateTime, List<Note>> _getEventsForCalendar(DateTime first, DateTime last) {
    final events = <DateTime, List<Note>>{};
    final notesAsync = ref.watch(notesProvider);

    if (notesAsync is! AsyncData) {
      return events;
    }

    final notes = notesAsync.asData?.value ?? [];

    for (final note in notes) {
      final date = DateTime(note.date.year, note.date.month, note.date.day);

      if (date.isAfter(first.subtract(const Duration(days: 1))) &&
          date.isBefore(last.add(const Duration(days: 1)))) {
        events[date] = [...events[date] ?? [], note];
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        children: [
          TableCalendar<Note>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarFormat: _calendarFormat,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (date) {
              return _getEventsForCalendar(
                date.year == _focusedDay.year && date.month == _focusedDay.month
                    ? _focusedDay
                    : date,
                date.year == _focusedDay.year && date.month == _focusedDay.month
                    ? _focusedDay.add(const Duration(days: 31))
                    : date.add(const Duration(days: 31)),
              )[DateTime(date.year, date.month, date.day)] ??
                  [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final note = events.first;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getMoodColor(note.moodIndex),
                    ),
                    width: 8,
                    height: 8,
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null) _buildNotesList(),
        ],
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: const Text('CALENDARIO DE ESTADOS DE ÁNIMO', 
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: _handleClearAllNotes,
          tooltip: 'Eliminar todas las notas',
        ),
      ],
    );
  }

  Future<void> _handleClearAllNotes() async {
    final userId = ref.read(authProvider).userId;
    final userIdInt = int.tryParse(userId ?? '');
    
    if (userIdInt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor inicia sesión para eliminar notas'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar todas las notas'),
          content: const Text('¿Estás seguro de que deseas eliminar todas las notas? Esta acción no se puede deshacer.'),
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

      if (confirmed == true) {
        await ref.read(notesProvider.notifier).clearNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todas las notas han sido eliminadas'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar las notas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error clearing notes: $e');
    }
  }

  Widget _buildNotesList() {
    final notesAsync = ref.watch(notesProvider);

    return notesAsync.when(
      data: (allNotes) {
        final notes = allNotes
            .where((note) => isSameDay(note.date, _selectedDay))
            .toList();

        if (notes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'NO HAY NOTAS PARA ESTA FECHA',
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
            itemCount: notes.length,
            itemBuilder: (context, index) => _buildNoteCard(notes[index]),
          ),
        );
      },
      loading: () => const Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              const Text('CARGANDO NOTAS...', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'ERROR AL CARGAR LAS NOTAS',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().split(':').last.trim(),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(notesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
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

  Widget _buildNoteCard(Note note) {
    final moodEmojis = ['😄', '🙂', '😐', '🙁', '😞'];
    final moodDescriptions = ['EXCELENTE', 'BIEN', 'NEUTRAL', 'NO MUY BIEN', 'MAL'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMoodColor(note.moodIndex).withValues(alpha: 51),
          child: Text(
            moodEmojis[note.moodIndex].toUpperCase(),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          moodDescriptions[note.moodIndex].toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: note.content.isNotEmpty
            ? Text(note.content.toUpperCase())
            : Text(
                'SIN DESCRIPCIÓN'.toUpperCase(),
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
        trailing: Text(
          DateFormat('HH:mm').format(note.date),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DETALLES DE LA NOTA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ESTADO DE ÁNIMO: ${['EXCELENTE', 'BIEN', 'NEUTRAL', 'NO MUY BIEN', 'MAL'][note.moodIndex].toUpperCase()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HORA: ${DateFormat('HH:mm').format(note.date).toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (note.content.isNotEmpty) ...[
                    Text(
                      'NOTA:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(note.content.toUpperCase(), style: const TextStyle(letterSpacing: 0.3)),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                          // Navigate to edit screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteEditScreen(
                                initialMoodIndex: note.moodIndex,
                                moodColor: _getMoodColor(note.moodIndex),
                                moodDescription: ['EXCELENTE', 'BIEN', 'NEUTRAL', 'NO MUY BIEN', 'MAL'][note.moodIndex],
                                moodEmoji: ['😄', '🙂', '😐', '🙁', '😞'][note.moodIndex],
                                noteToEdit: note,
                              ),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 4),
                            Text('EDITAR', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close confirmation dialog
                          
                          if (note.id == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error: No se puede eliminar la nota. ID no válido.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          try {
                            final notesNotifier = ref.read(notesProvider.notifier);
                            await notesNotifier.deleteNote(note.id!);
                            
                            if (mounted) {
                              // Refresh the notes after successful deletion
                              await ref.refresh(notesProvider);
                               
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nota eliminada correctamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error deleting note: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al eliminar la nota: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getMoodColor(int moodIndex) {
    const colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];
    return colors[moodIndex % colors.length];
  }
}
