import 'package:flutter/material.dart';

/// Tela principal do aplicativo Sophos Kodiak
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        title: const Text(
          'Sophos Kodiak',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 100, color: Color(0xFFF6790F)),
            SizedBox(height: 20),
            Text(
              'Bem-vindo ao Sophos Kodiak!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Interface inteligente para o ERP Kodiak',
              style: TextStyle(fontSize: 16, color: Color(0xFFE6E6E6)),
            ),
          ],
        ),
      ),
    );
  }
}
