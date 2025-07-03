import 'package:flutter/material.dart';
import '../models/ai_model.dart';
import '../services/ai_service.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  List<AIModelData> _aiModels = [];
  List<AIModelData> _filteredModels = [];
  List<String> _themes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedTheme = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<AIModelData> get aiModels => _aiModels;
  List<AIModelData> get filteredModels => _filteredModels;
  List<String> get themes => _themes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedTheme => _selectedTheme;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Load all AI models
  Future<void> loadAIModels() async {
    _setLoading(true);
    _clearError();

    try {
      _aiService.getAIModels().listen(
        (models) async {
          _aiModels = models;

          // Load user names for all models
          for (var model in _aiModels) {
            model.userName = await _aiService.getUserName(model.userId);
          }

          _applyFilters();
          _setLoading(false);
        },
        onError: (e) {
          _setError('Failed to load AI models: $e');
          _setLoading(false);
        },
      );

      // Load themes
      await loadThemes();
    } catch (e) {
      _setError('Failed to load AI models: $e');
      _setLoading(false);
    }
  }

  // Load themes
  Future<void> loadThemes() async {
    try {
      final themes = await _aiService.getUniqueThemes();
      _themes = ['All', ...themes];
      notifyListeners();
    } catch (e) {
      _setError('Failed to load themes: $e');
    }
  }

  // Filter by theme
  void filterByTheme(String theme) {
    _selectedTheme = theme;
    _applyFilters();
  }

  // Filter by date range
  void filterByDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  // Clear date filter
  void clearDateFilter() {
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _selectedTheme = '';
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredModels = _aiModels;

    // Apply theme filter
    if (_selectedTheme.isNotEmpty && _selectedTheme != 'All') {
      _filteredModels = _filteredModels
          .where((model) => model.theme == _selectedTheme)
          .toList();
    }

    // Apply date filter
    if (_startDate != null && _endDate != null) {
      _filteredModels = _filteredModels.where((model) {
        final modelDate = model.createdAt.toDate();
        return modelDate.isAfter(_startDate!) &&
            modelDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    notifyListeners();
  }

  // Get average processing time by theme
  Map<String, double> getAverageProcessingTimeByTheme() {
    final Map<String, List<double>> themeTimesMap = {};

    for (var model in _filteredModels) {
      if (!themeTimesMap.containsKey(model.theme)) {
        themeTimesMap[model.theme] = [];
      }
      themeTimesMap[model.theme]!.add(model.processingTimeInSeconds);
    }

    final Map<String, double> result = {};
    themeTimesMap.forEach((theme, times) {
      final average = times.reduce((a, b) => a + b) / times.length;
      result[theme] = average;
    });

    return result;
  }

  // Get processing time trends over time (daily average)
  Map<DateTime, double> getProcessingTimeTrends() {
    final Map<DateTime, List<double>> dateTimesMap = {};

    for (var model in _filteredModels) {
      final date = DateTime(
        model.createdAt.toDate().year,
        model.createdAt.toDate().month,
        model.createdAt.toDate().day,
      );

      if (!dateTimesMap.containsKey(date)) {
        dateTimesMap[date] = [];
      }
      dateTimesMap[date]!.add(model.processingTimeInSeconds);
    }

    final Map<DateTime, double> result = {};
    dateTimesMap.forEach((date, times) {
      final average = times.reduce((a, b) => a + b) / times.length;
      result[date] = average;
    });

    return result;
  }

  // Get theme distribution
  Map<String, int> getThemeDistribution() {
    final Map<String, int> result = {};

    for (var model in _filteredModels) {
      if (!result.containsKey(model.theme)) {
        result[model.theme] = 0;
      }
      result[model.theme] = result[model.theme]! + 1;
    }

    return result;
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
