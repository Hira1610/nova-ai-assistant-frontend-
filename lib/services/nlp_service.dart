import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class NLPService {
  // 1. Singleton Pattern (Sirf aik baar memory mein banega)
  static final NLPService _instance = NLPService._internal();
  factory NLPService() => _instance;
  NLPService._internal();

  Interpreter? _interpreter;
  Map<String, dynamic>? _dictionary;
  List<String>? _labels;
  bool _isReady = false;

  bool get isReady => _isReady;

  // 2. Optimized Initialization (Parallel Loading)
  Future<void> initModel() async {
    if (_isReady) return; // Agar pehle se load hai to dobara mehnat na kare

    try {
      // Future.wait sab files ko aik sath load karega (Fast Startup)
      final results = await Future.wait([
        Interpreter.fromAsset('assets/models/urdu_intent_model.tflite'),
        rootBundle.loadString('assets/models/dictionary.json'),
        rootBundle.loadString('assets/models/labels.txt'),
      ]);

      // Assigning results
      _interpreter = results[0] as Interpreter;
      _dictionary = json.decode(results[1] as String);

      String labelsRaw = results[2] as String;
      _labels = labelsRaw.split('\n')
          .map((e) => e.trim()) // Extra spaces safai
          .where((s) => s.isNotEmpty)
          .toList();

      _isReady = true;
      print("✅ NLP Engine Started Successfully!");
    } catch (e) {
      print("❌ Error initializing NLP: $e");
    }
  }

  // 3. Smart Tokenization (Regex for Cleanup)
  List<double> _tokenize(String text) {
    if (_dictionary == null) return List.filled(20, 0.0);

    // Punctuation hatana zaroori hai (e.g., "do." -> "do")
    String cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    List<String> words = cleanText.split(' ');

    // Fixed size buffer (20 inputs)
    List<double> sequence = List.filled(20, 0.0);

    for (int i = 0; i < words.length && i < 20; i++) {
      String word = words[i];
      if (_dictionary!.containsKey(word)) {
        sequence[i] = (_dictionary![word] as num).toDouble();
      } else {
        sequence[i] = 1.0; // <OOV> Unknown word
      }
    }
    return sequence;
  }

  // 4. Safe Prediction
  String predictIntent(String text) {
    if (!_isReady || _interpreter == null) return "Model Loading...";

    try {
      // Input & Output buffers
      var input = [_tokenize(text)];
      var output = List<double>.filled(_labels!.length, 0).reshape([1, _labels!.length]);

      // Run Inference
      _interpreter!.run(input, output);

      // Find Max Score (Argmax)
      List<double> probabilities = output[0];
      double maxScore = -1;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxScore) {
          maxScore = probabilities[i];
          maxIndex = i;
        }
      }

      // Confidence check (Optional: Agar yaqeen kam ho to ignore karein)
      if (maxScore < 0.5) return "NOT_SURE";

      return _labels![maxIndex];
    } catch (e) {
      print("❌ Prediction Error: $e");
      return "ERROR";
    }
  }

  // 5. Memory Cleanup
  void dispose() {
    _interpreter?.close();
    _isReady = false;
  }
}