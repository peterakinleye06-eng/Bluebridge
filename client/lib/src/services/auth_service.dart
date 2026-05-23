import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isGuest = false;

  bool get isAuthenticated => _token != null;
  bool get isGuest => _isGuest;
  bool get canBrowse => isAuthenticated || isGuest;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;

  Future<void> login(String email, String password) async {
    // Errors from ApiService are already readable — just rethrow directly
    final response = await ApiService().login(email, password);
    _token = response['token'];
    _user = response['user'];
    notifyListeners();
  }

  Future<void> register(String email, String password, String name) async {
    final response = await ApiService().register(email, password, name);
    _token = response['token'];
    _user = response['user'];
    _isGuest = false;
    notifyListeners();
  }

  void continueAsGuest() {
    _token = null;
    _user = {'name': 'Guest'};
    _isGuest = true;
    notifyListeners();
  }

  void updateProfile(Map<String, dynamic> profile) {
    _user = {...?_user, ...profile};
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    _isGuest = false;
    notifyListeners();
  }

  // SMS/OTP Authentication
  Future<void> sendOTP(String phone) async {
    await ApiService().sendOTP(phone);
  }

  Future<void> verifyOTP(String phone, String code) async {
    final response = await ApiService().verifyOTP(phone, code);
    _token = response['token'];
    _user = response['user'];
    _isGuest = false;
    notifyListeners();
  }

  // OAuth Authentication
  Future<void> googleSignIn(String token) async {
    final response = await ApiService().googleSignIn(token);
    _token = response['token'];
    _user = response['user'];
    _isGuest = false;
    notifyListeners();
  }

  Future<void> appleSignIn(String identityToken, String? authorizationCode, String? user) async {
    final response = await ApiService().appleSignIn(identityToken, authorizationCode, user);
    _token = response['token'];
    _user = response['user'];
    _isGuest = false;
    notifyListeners();
  }

  // Password Reset
  Future<void> forgotPassword({String? email, String? phone}) async {
    await ApiService().forgotPassword(email: email, phone: phone);
  }

  Future<void> resetPassword(String token, String password) async {
    await ApiService().resetPassword(token, password);
  }
}