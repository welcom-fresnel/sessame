import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class ConversationProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Conversation> _conversations = [];
  int _currentConversationIndex = 0;
  bool _isLoading = false;

  List<Conversation> get conversations => _conversations;
  int get currentConversationIndex => _currentConversationIndex;
  Conversation? get currentConversation =>
      _conversations.isEmpty ? null : _conversations[_currentConversationIndex];
  bool get isLoading => _isLoading;

  // Initialize and load conversations
  Future<void> initialize() async {
    await loadConversations();
  }

  // Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _dbService.getAllConversations();
      if (_conversations.isEmpty) {
        await createNewConversation();
      } else {
        _currentConversationIndex = 0;
      }
    } catch (e) {
      print('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new conversation
  Future<void> createNewConversation() async {
    try {
      final newConv = Conversation(
        id: const Uuid().v4(),
        title: 'Nouvelle conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.insertConversation(newConv);
      await loadConversations();
      _currentConversationIndex = 0;
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // Switch to a different conversation
  void switchConversation(int index) {
    if (index >= 0 && index < _conversations.length) {
      _currentConversationIndex = index;
      notifyListeners();
    }
  }

  // Add a message to the current conversation
  Future<void> addMessage(Message message) async {
    if (_conversations.isEmpty) {
      await createNewConversation();
    }

    try {
      final currentConv = _conversations[_currentConversationIndex];
      
      // Save message to database first
      await _dbService.insertMessage(currentConv.id, message);
      
      // Update title if it's still the default and this is a user message
      if (currentConv.title == 'Nouvelle conversation' && message.isUser) {
        final newTitle = message.content.length > 30
            ? '${message.content.substring(0, 30)}...'
            : message.content;
        final updatedConv = currentConv.copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        );
        await _dbService.updateConversation(updatedConv);
      } else {
        // Just update the timestamp
        final updatedConv = currentConv.copyWith(
          updatedAt: DateTime.now(),
        );
        await _dbService.updateConversation(updatedConv);
      }
      
      // Reload conversations to get the updated state
      await loadConversations();
    } catch (e) {
      print('Error adding message: $e');
      rethrow;
    }
  }

  // Update conversation title
  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    try {
      final conv = _conversations.firstWhere((c) => c.id == conversationId);
      final updatedConv = conv.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      await _dbService.updateConversation(updatedConv);
      await loadConversations();
    } catch (e) {
      print('Error updating conversation title: $e');
    }
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dbService.deleteConversation(conversationId);
      await loadConversations();
      
      // If we deleted the current conversation, switch to the first one
      if (_conversations.isEmpty) {
        await createNewConversation();
      } else if (_currentConversationIndex >= _conversations.length) {
        _currentConversationIndex = _conversations.length - 1;
      }
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }
}

