import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/services/chat_api_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../../questionnaire/domain/entities/user_profile.dart';
import '../../../prediction/domain/entities/prediction_result.dart';
import '../../../prediction/data/services/prediction_api_service.dart';
import '../../../questionnaire/data/services/questionnaire_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _chatSvc = ChatApiService();
  final _questionnaireSvc = QuestionnaireService();
  final _predictionSvc = PredictionApiService();
  final _uuid = const Uuid();

  final List<ChatMessage> _msgs = [];
  bool _loading = false;
  bool _typing = false;
  CancelToken? _cancelToken;
  bool _isTranscribing = false;
  String? _lastSpokenText;
  bool _isPaused = false;
  int _currentSpeakPosition = 0;

  // Voice & TTS
  final _audioRecorder = AudioRecorder();
  final _tts = FlutterTts();
  bool _isRecording = false;
  bool _autoSpeak = false;
  bool _isSpeaking = false;
  bool _ttsReady = false;

  UserProfile? _profile;
  PredictionResult? _prediction;

  final List<String> _suggestions = [
    "Pourquoi mon risque est élevé aujourd'hui ?",
    "Quels produits éviter avec ma peau ?",
    "Comment gérer l'acné en phase lutéale ?",
    "Quelle routine adopter cette semaine ?",
  ];

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadData();
    _initTts();
  }

  Future<void> _initRecorder() async {
    try {
      debugPrint("🎤 Initializing AudioRecorder...");
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint("🎤 Has permission: $hasPermission");
    } catch (e) {
      debugPrint("❌ Error initializing recorder: $e");
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _audioRecorder.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      debugPrint('TTS: Initializing...');

      await _tts.setLanguage("fr-FR");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setStartHandler(() {
        debugPrint('TTS: Started speaking');
        setState(() => _isSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        debugPrint('TTS: Finished speaking');
        setState(() => _isSpeaking = false);
      });
      _tts.setPauseHandler(() {
        debugPrint('TTS: Paused');
        setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((message) {
        debugPrint('TTS error: $message');
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setProgressHandler((text, start, end, word) {
        _currentSpeakPosition = start;
      });
      if (mounted) setState(() => _ttsReady = true);
      debugPrint('TTS: Ready');
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
      if (mounted) setState(() => _ttsReady = false);
    }
  }

  Future<void> _stopSpeaking() async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    }
  }

  Future<void> _pauseSpeaking() async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = true;
      });
    }
  }

  Future<void> _resumeSpeaking() async {
    if (!_ttsReady || _lastSpokenText == null) return;
    setState(() {
      _isPaused = false;
    });
    // Si on a une position valide, on reprend depuis cette position
    if (_currentSpeakPosition > 0 && _currentSpeakPosition < _lastSpokenText!.length) {
      await _tts.speak(_lastSpokenText!.substring(_currentSpeakPosition));
    } else {
      await _tts.speak(_lastSpokenText!);
    }
  }

  Future<void> _handleSpeak(String text) async {
    _lastSpokenText = text;
    _currentSpeakPosition = 0;
    _isPaused = false;
    debugPrint(
        'TTS: _handleSpeak called with text: "${text.length > 50 ? text.substring(0, 50) : text}..."');
    if (!_ttsReady) {
      debugPrint('TTS: Not ready yet');
      return;
    }

    if (_isSpeaking) {
      debugPrint('TTS: Already speaking, stopping first');
      await _stopSpeaking();
      return;
    }

    debugPrint('TTS: Speaking text');
    await _tts.speak(text);
  }

  Future<void> _toggleAutoSpeak() async {
    final newMode = !_autoSpeak;
    if (mounted) {
      setState(() => _autoSpeak = newMode);
    }
    try {
      await _tts.setVolume(newMode ? 1.0 : 0.0);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _addWelcome();
      return;
    }

    final hist = await _chatSvc.loadHistory(uid);
    if (hist.isEmpty) {
      _addWelcome();
    } else {
      setState(() => _msgs.addAll(hist));
      _scrollBottom();
    }

    _questionnaireSvc
        .fetchUserProfile(uid)
        .then((p) => setState(() => _profile = p));
    _predictionSvc.getHistory(uid).then((preds) {
      if (preds.isNotEmpty) setState(() => _prediction = preds.first);
    });
  }

  void _addWelcome() => setState(() => _msgs.add(ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        timestamp: DateTime.now(),
        content:
            "Bonjour ! Je suis AcnéIA 🌸\n\nPosez-moi n'importe quelle question sur votre peau ou votre cycle !\n\n🎤 Vous pouvez aussi me parler avec le micro !",
      )));

  Future<void> _startRecording() async {
    try {
      debugPrint("🎤 START: Checking permissions...");

      bool hasPermission = await _audioRecorder.hasPermission();
      debugPrint("🎤 Has permission initially: $hasPermission");

      if (!hasPermission && !kIsWeb) {
        debugPrint("🎤 Requesting microphone permission...");
        final status = await Permission.microphone.request();
        debugPrint("🎤 Permission status: ${status.toString()}");
        hasPermission = status.isGranted;
      }

      if (!hasPermission) {
        debugPrint("❌ Microphone permission DENIED");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permission microphone refusée"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      String path = '';
      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        path = p.join(directory.path, 'recording_$timestamp.m4a');
      }

      debugPrint("🎤 Starting recording to: $path");

      try {
        if (kIsWeb) {
          await _audioRecorder.start(const RecordConfig(), path: '');
        } else {
          await _audioRecorder.start(const RecordConfig(), path: path);
        }
        debugPrint("🎤 ✅ Recording STARTED successfully");

        if (mounted) {
          setState(() => _isRecording = true);
        }
      } catch (e) {
        debugPrint("❌ Failed to start recording: $e");
        rethrow;
      }
    } catch (e) {
      debugPrint("❌ ERROR in _startRecording: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      debugPrint("🎤 STOP: Stopping recording...");
      final path = await _audioRecorder.stop();
      debugPrint("🎤 Recording stopped. Path: $path");

      if (mounted) {
        setState(() => _isRecording = false);
      }

      if (path != null && path.isNotEmpty) {
        debugPrint("🎤 Recording file found: $path");
        if (mounted) {
          setState(() => _isTranscribing = true);
        }

        try {
          debugPrint("🎤 Starting transcription...");
          final text = await _chatSvc.transcribeAudio(path);
          debugPrint("🎤 Transcription result: $text");

          if (text.trim().isNotEmpty) {
            debugPrint(
                "🎤 ✅ Sending transcribed text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}");
            _send(text, isVoice: true);
          } else {
            debugPrint("🎤 ⚠️ Empty transcription result");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Aucun son détecté"),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint("❌ Transcription error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erreur transcription: $e"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isTranscribing = false);
          }
        }
      } else {
        debugPrint("❌ No recording file found");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aucun enregistrement trouvé"),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ ERROR in _stopRecording: $e");
      if (mounted) {
        setState(() => _isRecording = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _send(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty || _loading) return;

    _textCtrl.clear();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
      isVoice: isVoice,
    );

    setState(() {
      _msgs.add(userMsg);
      _loading = true;
      _typing = true;
    });
    _scrollBottom();

    if (uid != null) {
      try {
        await _chatSvc.saveMessage(userMsg, uid);
      } catch (e) {
        debugPrint('Failed to save user message: $e');
      }
    }

    _cancelToken = CancelToken();

    try {
      final reply = await _chatSvc.getResponse(
        history: _msgs,
        userMessage: text,
        profile: _profile,
        prediction: _prediction,
        cancelToken: _cancelToken,
      );

      final botMsg = ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      );

      setState(() {
        _msgs.add(botMsg);
        _loading = false;
        _typing = false;
      });

      if (uid != null) {
        try {
          await _chatSvc.saveMessage(botMsg, uid);
        } catch (e) {
          debugPrint('Failed to save bot message: $e');
        }
      }
      _scrollBottom();

      if (_autoSpeak || isVoice) {
        debugPrint(
            'TTS: Auto speak enabled or voice input, calling _handleSpeak');
        await _handleSpeak(reply);
      } else {
        debugPrint('TTS: Auto speak disabled and not voice input');
      }
    } catch (e) {
      if (e.toString().contains("Annulé par l'utilisateur")) {
        setState(() {
          _loading = false;
          _typing = false;
        });
        debugPrint('Chat request cancelled by user');
        return;
      }
      
      setState(() {
        _loading = false;
        _typing = false;
      });
      debugPrint('Chat error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur de chat : ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _scrollBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    String statusText = _isRecording
        ? "🔴 Enregistrement..."
        : (_isTranscribing
            ? "Transcription..."
            : (_isSpeaking
                ? "🔊 AcnéIA parle..."
                : (_typing ? "En train d'écrire..." : "En ligne")));

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AcnéIA',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                Text(statusText,
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ],
        ),
        actions: [
          // Toggle Auto-Speak
          IconButton(
            tooltip: _autoSpeak ? 'Désactiver la lecture auto' : 'Activer la lecture auto',
            icon: Icon(
              _autoSpeak ? Iconsax.volume_high : Iconsax.volume_cross,
              color: _autoSpeak
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            onPressed: _toggleAutoSpeak,
          ),
          // Pause / Play / Replay buttons
          if (_isSpeaking)
            IconButton(
              tooltip: 'Mettre en pause',
              icon: Icon(
                Icons.pause_circle_filled_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: _pauseSpeaking,
            )
          else if (_isPaused)
            IconButton(
              tooltip: 'Reprendre la lecture',
              icon: Icon(
                Icons.play_circle_filled_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: _resumeSpeaking,
            ),
          if (_lastSpokenText != null && !_isSpeaking)
            IconButton(
              tooltip: 'Recommencer depuis le début',
              icon: Icon(
                Icons.replay_circle_filled_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: () => _handleSpeak(_lastSpokenText!),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length + (_typing || _isTranscribing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _msgs.length) return const _TypingIndicator();
                final msg = _msgs[index];
                return _ChatBubble(
                    msg: msg,
                    onSpeak: () {
                      debugPrint(
                          'TTS: Listen button tapped for message: ${msg.content.substring(0, min(30, msg.content.length))}...');
                      _handleSpeak(msg.content);
                    });
              },
            ),
          ),
          if (_isRecording)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(Icons.mic, color: theme.colorScheme.error, size: 18)
                      .animate(onPlay: (c) => c.repeat())
                      .scale(duration: 800.ms)
                      .then()
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1)),
                  const SizedBox(width: 10),
                  Text("Je vous écoute... Relâchez pour envoyer",
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                ],
              ),
            ),
          if (_msgs.length <= 1 && !_isRecording)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => InkWell(
                  onTap: () => _send(_suggestions[i]),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3))),
                    child: Text(_suggestions[i],
                        style: TextStyle(
                            color: theme.colorScheme.primary, fontWeight: FontWeight.w500, fontSize: 12)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: () {
              debugPrint("🎤 LONG PRESS DETECTED!");
              _startRecording();
            },
            onLongPressUp: () {
              debugPrint("🎤 LONG PRESS RELEASED!");
              _stopRecording();
            },
            onTap: _isRecording
                ? () {
                    debugPrint("🎤 TAP DETECTED!");
                    _stopRecording();
                  }
                : null,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: _isRecording
                    ? LinearGradient(
                        colors: [theme.colorScheme.error, theme.colorScheme.error.withOpacity(0.8)])
                    : LinearGradient(
                        colors: [theme.colorScheme.primary.withOpacity(0.1), theme.colorScheme.primary.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _isRecording
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Icon(
                  _isRecording ? Icons.stop_rounded : Iconsax.microphone_2,
                  color: _isRecording ? Colors.white : theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor)),
              child: TextField(
                controller: _textCtrl,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                    hintText: 'Posez une question...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none),
                enabled: !_isRecording && !_isTranscribing,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _loading
                ? () {
                    _cancelToken?.cancel("Annulé par l'utilisateur");
                  }
                : () => _send(_textCtrl.text),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: _loading
                    ? LinearGradient(colors: [theme.colorScheme.error, theme.colorScheme.error.withOpacity(0.8)])
                    : _textCtrl.text.trim().isNotEmpty
                        ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])
                        : LinearGradient(colors: [theme.colorScheme.surface, theme.colorScheme.surface]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _loading
                      ? theme.colorScheme.error
                      : _textCtrl.text.trim().isNotEmpty
                          ? Colors.transparent
                          : theme.dividerColor,
                ),
              ),
              child: Icon(
                _loading ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                color: _loading || _textCtrl.text.trim().isNotEmpty
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onSpeak;
  const _ChatBubble({required this.msg, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
                margin: const EdgeInsets.only(top: 4),
                child: const Text('🌸', style: TextStyle(fontSize: 18))),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16)),
                    border: Border.all(
                        color: isUser
                            ? theme.colorScheme.primary.withOpacity(0.3)
                            : theme.dividerColor),
                  ),
                  child: Text(msg.content,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface, fontSize: 14, height: 1.5)),
                ),
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: InkWell(
                        onTap: onSpeak,
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_up,
                                  size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text("Écouter",
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 10))
                            ])),
                  ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: isUser ? 0.1 : -0.1),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Text('🌸', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
              width: 30,
              height: 10,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                      3,
                      (i) => Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                              begin: 0,
                              end: -4,
                              duration: Duration(milliseconds: 300),
                              delay: Duration(milliseconds: i * 100))))),
        ),
      ],
    );
  }
}