import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth.dart';
import 'screens/marketplace/marketplace_list_screen.dart';
import 'screens/marketplace/marketplace_detail_screen.dart';
import 'screens/marketplace/marketplace_create_screen.dart';
import 'screens/marketplace/marketplace_buy_screen.dart';
import 'screens/simple_voice_agent.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Companion',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/marketplace': (context) => const MarketplaceListScreen(),
        '/marketplace/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MarketplaceDetailScreen(product: args);
        },
        '/marketplace/create': (context) => const MarketplaceCreateScreen(),
        '/marketplace/buy': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MarketplaceBuyScreen(product: args);
        },
        '/simple-voice-agent': (context) => const SimpleVoiceAgent(),
      },
    );
  }
}

class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Companion')),
      body: const Center(child: Text('Welcome! UI screens coming soon.')),
    );
  }
}
