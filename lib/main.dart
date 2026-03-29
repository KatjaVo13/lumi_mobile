import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      home: const LumiHomePage(),
    );
  }
}

class LumiHomePage extends StatefulWidget {
  const LumiHomePage({super.key});

  @override
  State<LumiHomePage> createState() => _LumiHomePageState();
}

class _LumiHomePageState extends State<LumiHomePage> {
   final String baseUrl = 'http://192.168.60.82:8000';

  String statusMessage = 'Tap the button to load likes';
  bool isLoading = false;
  List<dynamic> likes = [];

  Future<void> loadLikes() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Loading likes...';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/likes'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            likes = data;
            statusMessage = data.isEmpty ? 'No liked places yet' : 'Loaded';
          });
        } else {
          setState(() {
            likes = [];
            statusMessage = 'Unexpected response format';
          });
        }
      } else {
        setState(() {
          likes = [];
          statusMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        likes = [];
        statusMessage = 'Connection failed: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildLikeCard(dynamic item) {
    final tags = item['tags'] is List ? (item['tags'] as List).join(', ') : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['place_name'] ?? 'Unknown place',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Category: ${item['category'] ?? '-'}'),
            Text('Area: ${item['area'] ?? '-'}'),
            const SizedBox(height: 8),
            Text(item['description'] ?? ''),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Tags: $tags'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Liked places',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : loadLikes,
              child: const Text('Load likes'),
            ),
            const SizedBox(height: 12),
            Text(statusMessage),
            const SizedBox(height: 12),
            Expanded(
              child: likes.isEmpty
                  ? const Center(
                      child: Text('No items to show'),
                    )
                  : ListView.builder(
                      itemCount: likes.length,
                      itemBuilder: (context, index) {
                        return buildLikeCard(likes[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}