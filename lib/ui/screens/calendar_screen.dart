import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'note_edit_screen.dart';
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
  Map<DateTime, List<Note>> _events = {};
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild the events map when notes change
    _updateEvents();
  }
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _updateEvents() {
    final notes = ref.read(notesProvider);
    final newEvents = <DateTime, List<Note>>{};
    
    for (final note in notes) {
      final date = DateTime(note.date.year, note.date.month, note.date.day);
      newEvents[date] = [...newEvents[date] ?? [], note];
    }
    
    if (mounted) {
      setState(() {
        _events = newEvents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to notes to trigger rebuilds
    final notes = ref.watch(notesProvider);
    
    // Update events when notes change
    if (notes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateEvents();
      });
    }

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
              return _events[DateTime(date.year, date.month, date.day)] ?? [];
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
          if (_selectedDay != null) _buildEventList(_selectedDay!),
        ],
      ),
    );
  }

  Widget _buildEventList(DateTime day) {
    final events = _events[DateTime(day.year, day.month, day.day)] ?? [];
    
    if (events.isEmpty) {
      return const SizedBox.shrink(); // Return an empty widget when there are no notes
    }

    return Expanded(
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final note = events[index];
          return _buildNoteCard(note);
        },
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
          backgroundColor: _getMoodColor(note.moodIndex).withOpacity(0.2),
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
          // TODO: Implement note editing
          _showNoteDetails(context, note);
        },
      ),
    );
  }

  void _showNoteDetails(BuildContext context, Note note) {
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditScreen(
                            moodIndex: note.moodIndex,
                            moodColor: _getMoodColor(note.moodIndex),
                            noteToEdit: note,
                          ),
                          settings: const RouteSettings(arguments: 'fromCalendar'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Editar nota'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Show delete confirmation
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar nota'),
                          content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Delete the note
                                ref.read(notesProvider.notifier).removeNote(note).then((_) {
                                  if (mounted) {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Close bottom sheet
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Nota eliminada'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                });
                              },
                              child: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
