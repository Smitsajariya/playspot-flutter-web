import 'package:flutter/foundation.dart';

class HostEventFlowController extends ChangeNotifier {
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  String? _customActivityName;
  String? _customActivityEmoji;
  String? _selectedLocation;
  DateTime? _selectedDateTime;
  String? _audienceType;
  bool _addToMap = false;

  // Getters
  String? get selectedMainCategory => _selectedMainCategory;
  String? get selectedSubCategory => _selectedSubCategory;
  String? get customActivityName => _customActivityName;
  String? get customActivityEmoji => _customActivityEmoji;
  String? get selectedLocation => _selectedLocation;
  DateTime? get selectedDateTime => _selectedDateTime;
  String? get audienceType => _audienceType;
  bool get addToMap => _addToMap;

  // Setters
  void setMainCategory(String? category) {
    _selectedMainCategory = category;
    notifyListeners();
  }

  void setSubCategory(String?_subCategory) {
    _selectedSubCategory = _subCategory;
    notifyListeners();
  }

  void setCustomActivity(String name, String emoji) {
    _customActivityName = name;
    _customActivityEmoji = emoji;
    notifyListeners();
  }

  void setLocation(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setDateTime(DateTime? dateTime) {
    _selectedDateTime = dateTime;
    notifyListeners();
  }

  void setAudienceType(String? audience) {
    _audienceType = audience;
    notifyListeners();
  }

  void setAddToMap(bool value) {
    _addToMap = value;
    notifyListeners();
  }

  // Reset the flow
  void reset() {
    _selectedMainCategory = null;
    _selectedSubCategory = null;
    _customActivityName = null;
    _customActivityEmoji = null;
    _selectedLocation = null;
    _selectedDateTime = null;
    _audienceType = null;
    _addToMap = false;
    notifyListeners();
  }

  // Get the final activity name to use
  String getFinalActivityName() {
    if (_customActivityName != null && _customActivityName!.isNotEmpty) {
      return _customActivityName!;
    }
    return _selectedSubCategory ?? _selectedMainCategory ?? '';
  }

  // Get the final emoji to use
  String getFinalActivityEmoji() {
    if (_customActivityEmoji != null && _customActivityEmoji!.isNotEmpty) {
      return _customActivityEmoji!;
    }
    // Return emoji based on category
    switch (_selectedSubCategory ?? _selectedMainCategory) {
      case 'football':
      case 'soccer':
        return '⚽';
      case 'karaoke':
        return '🎤';
      case 'fitness':
      case 'yoga':
        return '💪';
      case 'cultural':
        return '🎭';
      default:
        return '🏆';
    }
  }
}
