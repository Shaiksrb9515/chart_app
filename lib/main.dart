import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

// The app starts here
void main() {
  runApp(ProviderScope(child: MyApp()));
}

// Main app widget that configures the GoRouter
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Setting up GoRouter with two routes: Home and Chart page
    final _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(),
        ),
        GoRoute(
          path: '/chart',
          builder: (context, state) => ChartPage(),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

// Home page widget with a button to navigate to the Chart page
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/chart');
          },
          child: Text('Go to Chart'),
        ),
      ),
    );
  }
}

// Data model to represent the chart data
class ChartData {
  final List<dynamic> values;
  ChartData({required this.values});

  // Factory method to parse JSON and create a ChartData instance
  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(values: json['data'] as List);
  }
}

// Repository class responsible for fetching chart data from the API
class ChartRepository {
  Future<ChartData> fetchChartData() async {
    final url = 'https://api.data.gov.in/resource/a5135590-4585-49a9-8259-a7d8125d86a8?api-key=579b464db66ec23bdd000001771be4e9e6ca444b4f3685944213c37e&format=json'; // Replace with actual endpoint
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ChartData.fromJson(jsonData);
    } else {
      throw Exception('Failed to load chart data');
    }
  }
}

// Riverpod provider that fetches chart data asynchronously
final chartDataProvider = FutureProvider<ChartData>((ref) async {
  final repository = ChartRepository();
  return repository.fetchChartData();
});

// Chart page widget that listens to the Riverpod provider and displays the chart
class ChartPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listening to the state of the chart data provider
    final chartDataAsyncValue = ref.watch(chartDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Chart')),
      body: chartDataAsyncValue.when(
        data: (chartData) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.values
                        .map((e) => FlSpot(e[0].toDouble(), e[1].toDouble()))
                        .toList(),
                    isCurved: true,
                    barWidth: 2,
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent],
                    ), // Apply a gradient to the line
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
