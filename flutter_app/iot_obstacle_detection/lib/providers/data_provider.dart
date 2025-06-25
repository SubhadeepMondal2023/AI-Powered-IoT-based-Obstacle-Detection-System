// lib/providers/data_provider.dart
import 'package:flutter/foundation.dart';
import '../services/thingspeak_service.dart';
import '../models/thingspeak_data.dart';

class DataProvider with ChangeNotifier {
  final ThingSpeakService _service = ThingSpeakService();
  ThingSpeakData? _data;
  String _error = '';
  bool _isLoading = false;

  ThingSpeakData? get data => _data;
  String get error => _error;
  bool get isLoading => _isLoading;

  Future<void> fetchData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _service.fetchData();
      _data = ThingSpeakData.fromJson(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
