import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url:
          'https://tcvdmehwyhjpiqbsqzvq.supabase.co', // From Supabase Dashboard → Settings → API
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjdmRtZWh3eWhqcGlxYnNxenZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3NzAwMTEsImV4cCI6MjA4MzM0NjAxMX0.ax02qKbYqFmAUoq9O6t2lNlfrI43HEa5PuHz-BS0DV8', // From Supabase Dashboard → Settings → API
    );
    print('Supabase initialized successfully!');
  } catch (e) {
    print('Supabase init error: $e');
  }

  try {
    final data = await supabase.from('plants').select();
    print('Data: $data');
  } catch (e) {
    print('Error: $e'); // ← this will tell you what's wrong
  }

  runApp(const MyApp());
}

// Global reference to Supabase client (use anywhere in your app)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      title: 'Mitidawa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green[700]!),
        useMaterial3: true,
      ),
      home: session != null ? const HomeScreen() : const AuthScreen(),
    );
  }
}
