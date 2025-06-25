import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkTestPage extends StatefulWidget {
  const NetworkTestPage({super.key});

  @override
  State<NetworkTestPage> createState() => _NetworkTestPageState();
}

class _NetworkTestPageState extends State<NetworkTestPage> {
  String _testResults = '';
  bool _isLoading = false;

  // Lista de URLs para testar
  static const List<String> _testUrls = [
    'http://10.0.2.2:5000', // Emulador local
    'http://192.168.1.100:5000', // IP local (ajuste conforme necessário)
    'http://sk-sk.cxbwajafbngqhhej.brazilsouth.azurecontainer.io:5000', // Azure original
  ];

  Future<void> _runConnectivityTests() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    final results = StringBuffer();
    results.writeln('=== TESTE DE CONECTIVIDADE MÚLTIPLAS URLs ===\n');

    for (int i = 0; i < _testUrls.length; i++) {
      final baseUrl = _testUrls[i];
      results.writeln('🔗 TESTANDO URL ${i + 1}: $baseUrl\n');

      await _testSingleUrl(baseUrl, results);
      results.writeln('\n${'=' * 50}\n');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _testSingleUrl(String baseUrl, StringBuffer results) async {
    // Teste 1: Health Check Básico
    results.writeln('1. Testando health check básico...');
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        results.writeln('✅ SUCESSO - Status: ${response.statusCode}');
        results.writeln('   Body: ${response.body}');
      } else {
        results.writeln('❌ FALHA - Status: ${response.statusCode}');
      }
    } catch (e) {
      results.writeln('❌ ERRO: $e');
    }

    // Teste 2: Endpoint de Debug
    results.writeln('\n2. Testando endpoint de debug...');
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/debug/connection'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        results.writeln('✅ SUCESSO - Status: ${response.statusCode}');
        results.writeln('   Message: ${data['message']}');
      } else {
        results.writeln('❌ FALHA - Status: ${response.statusCode}');
      }
    } catch (e) {
      results.writeln('❌ ERRO: $e');
    }

    // Teste 3: Endpoint de Pergunta
    results.writeln('\n3. Testando endpoint de pergunta...');
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/pergunta'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'pergunta': 'Teste de conectividade'}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        results.writeln('✅ SUCESSO - Status: ${response.statusCode}');
        results.writeln('   Sucesso: ${data['sucesso']}');
      } else {
        results.writeln('❌ FALHA - Status: ${response.statusCode}');
      }
    } catch (e) {
      results.writeln('❌ ERRO: $e');
    }

    // Teste 4: Endpoint de gráficos
    results.writeln('4. Testando endpoint de gráficos...');
    try {
      final response = await http
          .get(
            Uri.parse('http://10.0.2.2:5000/api/graphs/total_vendas_por_mes'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        results.writeln('✅ SUCESSO - Status: ${response.statusCode}');
        results.writeln('   Count: ${data['count']}');
        results.writeln('   Tempo execução: ${data['execution_time']}');
      } else {
        results.writeln('❌ FALHA - Status: ${response.statusCode}');
      }
    } catch (e) {
      results.writeln('❌ ERRO: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Conectividade'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runConnectivityTests,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Executar Testes'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? 'Clique no botão para executar os testes'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
