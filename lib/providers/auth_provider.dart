import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      var user = await _dbService.getUser();
      if (user != null) {
        _currentUser = User.fromMap(user);
        _isLoggedIn = true;
      } else {
        // 创建默认用户
        await _dbService.insertUser({
          'id': 1,
          'name': '管理员',
          'role': 'admin',
          'groupId': null,
          'companyId': 'company_1',
        });
        _currentUser = User(id: 1, name: '管理员', role: 'admin');
        _isLoggedIn = true;
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void login(String name, String role) {
    _currentUser = User(
      id: 1,
      name: name,
      role: role,
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
