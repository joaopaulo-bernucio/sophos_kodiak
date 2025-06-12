import 'package:flutter/material.dart';
import 'package:sophos_kodiak/pages/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/chatbot_page.dart';
import 'pages/charts_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sophos Kodiak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/chatbot': (context) => const ChatbotPage(),
        '/charts': (context) => const ChartsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/settings') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => SettingsPage(
              cnpj: args?['cnpj'] ?? '12.345.678/0001-90',
              password: args?['password'] ?? 'password123',
              userName: args?['userName'] ?? 'Usuário',
            ),
          );
        }
        return null;
      },
    );
  }
}
