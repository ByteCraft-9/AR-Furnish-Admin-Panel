import 'package:flutter/material.dart';
import '../models/promotion_model.dart';
import '../services/promotion_service.dart';

class PromotionProvider extends ChangeNotifier {
  final PromotionService _promotionService = PromotionService();
  List<PromotionModel> _promotions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<PromotionModel> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all promotions
  Future<void> loadPromotions() async {
    _setLoading(true);
    _clearError();

    try {
      _promotionService.getPromotions().listen(
        (promotions) {
          _promotions = promotions;
          _setLoading(false);
        },
        onError: (e) {
          _setError('Failed to load promotions: $e');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load promotions: $e');
      _setLoading(false);
    }
  }

  // Add promotion
  Future<bool> addPromotion(PromotionModel promotion) async {
    _setLoading(true);
    _clearError();

    try {
      await _promotionService.addPromotion(promotion);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add promotion: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update promotion
  Future<bool> updatePromotion(PromotionModel promotion) async {
    _setLoading(true);
    _clearError();

    try {
      await _promotionService.updatePromotion(promotion);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update promotion: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete promotion
  Future<bool> deletePromotion(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _promotionService.deletePromotion(id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete promotion: $e');
      _setLoading(false);
      return false;
    }
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
