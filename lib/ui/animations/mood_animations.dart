import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/note.dart';

// Constants for mood-related data
const List<Color> moodColors = [
  Colors.green,
  Colors.lightGreen,
  Colors.yellow,
  Colors.orange,
  Colors.red,
];

const List<String> moodEmojis = ['😄', '🙂', '😐', '🙁', '😞'];

class MoodEmojiDisplay extends StatelessWidget {
  final List<Note> notes;
  final Function(Note) onNoteTap;
  final bool isDeleting;

  const MoodEmojiDisplay({
    Key? key,
    required this.notes,
    required this.onNoteTap,
    this.isDeleting = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          final moodIndex = note.moodIndex.clamp(0, moodEmojis.length - 1);
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GestureDetector(
                      onTap: () => onNoteTap(note),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isDeleting 
                              ? Colors.red.withValues(alpha: 51)
                              : moodColors[moodIndex].withValues(alpha: 51),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isDeleting 
                                ? Colors.red
                                : moodColors[moodIndex],
                            width: 2,
                          ),
                        ),
                        child: Text(
                          moodEmojis[moodIndex],
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
