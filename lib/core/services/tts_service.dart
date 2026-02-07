import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for Text-to-Speech using Google TTS for Japanese pronunciation
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentWord;

  /// Callback when speaking starts
  VoidCallback? onSpeakingStart;

  /// Callback when speaking completes
  VoidCallback? onSpeakingComplete;

  /// Initialize TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();

      // Set Japanese language
      await _flutterTts!.setLanguage('ja-JP');

      // Set speech parameters
      await _flutterTts!.setSpeechRate(0.5); // Slower for learning
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      // Set handlers
      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingStart?.call();
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        _currentWord = null;
        onSpeakingComplete?.call();
      });

      _flutterTts!.setErrorHandler((message) {
        debugPrint('TTS Error: $message');
        _isSpeaking = false;
        _currentWord = null;
        onSpeakingComplete?.call();
      });

      _flutterTts!.setCancelHandler(() {
        _isSpeaking = false;
        _currentWord = null;
        onSpeakingComplete?.call();
      });

      _isInitialized = true;
      debugPrint('TTS Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize TTS: $e');
    }
  }

  /// Check if TTS is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Get the word currently being spoken
  String? get currentWord => _currentWord;

  /// Speak a Japanese word
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_flutterTts == null) {
      debugPrint('TTS not available');
      return;
    }

    // Stop any current speech
    if (_isSpeaking) {
      await stop();
    }

    _currentWord = text;
    await _flutterTts!.speak(text);
  }

  /// Stop speaking
  Future<void> stop() async {
    if (_flutterTts != null && _isSpeaking) {
      await _flutterTts!.stop();
      _isSpeaking = false;
      _currentWord = null;
    }
  }

  /// Dispose TTS resources
  Future<void> dispose() async {
    await stop();
    _flutterTts = null;
    _isInitialized = false;
  }

  /// Check if a specific word is currently being spoken
  bool isWordSpeaking(String word) => _isSpeaking && _currentWord == word;
}
