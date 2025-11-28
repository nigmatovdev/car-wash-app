import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Fetch user profile
  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Try /users/me first, fallback to /users/profile
      try {
        final response = await _apiClient.get('/users/me');
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
        _errorMessage = 'Failed to load profile';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (avatar != null) data['avatar'] = avatar;
      
      final response = await _apiClient.patch(
        ApiConstants.updateProfile,
        data: data,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _user = UserModel.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update profile';
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
  
  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to change password';
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
  
  // Delete account
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.delete('/users/me');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete account';
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

