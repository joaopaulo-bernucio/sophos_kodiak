import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/chat_message.dart';

class ChatHistoryService {
  static final Logger _logger = Logger();
  static const String _historyKey = 'chat_history';
  static const String _sessionIdsKey = 'chat_session_ids';

  static Future<bool> saveMessage(
    ChatMessage message, {
    String? sessionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSessionId = sessionId ?? _getCurrentSessionId();
      final sessionMessages = await getMessagesFromSession(currentSessionId);
      sessionMessages.add(message);
      final messagesJson = sessionMessages.map((msg) => msg.toJson()).toList();
      final success = await prefs.setString(
        '${_historyKey}_$currentSessionId',
        jsonEncode(messagesJson),
      );
      if (success) {
        await _updateSessionIds(currentSessionId);
      }
      return success;
    } catch (e) {
      _logger.e('Erro ao salvar mensagem no histórico: $e');
      return false;
    }
  }

  static Future<List<ChatMessage>> getCurrentSessionMessages() async {
    return getMessagesFromSession(_getCurrentSessionId());
  }

  static Future<List<ChatMessage>> getMessagesFromSession(
    String sessionId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJsonString = prefs.getString('${_historyKey}_$sessionId');
      if (messagesJsonString == null) {
        return [];
      }
      final List<dynamic> messagesJson = jsonDecode(messagesJsonString);
      return messagesJson
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Erro ao recuperar mensagens da sessão $sessionId: $e');
      return [];
    }
  }

  static Future<List<ChatSession>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionIdsJson = prefs.getString(_sessionIdsKey);
      if (sessionIdsJson == null) {
        return [];
      }
      final List<dynamic> sessionIds = jsonDecode(sessionIdsJson);
      final List<ChatSession> sessions = [];
      for (String sessionId in sessionIds.cast<String>()) {
        final messages = await getMessagesFromSession(sessionId);
        if (messages.isNotEmpty) {
          sessions.add(
            ChatSession(
              id: sessionId,
              messages: messages,
              startTime: DateTime.parse(sessionId),
            ),
          );
        }
      }
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (e) {
      _logger.e('Erro ao recuperar todas as sessões: $e');
      return [];
    }
  }

  static Future<bool> clearSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final removed = await prefs.remove('${_historyKey}_$sessionId');
      if (removed) {
        await _removeSessionId(sessionId);
      }
      return removed;
    } catch (e) {
      _logger.e('Erro ao limpar sessão $sessionId: $e');
      return false;
    }
  }

  static Future<bool> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getAllSessions();
      bool allCleared = true;
      for (ChatSession session in sessions) {
        final removed = await prefs.remove('${_historyKey}_${session.id}');
        if (!removed) allCleared = false;
      }
      final idsRemoved = await prefs.remove(_sessionIdsKey);
      return allCleared && idsRemoved;
    } catch (e) {
      _logger.e('Erro ao limpar todo o histórico: $e');
      return false;
    }
  }

  static String startNewSession() {
    return DateTime.now().toIso8601String();
  }

  static String _getCurrentSessionId() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).toIso8601String();
  }

  static Future<void> _updateSessionIds(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionIdsJson = prefs.getString(_sessionIdsKey);
      Set<String> sessionIds = {};
      if (sessionIdsJson != null) {
        final List<dynamic> existingIds = jsonDecode(sessionIdsJson);
        sessionIds = existingIds.cast<String>().toSet();
      }
      sessionIds.add(sessionId);
      await prefs.setString(_sessionIdsKey, jsonEncode(sessionIds.toList()));
    } catch (e) {
      _logger.e('Erro ao atualizar IDs de sessão: $e');
    }
  }

  static Future<void> _removeSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionIdsJson = prefs.getString(_sessionIdsKey);
      if (sessionIdsJson != null) {
        final List<dynamic> sessionIds = jsonDecode(sessionIdsJson);
        sessionIds.remove(sessionId);
        await prefs.setString(_sessionIdsKey, jsonEncode(sessionIds));
      }
    } catch (e) {
      _logger.e('Erro ao remover ID de sessão: $e');
    }
  }
}

class ChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime startTime;

  ChatSession({
    required this.id,
    required this.messages,
    required this.startTime,
  });

  String get firstUserMessage {
    final userMessage = messages.firstWhere(
      (msg) => msg.isUser && msg.text.trim().isNotEmpty,
      orElse: () => ChatMessage(
        text: 'Nova conversa',
        isUser: true,
        timestamp: startTime,
      ),
    );
    return userMessage.text;
  }

  ChatMessage get lastMessage => messages.last;
  int get messageCount => messages.length;
}
