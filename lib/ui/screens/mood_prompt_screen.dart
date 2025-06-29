import 'package:flutter/material.dart';
import 'note_edit_screen.dart';

class MoodPromptScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moods = ['😄','🙂','😐','🙁','😞'];
    return Scaffold(
      appBar: AppBar(title: Text('¿Cómo te sientes hoy?')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            moods.length,
            (i) => IconButton(
              icon: Text(moods[i], style: TextStyle(fontSize: 32)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteEditScreen(moodIndex: i),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
