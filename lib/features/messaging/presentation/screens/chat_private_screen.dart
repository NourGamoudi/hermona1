import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/features/messaging/data/services/messaging_service.dart';

class ChatPrivateScreen extends StatefulWidget {
  final String conversationId;
  const ChatPrivateScreen({super.key, required this.conversationId});

  @override State<ChatPrivateScreen> createState() => _ChatPrivateScreenState();
}

class _ChatPrivateScreenState extends State<ChatPrivateScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _svc = MessagingService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  bool _sending = false;

  @override 
  void dispose() { 
    _msgCtrl.dispose(); 
    _scrollCtrl.dispose(); 
    super.dispose(); 
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    await _svc.sendMessage(convId: widget.conversationId, content: text);
    _scrollBottom();
    setState(() => _sending = false);
  }

  void _scrollBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: 300.ms, curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            _AnonymAvatar(seed: widget.conversationId, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.translate('chat_private_title'), 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -100,
            left: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withValues(alpha: 0.05)),
          ),

          Column(
            children: [
              const SizedBox(height: 100),
              // Warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                color: AppColors.warning.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    const Icon(Iconsax.shield_tick, size: 14, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.translate('personal_data_forbidden'), style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _svc.getMessages(widget.conversationId),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!.docs;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());
                    
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.message_text, size: 48, color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(l.translate('say_hello'), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondaryDark)),
                          ],
                        ),
                      ).animate().fadeIn();
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(24),
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final isMe = d['senderId'] == _uid;
                        final date = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now();
                        
                        return _MessageBubble(
                          content: d['content'] ?? '',
                          isMe: isMe,
                          date: timeago.format(date, locale: l.locale.languageCode),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  borderRadius: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          maxLines: 4,
                          minLines: 1,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(hintText: l.translate('your_message_hint'), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: _sending 
                              ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                              : const Icon(Iconsax.send_1, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String date;
  const _MessageBubble({required this.content, required this.isMe, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const _AnonymAvatar(seed: 'other', size: 32),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]) : null,
                color: isMe ? null : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 6),
                  Text(date, style: TextStyle(color: (isMe ? Colors.white : AppColors.textSecondaryDark).withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideX(begin: isMe ? 0.1 : -0.1),
    );
  }
}

class _AnonymAvatar extends StatelessWidget {
  final String seed;
  final double size;
  const _AnonymAvatar({required this.seed, this.size = 40});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondary.withValues(alpha: 0.4), AppColors.primary.withValues(alpha: 0.4)]),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(child: Icon(Iconsax.user, color: Colors.white, size: size * 0.4)),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}
