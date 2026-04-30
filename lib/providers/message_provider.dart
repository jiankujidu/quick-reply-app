import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class MessageProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<Message> _messages = [];
  List<Tag> _tags = [];
  List<Map<String, dynamic>> _categories = [];
  String _currentLevel = 'company';
  bool _isLoading = false;
  String? _error;
  // Filter fields for future use
  // String? _categoryFilter;
  // String? _subcategoryFilter;

  List<Message> get messages => _messages;
  List<Tag> get tags => _tags;
  List<Map<String, dynamic>> get categories => _categories;
  String get currentLevel => _currentLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMessages({String? level}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 如果指定了level，按level过滤；否则加载所有数据
      if (level != null) {
        _messages = await _dbService.getMessages(level: level);
      } else {
        // 加载所有消息，UI会按tab过滤
        _messages = await _dbService.getMessages();
      }
      _tags = await _dbService.getTags();
      _categories = await _dbService.getAllCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLevel(String level) async {
    _currentLevel = level;
    await loadMessages(level: level);
  }

  // Filter methods - currently not used but kept for future
  /*
  void filterByCategory(String? category) {
    // _categoryFilter = category;
    // _subcategoryFilter = null;
    notifyListeners();
  }

  void filterBySubcategory(String? subcategory) {
    // _subcategoryFilter = subcategory;
    notifyListeners();
  }
  */

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

  // 分类管理
  Future<void> addCategory(Map<String, dynamic> category) async {
    try {
      await _dbService.insertCategory(category);
      _categories = await _dbService.getAllCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getCategoriesByLevel(String level) {
    return _categories.where((c) => c['level'] == level || c['level'] == null).toList();
  }
}
