// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/thingspeak_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obstacle Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DataProvider>().fetchData(),
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.data == null) {
            return const Center(child: Text('No data available'));
          }

          return _buildDataView(provider.data!);
        },
      ),
    );
  }

  Widget _buildDataView(ThingSpeakData data) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            data.channelName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: data.feeds.length,
            itemBuilder: (context, index) {
              final feed = data.feeds[index];
              return ListTile(
                title: Text('Distance: ${feed.distance} cm'),
                subtitle: Text(
                  'Time: ${feed.timestamp.hour}:${feed.timestamp.minute}:${feed.timestamp.second}',
                ),
                leading: CircleAvatar(
                  backgroundColor: _getColor(feed.distance),
                  child: Text(
                    feed.distance,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getColor(String distance) {
    final value = int.tryParse(distance) ?? 0;
    if (value < 10) return Colors.red;
    if (value < 20) return Colors.orange;
    return Colors.green;
  }
}
