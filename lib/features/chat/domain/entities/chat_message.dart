import 'package:equatable/equatable.dart';





// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// DOMAIN ”“ Chat Entities & Repository

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ChatMessage extends Equatable {

  final String id;

  final String role;      // 'user' | 'assistant'

  final String content;

  final DateTime timestamp;

  final bool isVoice;

  final String? audioUrl;



  const ChatMessage({

    required this.id,

    required this.role,

    required this.content,

    required this.timestamp,

    this.isVoice = false,

    this.audioUrl,

  });



  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(

    id       : j['id']        as String,

    role     : j['role']      as String,

    content  : j['content']   as String,

    timestamp: DateTime.parse(j['timestamp'] as String),

    isVoice  : j['isVoice']   as bool? ?? false,

    audioUrl : j['audioUrl']  as String?,

  );



  Map<String, dynamic> toJson() => {

    'id': id, 'role': role,

    'content': content, 'timestamp': timestamp.toIso8601String(),

    'isVoice': isVoice, 'audioUrl': audioUrl,

  };



  @override

  List<Object?> get props => [id];

}








