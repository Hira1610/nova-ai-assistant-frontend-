import 'dart:convert';
import 'dart:typed_data'; // 🔥 Fast processing ke liye
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class NLPService {
  static final NLPService _instance = NLPService._internal();
  factory NLPService() => _instance;
  NLPService._internal();

  Interpreter? _interpreter;
  Map<String, dynamic>? _dictionary;
  List<String>? _labels;
  bool _isReady = false;

  // Model input size (Jitna training ke waqt rakha tha, e.g., 20)
  static const int _inputLength = 20;

  bool get isReady => _isReady;

  Future<void> initModel() async {
    if (_isReady) return;

    try {
      // Asset paths check karlein ke 'models' hai ya 'model'
      final results = await Future.wait([
        Interpreter.fromAsset('assets/model/intent_model.tflite'),
        rootBundle.loadString('assets/model/tokenizer.json'),
        rootBundle.loadString('assets/model/labels.json'),
      ]);

      _interpreter = results[0] as Interpreter;
      _dictionary = json.decode(results[1] as String);

      // Label parsing (Handle both JSON list and Newline text)
      String labelsRaw = results[2] as String;
      if (labelsRaw.startsWith('[')) {
        _labels = List<String>.from(json.decode(labelsRaw));
      } else {
        _labels = labelsRaw.split('\n')
            .map((e) => e.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      _isReady = true;
      print("🧠 JARVIS NLP: Engine Optimized & Ready!");
    } catch (e) {
      print("❌ JARVIS NLP Error: $e");
    }
  }

  // 🔥 Optimized Tokenization using Float32List
  Float32List _tokenize(String text) {
    var sequence = Float32List(_inputLength);
    if (_dictionary == null) return sequence;

    // Safai: Remove Punctuation & Lowercase
    String cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    List<String> words = cleanText.split(RegExp(r'\s+'));

    for (int i = 0; i < words.length && i < _inputLength; i++) {
      String word = words[i];
      // Tokenizer ID fetch: Word na mile to 1 (OOV) ya 0
      sequence[i] = (_dictionary![word] ?? 1).toDouble();
    }
    return sequence;
  }

  String predictIntent(String text) {
    if (!_isReady || _interpreter == null || _labels == null) return "loading";

    try {
      // 1. Prepare Input (Shape: [1, 20])
      var input = _tokenize(text).reshape([1, _inputLength]);

      // 2. Prepare Output (Shape: [1, total_labels])
      var output = List<double>.filled(_labels!.length, 0).reshape([1, _labels!.length]);

      // 3. Run Inference
      _interpreter!.run(input, output);

      // 4. Extract Results
      List<double> probabilities = List<double>.from(output[0]);

      double maxScore = -1.0;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxScore) {
          maxScore = probabilities[i];
          maxIndex = i;
        }
      }

      // 🔥 Confidence Threshold: Agar 40% se kam sure ho to ignore karein
      if (maxScore < 0.4) {
        print("⚠️ Low Confidence: ${maxScore.toStringAsFixed(2)} - Intent: ${_labels![maxIndex]}");
        return "uncertain";
      }

      return _labels![maxIndex];
    } catch (e) {
      print("❌ Inference Error: $e");
      return "error";
    }
  }

  void dispose() {
    _interpreter?.close();
    _isReady = false;
  }
}