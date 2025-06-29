import 'package:flutter/material.dart';
import '../widgets/jar_container.dart';
import 'mood_prompt_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mis emociones')),
      body: Center(
        child: JarContainer(spheres: []),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MoodPromptScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
