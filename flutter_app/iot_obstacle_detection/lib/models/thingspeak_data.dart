// lib/models/thingspeak_data.dart
class ThingSpeakData {
  final String channelName;
  final String sensorType;
  final List<Feed> feeds;

  ThingSpeakData({
    required this.channelName,
    required this.sensorType,
    required this.feeds,
  });

  factory ThingSpeakData.fromJson(Map<String, dynamic> json) {
    return ThingSpeakData(
      channelName: json['channel']['name'] ?? 'Unknown Channel',
      sensorType: json['channel']['field1'] ?? 'Unknown Sensor',
      feeds:
          (json['feeds'] as List).map((feed) => Feed.fromJson(feed)).toList(),
    );
  }
}

class Feed {
  final String distance;
  final DateTime timestamp;

  Feed({required this.distance, required this.timestamp});

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      distance: json['field1'] ?? '0',
      timestamp: DateTime.parse(json['created_at']),
    );
  }
}
