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
  String message = 'Tap the button to test backend connection';

  // Replace this with your real computer IP
  final String baseUrl = 'http://192.168.60.82:8000';

  Future<void> checkBackend() async {
    setState(() {
      message = 'Checking backend...';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          message = 'Backend OK: ${data['status']}';
        });
      } else {
        setState(() {
          message = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumi'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hello, I am Lumi',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: checkBackend,
                child: const Text('Check backend'),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}