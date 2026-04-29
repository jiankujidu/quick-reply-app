import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class MessageProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<Message> _messages = [];
  List<Tag> _tags = [];
  String _currentLevel = 'company';
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => _messages;
  List<Tag> get tags => _tags;
  String get currentLevel => _currentLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _dbService.getMessages(level: _currentLevel);
      _tags = await _dbService.getTags();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLevel(String level) async {
    _currentLevel = level;
    await loadMessages();
  }

  Future<void> addMessage(Message message) async {
    try {
      await _dbService.insertMessage(message);
      await loadMessages();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateMessage(Message message) async {
    try {
      await _dbService.updateMessage(message);
      await loadMessages();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(int id) async {
    try {
      await _dbService.deleteMessage(id);
      await loadMessages();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Message>> searchMessages(String keyword) async {
    if (keyword.isEmpty) return [];
    return await _dbService.searchMessages(keyword);
  }

  Future<void> addTag(Tag tag) async {
    try {
      await _dbService.insertTag(tag);
      _tags = await _dbService.getTags();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Message> getMessagesByTag(String tag) {
    return _messages.where((m) => m.tags.contains(tag)).toList();
  }

  List<Message> get recentMessages => _messages.take(5).toList();
}
