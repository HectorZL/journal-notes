import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/note.dart';
import '../../state/providers/providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    
    // Group notes by date
    final Map<DateTime, List<Note>> events = {};
    for (final note in notes) {
      final date = DateTime(note.date.year, note.date.month, note.date.day);
      events[date] = [...events[date] ?? [], note];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Estados de Ánimo'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
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
          return events[DateTime(date.year, date.month, date.day)] ?? [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              final note = events.first as Note;
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
