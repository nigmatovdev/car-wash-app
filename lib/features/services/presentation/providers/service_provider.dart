import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/service_model.dart';

class ServiceProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  ServiceModel? _service;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFavorite = false;
  
  ServiceModel? get service => _service;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFavorite => _isFavorite;
  
  // Fetch service details
  Future<void> fetchServiceDetails(String serviceId) async {
    _isLoading = true;
    _errorMessage = null;
    _service = null;
    notifyListeners();
    
    try {
      final endpoint = ApiConstants.serviceDetails.replaceAll('{id}', serviceId);
      final response = await _apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        _service = ServiceModel.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load service details';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load service details: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle favorite
  void toggleFavorite() {
    _isFavorite = !_isFavorite;
    notifyListeners();
    // TODO: Implement API call to save favorite
  }
  
  // Clear service data
  void clear() {
    _service = null;
    _isFavorite = false;
    _errorMessage = null;
    notifyListeners();
  }
}

