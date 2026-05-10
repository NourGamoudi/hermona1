import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/features/chat/data/services/chat_api_service.dart';
import 'package:acneia/features/chat/domain/entities/chat_message.dart';
import 'package:acneia/features/questionnaire/domain/entities/user_profile.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';
import 'package:acneia/features/prediction/data/services/prediction_api_service.dart';
import 'package:acneia/features/questionnaire/data/services/questionnaire_service.dart';
import 'package:acneia/core/widgets/common_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String? targetMessageId;
  const ChatScreen({super.key, this.targetMessageId});

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

  bool _scrolledToTarget = false;
  final _targetKey = GlobalKey();
  
  final List<ChatMessage> _msgs = [];
  StreamSubscription<List<ChatMessage>>? _msgSub;
  bool _loading = false;
  bool _typing = false;
  CancelToken? _cancelToken;
  bool _isTranscribing = false;
  final _audioRecorder = AudioRecorder();
  final _tts = FlutterTts();
  bool _isRecording = false;
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
      await _audioRecorder.hasPermission();
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _audioRecorder.dispose();
    _tts.stop();
    _msgSub?.cancel(); // 🔥 CANCEL STREAM
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("fr-FR");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setStartHandler(() => setState(() => _isSpeaking = true));
      _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
      _tts.setPauseHandler(() => setState(() => _isSpeaking = false));
      _tts.setErrorHandler((_) => setState(() => _isSpeaking = false));
      if (mounted) setState(() => _ttsReady = true);
    } catch (_) {}
  }

  Future<void> _stopSpeaking() async {
    if (!_ttsReady) return;
    await _tts.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _handleSpeak(String text) async {
    if (!_ttsReady) return;
    if (_isSpeaking) {
      await _stopSpeaking();
      return;
    }
    await _tts.speak(text);
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _addWelcome();
      return;
    }

    // 🔥 REAL-TIME STREAM (Stable Sync)
    _msgSub = _chatSvc.getMessagesStream(uid).listen((hist) {
      if (mounted && hist.isNotEmpty) {
        setState(() {
          if (hist.length != _msgs.where((m) => m.role != 'system').length) {
            _msgs.clear();
            _msgs.addAll(hist);
          }
        });

        if (widget.targetMessageId != null && !_scrolledToTarget) {
          _scrollToTarget();
        } else {
          _scrollBottom();
        }
      }
    });

    _questionnaireSvc.fetchUserProfile(uid).then((p) {
      if (mounted) setState(() => _profile = p);
    });
    _predictionSvc.getHistory(uid).then((preds) {
      if (mounted && preds.isNotEmpty) setState(() => _prediction = preds.first);
    });
  }

  void _addWelcome() => setState(() => _msgs.add(ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        timestamp: DateTime.now(),
        content: "Bonjour ! Je suis Hermona AI ✨\n\nPosez-moi n'importe quelle question sur votre peau ou votre cycle !\n\nVous pouvez aussi me parler avec le micro !",
      )));

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final path = p.join(directory.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      setState(() => _isTranscribing = true);
      try {
        final text = await _chatSvc.transcribeAudio(path);
        if (!mounted) {
          return;
        }
        if (text.trim().isNotEmpty) {
          _send(text, isVoice: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isTranscribing = false;
          });
        }
      }
    }
  }

  Future<void> _send(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty || _loading) return;
    _textCtrl.clear();
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userMsg = ChatMessage(id: _uuid.v4(), role: 'user', content: text, timestamp: DateTime.now(), isVoice: isVoice);
    
    // 🔥 INSTANT DISPLAY (Optimistic UI)
    setState(() { 
      _msgs.add(userMsg);
      _loading = true; 
      _typing = true; 
    });
    _scrollBottom();

    // Background save
    _chatSvc.saveMessage(userMsg, uid);

    try {
      _cancelToken = CancelToken();
      // Take history from current state
      final historyToSend = List<ChatMessage>.from(_msgs);
      
      final response = await _chatSvc.getChatResponse(
        userMessage: text,
        profile: _profile,
        prediction: _prediction,
        cancelToken: _cancelToken,
        history: historyToSend,
      );

      if (!mounted) return;

      final botMsg = ChatMessage(id: _uuid.v4(), role: 'assistant', content: response, timestamp: DateTime.now());
      
      // Save bot response in background
      _chatSvc.saveMessage(botMsg, uid);

      setState(() {
        _loading = false;
        _typing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _typing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Assistant indisponible : $e")),
      );
    }
    _scrollBottom();
  }

  void _scrollToTarget() {
    Future.delayed(200.ms, () {
      if (mounted && _targetKey.currentContext != null) {
        _scrolledToTarget = true;
        Scrollable.ensureVisible(
          _targetKey.currentContext!,
          duration: 800.ms,
          curve: Curves.easeInOutQuart,
          alignment: 0.5, // Center the message
        );
      }
    });
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: 300.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const FittedBox(fit: BoxFit.scaleDown, child: Text('Assistant Hermona')),
        leadingWidth: 52,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                GoRouter.of(context).go('/home');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
        ),
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: AppColors.primary),
              onPressed: _stopSpeaking,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -50,
            left: -50,
            child: _Blob(size: 200, color: AppTheme.primary.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: 200,
            right: -50,
            child: _Blob(size: 250, color: AppColors.secondary.withValues(alpha: 0.05)),
          ),

          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  cacheExtent: 5000, // Force pre-building of items to make GlobalKey available
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                  itemCount: _msgs.length + (_typing || _isTranscribing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _msgs.length) return const _TypingIndicator();
                    final m = _msgs[index];
                    final isTarget = m.id == widget.targetMessageId;
                    return _ChatBubble(
                      key: isTarget ? _targetKey : null,
                      msg: m, 
                      isTarget: isTarget,
                      onSpeak: () => _handleSpeak(m.content),
                    );
                  },
                ),
              ),

              // Suggestions
              if (_msgs.length <= 1 && !_isRecording)
                _buildSuggestions(),

              _buildInput(size),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => GlassCard(
          onTap: () => _send(_suggestions[i]),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: 50,
          child: Text(
            _suggestions[i],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildInput(Size size) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mic Button
          GestureDetector(
            onLongPress: _startRecording,
            onLongPressUp: _stopRecording,
            child: AnimatedContainer(
              duration: 300.ms,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.error : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (_isRecording) BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Iconsax.microphone_2,
                color: _isRecording ? Colors.white : AppColors.primary,
                size: 26,
              ),
            ),
          ),
          
          const SizedBox(width: 12),

          // Text Input
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              child: TextField(
                controller: _textCtrl,
                maxLines: 5,
                minLines: 1,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Écrivez à Hermona...',
                  hintStyle: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Send Button
          GestureDetector(
            onTap: () => _send(_textCtrl.text),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
                ],
              ),
              child: _loading 
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
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
  final bool isTarget;
  const _ChatBubble({super.key, required this.msg, required this.onSpeak, this.isTarget = false});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Text('✨', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              decoration: isTarget ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
                boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 10)],
              ) : null,
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Text(msg.content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
                  )
                else
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 22,
                    opacity: 0.4, // Slightly more opaque for assistant
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content, 
                          style: TextStyle(
                            fontSize: 15, 
                            height: 1.6, 
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          )
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: onSpeak,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.volume_up_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('ÉCOUTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
        ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: isUser ? 0.1 : -0.1, curve: Curves.easeOut);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          const SizedBox(width: 48),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -5, duration: 400.ms, delay: (i * 150).ms)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])),
    );
  }
}
