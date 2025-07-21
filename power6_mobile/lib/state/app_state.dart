import 'package:flutter/material.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  String? _accessToken;

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void setToken(String token) {
    _accessToken = token;
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    _accessToken = null;
    notifyListeners();
  }
}
