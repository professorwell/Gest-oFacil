// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  void init() {
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
  }

  void startListening(Function(String) onResult) async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (val) {
        onResult(val.recognizedWords);
      });
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> speak(String texto) async {
    await _tts.speak(texto);
  }
}
