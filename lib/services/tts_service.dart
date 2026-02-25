import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  // 1. Singleton Pattern (Memory Leak se bachata hai)
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Getters to check status
  bool get isSpeaking => _isSpeaking;

  /// **Initialization Function (App Start par call karein)**
  Future<void> init() async {
    try {
      if (Platform.isIOS) {
        // iOS: Music bajta rahe, bas halka ho jaye (DuckOthers)
        await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.duckOthers,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            ]
        );
      }

      // Android: Google TTS Engine force karein (Best Quality ke liye)
      if (Platform.isAndroid) {
        var engines = await _flutterTts.getEngines;
        if (engines.contains('com.google.android.tts')) {
          await _flutterTts.setEngine('com.google.android.tts');
        }
      }

      // 2. Language Setup with Fallback
      bool isUrduAvailable = await _flutterTts.isLanguageAvailable("ur-PK");

      if (isUrduAvailable) {
        await _flutterTts.setLanguage("ur-PK");
      } else {
        // Agar PK wali Urdu nahi mili, toh Indian Urdu try karein
        bool isUrduIN = await _flutterTts.isLanguageAvailable("ur-IN");
        if (isUrduIN) {
          await _flutterTts.setLanguage("ur-IN");
        } else {
          print("⚠️ Urdu Language not found! Fallback to English.");
          await _flutterTts.setLanguage("en-US"); // Bilkul chup rehne se behtar hai English bole
        }
      }

      // 3. Voice Settings
      await _flutterTts.setPitch(1.0);       // Normal Pitch
      await _flutterTts.setSpeechRate(0.5);  // Thora slow aur clear
      await _flutterTts.setVolume(1.0);      // Full Volume

      // Ye bohot zaroori hai taake 'await speak()' speech khatam hone ka wait kare
      await _flutterTts.awaitSpeakCompletion(true);

      // 4. Listeners (UI Updates ke liye)
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        print("🗣️ NOVA started speaking...");
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        print("✅ NOVA finished speaking.");
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        print("❌ TTS Error: $msg");
      });

      print("✅ TTS Service Initialized (Pro Mode)");

    } catch (e) {
      print("❌ TTS Init Error: $e");
    }
  }

  /// **Smart Speak Function**
  Future<void> speak(String message) async {
    if (message.trim().isEmpty) return;

    // Agar pehle kuch bol raha hai to usay chup karayein (Interrupt)
    // Assistant style mein purani baat katna zaroori hota hai
    if (_isSpeaking) {
      await stop();
    }

    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print("❌ Error Speaking: $e");
    }
  }

  /// **Stop Function (Screen chorne par call karein)**
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print("❌ Error Stopping: $e");
    }
  }
}