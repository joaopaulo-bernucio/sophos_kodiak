import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
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
        '/menu': (context) => const MenuPage(),
        '/chatbot': (context) => const ChatbotPage(),
        '/charts': (context) => const ChartsPage(),
      },
    );
  }
}
