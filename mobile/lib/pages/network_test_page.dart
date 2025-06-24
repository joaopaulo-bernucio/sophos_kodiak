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

  Future<void> _runConnectivityTests() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    final results = StringBuffer();
    results.writeln('=== TESTE DE CONECTIVIDADE ===\n');

    // Teste 1: Endpoint de debug
    results.writeln('1. Testando endpoint de debug...');
    try {
      final response = await http
          .get(
            Uri.parse('http://10.0.2.2:5000/debug/connection'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        results.writeln('✅ SUCESSO - Status: ${response.statusCode}');
        results.writeln('   Dados: ${data['message']}');
        results.writeln('   CORS: ${data['environment']['cors_enabled']}');
        results.writeln('   DB Host: ${data['environment']['db_host']}');
      } else {
        results.writeln('❌ FALHA - Status: ${response.statusCode}');
        results.writeln('   Body: ${response.body}');
      }
    } catch (e) {
      results.writeln('❌ ERRO: $e');
    }

    results.writeln();

    // Teste 2: Endpoint de health check
    results.writeln('2. Testando health check...');
    try {
      final response = await http
          .get(
            Uri.parse('http://10.0.2.2:5000/api/graphs/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        results.writeln('✅ SUCESSO - Status: ${response.statusCode}');
        results.writeln('   Body: ${response.body}');
      } else {
        results.writeln('❌ FALHA - Status: ${response.statusCode}');
      }
    } catch (e) {
      results.writeln('❌ ERRO: $e');
    }

    results.writeln();

    // Teste 3: Endpoint de pergunta
    results.writeln('3. Testando endpoint de pergunta...');
    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:5000/pergunta'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'pergunta': 'Teste de conectividade'}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        results.writeln('✅ SUCESSO - Status: ${response.statusCode}');
        results.writeln('   Sucesso: ${data['sucesso']}');
        if (data['erro'] != null) {
          results.writeln('   Erro: ${data['erro']}');
        }
      } else {
        results.writeln('❌ FALHA - Status: ${response.statusCode}');
        results.writeln('   Body: ${response.body}');
      }
    } catch (e) {
      results.writeln('❌ ERRO: $e');
    }

    results.writeln();

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
