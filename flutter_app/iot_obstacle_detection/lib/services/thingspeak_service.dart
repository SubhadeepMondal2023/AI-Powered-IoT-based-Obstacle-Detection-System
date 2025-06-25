// lib/services/thingspeak_service.dart
import 'package:dio/dio.dart';

class ThingSpeakService {
  final Dio _dio = Dio();
  final String _apiKey = '2RDKDOPTN2DTFHZR';
  final int _channelId = 2997670;

  Future<Map<String, dynamic>> fetchData() async {
    try {
      final response = await _dio.get(
        'https://api.thingspeak.com/channels/$_channelId/fields/1.json',
        queryParameters: {'results': 10, 'api_key': _apiKey},
        options: Options(
          headers: {
            'User-Agent': 'Dart/3.1 (dart:io)',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
