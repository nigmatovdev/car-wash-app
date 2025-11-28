import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _secureStorage = SecureStorage();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  
  // Register
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // Save tokens
        if (data['accessToken'] != null) {
          await _secureStorage.saveToken(data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _secureStorage.saveRefreshToken(data['refreshToken']);
        }
        
        // Save user data
        if (data['user'] != null) {
          _user = UserModel.fromJson(data['user']);
          if (_user != null) {
            await _secureStorage.saveUserId(_user!.id);
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = response.data;
        _errorMessage = data['message'] ?? 'Registration failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // Save tokens
        if (data['accessToken'] != null) {
          await _secureStorage.saveToken(data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _secureStorage.saveRefreshToken(data['refreshToken']);
        }
        
        // Save user data
        if (data['user'] != null) {
          _user = UserModel.fromJson(data['user']);
          if (_user != null) {
            await _secureStorage.saveUserId(_user!.id);
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = response.data;
        _errorMessage = data['message'] ?? 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _secureStorage.clear();
      await LocalStorage.remove('user_data');
      _user = null;
      notifyListeners();
    }
  }
  
  // Get current user
  Future<void> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.userProfile);
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Extract error message from exception
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map && data['message'] != null) {
          return data['message'];
        }
        return error.response!.statusMessage ?? 'An error occurred';
      }
      return error.message ?? 'Network error. Please check your connection.';
    }
    return error.toString();
  }
}
