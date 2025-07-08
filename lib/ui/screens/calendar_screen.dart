import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('Calendario de Estados de Ánimo'),
      ),
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
                    'No hay notas para esta fecha',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
              Text('Cargando notas...'),
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
                const Text(
                  'Error al cargar las notas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  label: const Text('Reintentar'),
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
    final moodDescriptions = ['Excelente', 'Bien', 'Neutral', 'No muy bien', 'Mal'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMoodColor(note.moodIndex).withValues(alpha: 51),
          child: Text(
            moodEmojis[note.moodIndex],
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          moodDescriptions[note.moodIndex],
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: note.content.isNotEmpty
            ? Text(note.content)
            : Text(
                'Sin descripción',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).hintColor,
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
                        'Detalles de la nota',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estado de ánimo: ${['Excelente', 'Bien', 'Neutral', 'No muy bien', 'Mal'][note.moodIndex]}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hora: ${DateFormat('HH:mm').format(note.date)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (note.content.isNotEmpty) ...[
                    Text(
                      'Nota:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(note.content),
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
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const VerticalDivider(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the details dialog
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Eliminar nota'),
                                content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context); // Close confirmation dialog
                                      try {
                                        final notesNotifier = ref.read(notesProvider.notifier);
                                        await notesNotifier.deleteNote(note);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Nota eliminada correctamente'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error al eliminar la nota: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Eliminar'),
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
