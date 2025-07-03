import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = '';

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get filteredProducts => _filteredProducts;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Load all products
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      _productService.getProducts().listen(
        (products) {
          _products = products;
          _applyFilters();
          _setLoading(false);
        },
        onError: (e) {
          _setError('Failed to load products: $e');
          _setLoading(false);
        },
      );

      // Load categories after products
      await loadCategories();
    } catch (e) {
      _setError('Failed to load products: $e');
      _setLoading(false);
    }
  }

  // Load all categories
  Future<void> loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      _categories = ['All', ...categories];
      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: $e');
    }
  }

  // Add product
  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();

    try {
      await _productService.addProduct(product);
      // Refresh categories in case a new one was added
      await loadCategories();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();

    try {
      await _productService.updateProduct(product);
      // Refresh categories in case a category was changed
      await loadCategories();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _productService.deleteProduct(id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredProducts = _products;

    // Apply category filter
    if (_selectedCategory.isNotEmpty && _selectedCategory != 'All') {
      _filteredProducts = _filteredProducts
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    notifyListeners();
  }

  // Toggle product enabled state
  Future<bool> toggleProductEnabledState(String id, bool isEnabled) async {
    _setLoading(true);
    _clearError();

    try {
      await _productService.toggleProductEnabledState(id, isEnabled);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update product status: $e');
      _setLoading(false);
      return false;
    }
  }

  // Load only enabled products
  Future<void> loadEnabledProducts() async {
    _setLoading(true);
    _clearError();

    try {
      _productService.getEnabledProducts().listen(
        (products) {
          _products = products;
          _applyFilters();
          _setLoading(false);
        },
        onError: (e) {
          _setError('Failed to load enabled products: $e');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load enabled products: $e');
      _setLoading(false);
    }
  }

  // Load only disabled products
  Future<void> loadDisabledProducts() async {
    _setLoading(true);
    _clearError();

    try {
      _productService.getDisabledProducts().listen(
        (products) {
          _products = products;
          _applyFilters();
          _setLoading(false);
        },
        onError: (e) {
          _setError('Failed to load disabled products: $e');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load disabled products: $e');
      _setLoading(false);
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
