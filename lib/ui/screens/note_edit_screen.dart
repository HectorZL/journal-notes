import 'package:flutter/material.dart';
import 'home_screen.dart';

class NoteEditScreen extends StatefulWidget {
  final int moodIndex;
  NoteEditScreen({required this.moodIndex});

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva nota')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Estado: ${widget.moodIndex}'),
            TextField(controller: _controller, decoration: InputDecoration(labelText: 'Nota')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Guardar nota en base de datos
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen()),
                );
              },
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
