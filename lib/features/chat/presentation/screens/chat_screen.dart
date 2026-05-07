import 'dart:io';
import 'dart:math';
import 'dart:ui';
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
import '../../../../core/widgets/common_widgets.dart';

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

    final hist = await _chatSvc.loadHistory(uid);
    if (hist.isEmpty) {
      _addWelcome();
    } else {
      setState(() => _msgs.addAll(hist));
      _scrollBottom();
    }

    _questionnaireSvc.fetchUserProfile(uid).then((p) => setState(() => _profile = p));
    _predictionSvc.getHistory(uid).then((preds) {
      if (preds.isNotEmpty) setState(() => _prediction = preds.first);
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
        if (text.trim().isNotEmpty) _send(text, isVoice: true);
      } finally {
        setState(() => _isTranscribing = false);
      }
    }
  }

  Future<void> _send(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty || _loading) return;
    _textCtrl.clear();
    final userMsg = ChatMessage(id: _uuid.v4(), role: 'user', content: text, timestamp: DateTime.now(), isVoice: isVoice);
    setState(() { _msgs.add(userMsg); _loading = true; _typing = true; });
    _scrollBottom();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await _chatSvc.saveMessage(userMsg, uid);

    try {
      _cancelToken = CancelToken();
      final historyToSend = _msgs.take(_msgs.length - 1).toList();
      
      final response = await _chatSvc.getChatResponse(
        userMessage: text,
        profile: _profile,
        prediction: _prediction,
        cancelToken: _cancelToken,
        history: historyToSend,
      );
      final botMsg = ChatMessage(id: _uuid.v4(), role: 'assistant', content: response, timestamp: DateTime.now());
      if (mounted) {
        setState(() { _msgs.add(botMsg); _loading = false; _typing = false; });
        if (uid != null) await _chatSvc.saveMessage(botMsg, uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _typing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Désolé, une erreur est survenue. Réessayez bientôt.")),
        );
      }
    }
    _scrollBottom();
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: 400.ms, curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Assistant Hermona'),
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
          Positioned(
            top: -100,
            left: -50,
            child: _Blob(size: 300, color: AppColors.primary.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 200,
            right: -50,
            child: _Blob(size: 300, color: AppColors.secondary.withOpacity(0.08)),
          ),

          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                  itemCount: _msgs.length + (_typing || _isTranscribing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _msgs.length) return const _TypingIndicator();
                    return _ChatBubble(
                      msg: _msgs[index], 
                      onSpeak: () => _handleSpeak(_msgs[index].content),
                      isLast: index == _msgs.length - 1,
                    );
                  },
                ),
              ),

              if (_msgs.length <= 1 && !_isRecording)
                _buildSuggestions(isDark),

              _buildInput(isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => GlassCard(
          onTap: () => _send(_suggestions[i]),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          borderRadius: 50,
          child: Text(
            _suggestions[i],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildInput(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: _startRecording,
            onLongPressUp: _stopRecording,
            child: AnimatedContainer(
              duration: 300.ms,
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.error : AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (_isRecording ? AppColors.error : AppColors.primary).withOpacity(0.2)),
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Iconsax.microphone_2,
                color: _isRecording ? Colors.white : AppColors.primary,
                size: 26,
              ),
            ),
          ).animate(onPlay: (c) => _isRecording ? c.repeat(reverse: true) : c.stop())
            .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 800.ms),
          
          const SizedBox(width: 12),

          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              child: TextField(
                controller: _textCtrl,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Posez une question...',
                  hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: () => _send(_textCtrl.text),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
              ),
              child: _loading 
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                  : const Icon(Iconsax.send_1, color: Colors.white, size: 24),
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
  final bool isLast;
  const _ChatBubble({required this.msg, required this.onSpeak, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('✨', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isUser)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Text(msg.content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w600)),
                  )
                else
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.content, style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: onSpeak,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.volume_high, size: 14, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('ÉCOUTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          const SizedBox(width: 48),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            borderRadius: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -6, duration: 450.ms, delay: (i * 150).ms)),
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
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])),
    );
  }
}
