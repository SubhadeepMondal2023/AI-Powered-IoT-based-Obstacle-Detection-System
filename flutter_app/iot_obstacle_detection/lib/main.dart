import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const ThingSpeakDashboardApp());
}

class ThingSpeakDashboardApp extends StatelessWidget {
  const ThingSpeakDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obstacle Detection',
      theme: ThemeData(
        primaryColor: const Color(0xFF2E3192),
        colorScheme: ColorScheme.fromSwatch(
          accentColor: const Color(0xFF00AEEF),
          backgroundColor: const Color(0xFFF8F9FC),
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF5A5A89)),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Dio _dio = Dio();
  Map<String, dynamic>? _channelData;
  List<Map<String, dynamic>>? _feeds;
  bool _isLoading = true;
  String _errorMessage = '';
  final String _apiKey = '2RDKDOPTN2DTFHZR';
  final int _channelId = 2997670;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _dio.get(
        'https://api.thingspeak.com/channels/$_channelId/fields/1.json',
        queryParameters: {'results': 20, 'api_key': _apiKey},
        options: Options(
          headers: {
            'User-Agent': 'Dart/3.1 (dart:io)',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // Parse and sort feeds by entry_id descending
        List<dynamic> rawFeeds = response.data['feeds'];
        List<Map<String, dynamic>> sortedFeeds = [];

        for (var feed in rawFeeds) {
          if (feed is Map<String, dynamic>) {
            sortedFeeds.add(feed);
          }
        }

        sortedFeeds.sort((a, b) {
          int idA = a['entry_id'] ?? 0;
          int idB = b['entry_id'] ?? 0;
          return idB.compareTo(idA); // Descending order
        });

        setState(() {
          _channelData = response.data['channel'];
          _feeds = sortedFeeds;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child:
                  _isLoading
                      ? _buildLoading()
                      : _errorMessage.isNotEmpty
                      ? _buildError()
                      : _buildDashboard(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE5E5FF),
            child: Icon(Icons.sensors, color: Color(0xFF2E3192)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OBSTACLE DETECTION',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2E3192),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _channelData?['description'] ?? 'IoT with AI powered project',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Loading sensor data...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('RETRY', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_feeds == null || _feeds!.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final latestFeed = _feeds!.first;
    final latestDistance = latestFeed['field1'] ?? '0';
    final intDistance = int.tryParse(latestDistance) ?? 0;
    final entryId = latestFeed['entry_id']?.toString() ?? 'N/A';

    // Calculate statistics
    final distances =
        _feeds!.map((e) => int.tryParse(e['field1'] ?? '0') ?? 0).toList();
    final avgDistance =
        distances.isNotEmpty
            ? distances.reduce((a, b) => a + b) / distances.length
            : 0;
    final minDistance =
        distances.isNotEmpty ? distances.reduce((a, b) => a < b ? a : b) : 0;
    final maxDistance =
        distances.isNotEmpty ? distances.reduce((a, b) => a > b ? a : b) : 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Real-time status card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'CURRENT OBSTACLE DISTANCE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A5A89),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            // Display entry_id in large text
                            Text(
                              '#$entryId',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E3192),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$intDistance cm',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  intDistance,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(intDistance),
                                style: TextStyle(
                                  color: _getStatusColor(intDistance),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Replaced circular bar with safety zone indicators
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildZoneIndicator(
                              'SAFE ZONE',
                              '>30 cm',
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildZoneIndicator(
                              'WARNING ZONE',
                              '10-30 cm',
                              Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            _buildZoneIndicator(
                              'DANGER ZONE',
                              '<10 cm',
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          'Min',
                          '$minDistance cm',
                          Icons.arrow_downward,
                        ),
                        _buildStatCard(
                          'Avg',
                          '${avgDistance.toStringAsFixed(1)} cm',
                          Icons.bar_chart,
                        ),
                        _buildStatCard(
                          'Max',
                          '$maxDistance cm',
                          Icons.arrow_upward,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Data visualization section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DISTANCE TREND',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A5A89),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          maximum: 250,
                          interval: 50,
                        ),
                        series: <CartesianSeries>[
                          LineSeries<Map<String, dynamic>, String>(
                            dataSource: _feeds!,
                            xValueMapper: (data, index) {
                              final date = DateTime.tryParse(
                                data['created_at'] ?? '',
                              );
                              return date != null
                                  ? DateFormat.Hm().format(date)
                                  : '${index + 1}';
                            },
                            yValueMapper:
                                (data, _) =>
                                    int.tryParse(data['field1'] ?? '0') ?? 0,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
                            markerSettings: const MarkerSettings(
                              isVisible: true,
                            ),
                            color: const Color(0xFF2E3192),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent readings section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECENT READINGS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A5A89),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._feeds!
                        .take(5)
                        .map((feed) => _buildReadingItem(feed))
                        .toList(),
                    if (_feeds!.length > 5)
                      TextButton(
                        onPressed: () {},
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('View all readings'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneIndicator(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2E3192)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5A5A89)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3192),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingItem(Map<String, dynamic> feed) {
    final distance = feed['field1'] ?? '0';
    final entryId = feed['entry_id']?.toString() ?? 'N/A';
    final dateTime = feed['created_at'] ?? '';
    final intDistance = int.tryParse(distance) ?? 0;

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.tryParse(dateTime);
    } catch (e) {
      // Handle parse error
    }

    final formattedTime =
        parsedDate != null ? DateFormat.Hms().format(parsedDate) : dateTime;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(intDistance).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$entryId',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(intDistance),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance: $distance cm',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E3192),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A5A89),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getStatusIcon(intDistance),
            color: _getStatusColor(intDistance),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int distance) {
    if (distance < 10) return const Color(0xFFE53935);
    if (distance < 20) return const Color(0xFFFFB300);
    return const Color(0xFF43A047);
  }

  String _getStatusText(int distance) {
    if (distance < 10) return 'DANGER ZONE';
    if (distance < 20) return 'WARNING ZONE';
    return 'SAFE ZONE';
  }

  IconData _getStatusIcon(int distance) {
    if (distance < 10) return Icons.warning;
    if (distance < 20) return Icons.info_outline;
    return Icons.check_circle_outline;
  }
}
