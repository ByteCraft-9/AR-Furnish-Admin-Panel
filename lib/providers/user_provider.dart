import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _roleFilter;
  bool? _statusFilter;
  String _searchQuery = '';

  // Chart data
  Map<String, int> _userRegistrationsByMonth = {};
  Map<String, int> _userRoleDistribution = {};
  bool _isLoadingChartData = false;
  bool _hasLoadedChartData = false;

  // Getters
  List<UserModel> get users => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get roleFilter => _roleFilter;
  bool? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  Map<String, int> get userRegistrationsByMonth => _userRegistrationsByMonth;
  Map<String, int> get userRoleDistribution => _userRoleDistribution;
  bool get isLoadingChartData => _isLoadingChartData;
  bool get hasLoadedChartData => _hasLoadedChartData;

  // Load users with optional filters
  void loadUsers() {
    _setLoading(true);
    _clearError();

    try {
      _userService
          .getUsers(
        role: _roleFilter,
        isActive: _statusFilter,
        searchQuery: _searchQuery,
      )
          .listen(
        (users) {
          _users = users;
          _applyFilters();
          _setLoading(false);
        },
        onError: (e) {
          _setError('Failed to load users: $e');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to setup user loading: $e');
      _setLoading(false);
    }
  }

  // Set role filter
  void setRoleFilter(String? role) {
    _roleFilter = role;
    loadUsers();
  }

  // Set status filter
  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    loadUsers();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters locally (for search)
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredUsers = _users.where((user) {
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _roleFilter = null;
    _statusFilter = null;
    _searchQuery = '';
    loadUsers();
  }

  // Get user by ID
  Future<UserModel?> getUserById(String id) async {
    try {
      return await _userService.getUserById(id);
    } catch (e) {
      _setError('Failed to get user: $e');
      return null;
    }
  }

  // Create user
  Future<bool> createUser(UserModel user) async {
    _setLoading(true);
    _clearError();

    try {
      await _userService.createUser(user);
      loadUsers();
      return true;
    } catch (e) {
      _setError('Failed to create user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update user
  Future<bool> updateUser(UserModel user) async {
    _setLoading(true);
    _clearError();

    try {
      await _userService.updateUser(user);
      loadUsers();
      return true;
    } catch (e) {
      _setError('Failed to update user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Toggle user status using UserModel
  Future<void> toggleUserStatus(UserModel user) async {
    try {
      _setLoading(true);
      _clearError();

      await _userService.toggleUserStatus(user.id, !user.isActive);

      // Update the local user list
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user.copyWith(isActive: !user.isActive);
        _applyFilters();
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to toggle user status: $e');
      _setLoading(false);
    }
  }

  // Delete user using UserModel
  Future<void> deleteUser(UserModel user) async {
    try {
      _setLoading(true);
      _clearError();

      await _userService.deleteUser(user.id);

      // Remove from local list
      _users.removeWhere((u) => u.id == user.id);
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to delete user: $e');
      _setLoading(false);
    }
  }

  // Load chart data
  Future<void> loadChartData() async {
    // Skip if already loading or loaded with data
    if (_isLoadingChartData ||
        (_hasLoadedChartData &&
            _userRegistrationsByMonth.isNotEmpty &&
            _userRoleDistribution.isNotEmpty)) {
      return;
    }

    _isLoadingChartData = true;
    notifyListeners();

    try {
      // Load registrations by month
      _userRegistrationsByMonth =
          await _userService.getUserRegistrationsByMonth();

      // Load role distribution
      _userRoleDistribution = await _userService.getUserRolesDistribution();

      _isLoadingChartData = false;
      _hasLoadedChartData = true;
      notifyListeners();
    } catch (e) {
      // Initialize with empty data on error
      _userRegistrationsByMonth = {};
      _userRoleDistribution = {};
      _isLoadingChartData = false;
      _hasLoadedChartData = true; // Mark as loaded to prevent constant retries
      notifyListeners();
    }
  }

  // User permission methods
  Future<Map<String, bool>?> getUserPermissions(String userId) async {
    try {
      return await _userService.getUserPermissions(userId);
    } catch (e) {
      _setError('Failed to get user permissions: $e');
      return null;
    }
  }

  Future<bool> updateUserPermissions(
      String userId, Map<String, bool> permissions) async {
    _setLoading(true);
    _clearError();

    try {
      await _userService.updateUserPermissions(userId, permissions);
      loadUsers();
      return true;
    } catch (e) {
      _setError('Failed to update user permissions: $e');
      _setLoading(false);
      return false;
    }
  }

  // Default permissions map for new managers
  Map<String, bool> getDefaultPermissions() {
    return {
      'dashboard': true,
      'products': true,
      'categories': true,
      'orders': true,
      'users': false,
      'managers': false,
      'analytics': true,
      'ai-interiors': false,
      'settings': false,
      'promotions': true,
    };
  }

  // Helper methods
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
