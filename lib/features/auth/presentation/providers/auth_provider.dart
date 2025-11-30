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
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? avatar,
    String role = 'customer',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Convert role to uppercase to match API
      final roleUpper = role.toUpperCase();
      
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (address != null && address.isNotEmpty) 'address': address,
          if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
          'role': roleUpper == 'WASHER' ? 'WASHER' : 'CUSTOMER',
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
    _isLoading = true;
    notifyListeners();
    
    try {
      // Try /users/me first, fallback to /users/profile
      try {
        final response = await _apiClient.get(ApiConstants.userMe);
        if (response.statusCode == 200) {
          _user = UserModel.fromJson(response.data);
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        // Fallback to /users/profile
      }
      
      final response = await _apiClient.get(ApiConstants.userProfile);
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
      print('Error fetching user: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Initialize user on app start
  Future<void> initialize() async {
    // Only fetch if we have a token and no user data
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty && _user == null) {
      await getCurrentUser();
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
