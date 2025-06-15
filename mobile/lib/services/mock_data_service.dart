/// Serviço de dados mock para testes e desenvolvimento offline
///
/// Este arquivo fornece dados simulados que replicam a estrutura
/// do backend real, permitindo desenvolvimento e testes sem
/// dependência do servidor.
class MockDataService {
  /// Dados simulados de vendas por mês
  static List<Map<String, dynamic>> getVendasMockData() {
    return [
      {'mes': '2024-01', 'total_vendas': 125000.50, 'num_vendas': 25},
      {'mes': '2024-02', 'total_vendas': 98750.30, 'num_vendas': 18},
      {'mes': '2024-03', 'total_vendas': 156800.75, 'num_vendas': 31},
      {'mes': '2024-04', 'total_vendas': 142300.20, 'num_vendas': 28},
      {'mes': '2024-05', 'total_vendas': 178950.60, 'num_vendas': 35},
      {'mes': '2024-06', 'total_vendas': 201500.40, 'num_vendas': 42},
      {'mes': '2024-07', 'total_vendas': 189300.25, 'num_vendas': 38},
      {'mes': '2024-08', 'total_vendas': 167800.90, 'num_vendas': 33},
      {'mes': '2024-09', 'total_vendas': 195600.15, 'num_vendas': 40},
      {'mes': '2024-10', 'total_vendas': 215400.80, 'num_vendas': 45},
      {'mes': '2024-11', 'total_vendas': 234500.50, 'num_vendas': 48},
      {'mes': '2024-12', 'total_vendas': 186750.25, 'num_vendas': 37},
    ];
  }

  /// Dados simulados de funcionários por departamento
  static List<Map<String, dynamic>> getFuncionariosMockData() {
    return [
      {
        'departamento': 'Desenvolvimento',
        'quantidade': 15,
        'orcamento': 450000.00,
      },
      {'departamento': 'Marketing', 'quantidade': 8, 'orcamento': 240000.00},
      {'departamento': 'Vendas', 'quantidade': 12, 'orcamento': 360000.00},
      {
        'departamento': 'Recursos Humanos',
        'quantidade': 5,
        'orcamento': 150000.00,
      },
      {'departamento': 'Financeiro', 'quantidade': 6, 'orcamento': 180000.00},
      {'departamento': 'Suporte', 'quantidade': 10, 'orcamento': 300000.00},
      {'departamento': 'Qualidade', 'quantidade': 4, 'orcamento': 120000.00},
    ];
  }

  /// Dados simulados de projetos por status
  static List<Map<String, dynamic>> getProjetosMockData() {
    return [
      {'status': 'Em andamento', 'quantidade': 25, 'valor_total': 1250000.00},
      {'status': 'Concluído', 'quantidade': 18, 'valor_total': 900000.00},
      {'status': 'Em aprovação', 'quantidade': 8, 'valor_total': 400000.00},
      {'status': 'Cancelado', 'quantidade': 3, 'valor_total': 150000.00},
      {'status': 'Pausado', 'quantidade': 5, 'valor_total': 250000.00},
    ];
  }

  /// Dados simulados de receita por cliente
  static List<Map<String, dynamic>> getReceitaMockData() {
    return [
      {
        'cliente': 'Tech Solutions Ltda',
        'receita': 450000.50,
        'projetos_total': 8,
        'projetos_ativos': 3,
      },
      {
        'cliente': 'Inovação Digital SA',
        'receita': 385200.75,
        'projetos_total': 6,
        'projetos_ativos': 2,
      },
      {
        'cliente': 'Sistemas Avançados Inc',
        'receita': 298750.30,
        'projetos_total': 5,
        'projetos_ativos': 1,
      },
      {
        'cliente': 'DataCorp Enterprises',
        'receita': 267890.25,
        'projetos_total': 7,
        'projetos_ativos': 4,
      },
      {
        'cliente': 'CloudTech Services',
        'receita': 234567.80,
        'projetos_total': 4,
        'projetos_ativos': 2,
      },
      {
        'cliente': 'AI Solutions Group',
        'receita': 198450.60,
        'projetos_total': 3,
        'projetos_ativos': 1,
      },
      {
        'cliente': 'Smart Systems Ltd',
        'receita': 156789.40,
        'projetos_total': 4,
        'projetos_ativos': 1,
      },
    ];
  }

  /// Dados simulados de métricas gerais
  static Map<String, dynamic> getMetricasGeraisMockData() {
    return {
      'novos_clientes_ano': 45,
      'projetos_ativos': 25,
      'total_funcionarios': 68,
      'vendas_mes_atual': 186750.25,
      'vendas_ano_atual': 2092453.60,
    };
  }

  /// Simula delay de rede para tornar o mock mais realista
  static Future<T> _simulateNetworkDelay<T>(T data, {Duration? delay}) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 500));
    return data;
  }

  /// Versões async dos métodos para simular chamadas de API
  static Future<List<Map<String, dynamic>>> getVendasMockDataAsync() async {
    return _simulateNetworkDelay(getVendasMockData());
  }

  static Future<List<Map<String, dynamic>>>
  getFuncionariosMockDataAsync() async {
    return _simulateNetworkDelay(getFuncionariosMockData());
  }

  static Future<List<Map<String, dynamic>>> getProjetosMockDataAsync() async {
    return _simulateNetworkDelay(getProjetosMockData());
  }

  static Future<List<Map<String, dynamic>>> getReceitaMockDataAsync() async {
    return _simulateNetworkDelay(getReceitaMockData());
  }

  static Future<Map<String, dynamic>> getMetricasGeraisMockDataAsync() async {
    return _simulateNetworkDelay(getMetricasGeraisMockData());
  }

  /// Método utilitário para simular erro de rede
  static Future<void> simulateNetworkError() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    throw Exception('Erro de conexão simulado');
  }

  /// Verifica se deve usar dados mock baseado em configuração
  static bool shouldUseMockData() {
    // Em um cenário real, isso poderia vir de SharedPreferences,
    // variáveis de ambiente, ou configuração de build
    return false; // Mude para true para usar dados mock
  }
}
