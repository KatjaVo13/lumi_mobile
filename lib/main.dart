import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const LumiApp());
}

class LumiApp extends StatelessWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    goNext();
  }

  Future<void> goNext() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lumi',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

final String baseUrl = 'http://192.168.60.82:8000';

  String locationStatus = 'Checking location...';
  String? selectedCity = 'Helsinki';
  String selectedMood = 'curious';
  String recommendationText = '';
  Map<String, dynamic>? recommendation;
  bool isLoadingRecommendation = false;
  List<dynamic> recommendations = [];

  final List<String> cities = ['Helsinki', 'Espoo'];
  final List<String> moods = ['curious', 'calm', 'adventurous', 'romantic'];

  @override
  void initState() {
    super.initState();
    initLocation();
  }

  Future<void> initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationStatus = 'Location services are off';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          locationStatus = 'Location not allowed';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationStatus = 'Location permanently denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        locationStatus =
            'Location found: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      setState(() {
        locationStatus = 'Location error: $e';
      });
    }
  }

Future<void> recommendPlace() async {
  setState(() {
    isLoadingRecommendation = true;
    recommendationText = '';
    recommendation = null;
    recommendations = [];
  });

  final bool noLocation =
      locationStatus == 'Location not allowed' ||
      locationStatus == 'Location permanently denied' ||
      locationStatus == 'Location services are off' ||
      locationStatus.startsWith('Location error');

  double userLat = 0;
  double userLon = 0;

  try {
    if (!noLocation) {
      final position = await Geolocator.getCurrentPosition();
      userLat = position.latitude;
      userLon = position.longitude;
    }

    final body = {
      "area": noLocation ? selectedCity : "",
      "mood": selectedMood,
      "time_available": 30,
      "transport": "walk",
      "weather": "dry",
      "user_lat": userLat,
      "user_lon": userLon,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/walk'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

    if (data["suggestions"] != null && data["suggestions"].isNotEmpty) {
      final List<dynamic> items = List<dynamic>.from(data["suggestions"]);

      items.sort((a, b) {
       final scoreA = a["score"] ?? 0;
       final scoreB = b["score"] ?? 0;
       return scoreB.compareTo(scoreA);
      });

      setState(() {
      recommendations = items.take(3).toList();
      recommendation = recommendations.isNotEmpty ? recommendations[0] : null;
      });
    } else {
        setState(() {
          recommendationText = 'No suggestions found';
        });
      }
    } else {
      setState(() {
        recommendationText = 'Server error: ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      recommendationText = 'Error: $e';
    });
  } finally {
    setState(() {
      isLoadingRecommendation = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final bool noLocation =
        locationStatus == 'Location not allowed' ||
        locationStatus == 'Location permanently denied' ||
        locationStatus == 'Location services are off' ||
        locationStatus.startsWith('Location error');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumi'),
      ),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locationStatus),
              const SizedBox(height: 16),
              if (noLocation) ...[
                const Text('Select city'),
                const SizedBox(height: 8),
               DropdownButtonFormField<String>(
                  value: selectedCity,
                  items: cities
                    .map(
                      (city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      ),
                    )
                    .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text('Select mood'),
              const SizedBox(height: 8),
             DropdownButtonFormField<String>(
                value: selectedMood,
                items: moods
                  .map(
                    (mood) => DropdownMenuItem(
                      value: mood,
                      child: Text(mood),
                    ),
                  )
                  .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedMood = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: recommendPlace,
                  child: const Text('Recommend a place'),
                ),
              ),
              const SizedBox(height: 24),
              if (isLoadingRecommendation) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
            ] else if (recommendations.isNotEmpty) ...[
                const SizedBox(height: 24),
                ...recommendations.map((item) => buildRecommendationCard(item)),
            ] else if (recommendationText.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(recommendationText),
                  ),
                ),
          ]
             ],
          ),
        ),
      ),
    ),
    );
  }

  Widget buildRecommendationCard(dynamic item) {
  if (recommendation == null) {
    return const SizedBox.shrink();
  }

  final reasoning = item['reasoning'] as List<dynamic>? ?? [];

  return Card(
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(
            item['name'] ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(item['description'] ?? ''),
          const SizedBox(height: 12),
          Text('Area: ${item['area'] ?? '-'}'),
          Text('Category: ${item['category'] ?? '-'}'),
          Text('Address: ${item['address'] ?? '-'}'),
          const SizedBox(height: 12),
          const Text(
            'Why this place',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...reasoning.take(3).map((item) => Text('• $item')),
         ],
       ),
     ),

  );
}
}