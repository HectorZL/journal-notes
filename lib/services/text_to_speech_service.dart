import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _flutterTts.awaitSpeakCompletion(true);
      _isInitialized = true;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final prefs = await SharedPreferences.getInstance();
    final ttsEnabled = prefs.getBool('textToSpeech') ?? false;
    
    if (ttsEnabled && text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  void dispose() {
    _flutterTts.stop();
  }
}

// Provider for the TextToSpeechService
final textToSpeechProvider = TextToSpeechService();
