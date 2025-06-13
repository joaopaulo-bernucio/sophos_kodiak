import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int _selectedTabIndex = 0;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Dados dos gráficos
  List<Map<String, dynamic>> _vendasData = [];
  List<Map<String, dynamic>> _funcionariosData = [];
  List<Map<String, dynamic>> _projetosData = [];
  List<Map<String, dynamic>> _receitaData = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  /// Carrega todos os dados dos gráficos
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carrega todos os dados em paralelo para melhor performance
      final results = await Future.wait([
        _apiService.buscarVendasPorMes(),
        _apiService.buscarFuncionariosPorDepartamento(),
        _apiService.buscarProjetosPorStatus(),
        _apiService.buscarReceitaPorCliente(),
      ]);

      setState(() {
        _vendasData = results[0];
        _funcionariosData = results[1];
        _projetosData = results[2];
        _receitaData = results[3];
      });
    } catch (e) {
      _mostrarErro('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mostra uma mensagem de erro
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Relatórios e Gráficos', style: AppTextStyles.header),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isLoading ? Icons.hourglass_empty : Icons.refresh,
              color: AppColors.textPrimary,
            ),
            onPressed: _isLoading ? null : _carregarDados,
          ),
        ],
      ),
      body: Column(
        children: [
          _TabSelector(
            selectedIndex: _selectedTabIndex,
            onTabSelected: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _getTabContent(_selectedTabIndex),
          ),
        ],
      ),
    );
  }

  /// Retorna o conteúdo da aba selecionada
  Widget _getTabContent(int index) {
    switch (index) {
      case 0:
        return _VendasTab(vendasData: _vendasData);
      case 1:
        return _FuncionariosTab(funcionariosData: _funcionariosData);
      case 2:
        return _ProjetosTab(
          projetosData: _projetosData,
          receitaData: _receitaData,
        );
      default:
        return _VendasTab(vendasData: _vendasData);
    }
  }
}

/// Seletor de abas para os diferentes tipos de relatórios
class _TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _TabSelector({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        children: [
          _TabButton(
            title: 'Vendas',
            icon: Icons.trending_up,
            isSelected: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _TabButton(
            title: 'Funcionários',
            icon: Icons.people,
            isSelected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          _TabButton(
            title: 'Projetos',
            icon: Icons.analytics,
            isSelected: selectedIndex == 2,
            onTap: () => onTabSelected(2),
          ),
        ],
      ),
    );
  }
}

/// Botão individual da aba
class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMedium,
            horizontal: AppDimensions.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aba de gráficos de vendas
class _VendasTab extends StatelessWidget {
  final List<Map<String, dynamic>> vendasData;

  const _VendasTab({required this.vendasData});

  @override
  Widget build(BuildContext context) {
    // Calcula estatísticas das vendas
    double totalVendas = 0;
    for (var venda in vendasData) {
      totalVendas += (venda['total_vendas'] ?? 0).toDouble();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricCard(
            title: 'Total de Vendas',
            value: 'R\$ ${totalVendas.toStringAsFixed(2)}',
            change: '+12.5%',
            isPositive: true,
            icon: Icons.attach_money,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _MetricCard(
            title: 'Períodos com Vendas',
            value: '${vendasData.length}',
            change: '+8.2%',
            isPositive: true,
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Vendas por Mês',
            child: vendasData.isEmpty
                ? const _EmptyChart(message: 'Nenhum dado de vendas disponível')
                : _VendasBarChart(dados: vendasData),
          ),
        ],
      ),
    );
  }
}

/// Aba de gráficos de funcionários
class _FuncionariosTab extends StatelessWidget {
  final List<Map<String, dynamic>> funcionariosData;

  const _FuncionariosTab({required this.funcionariosData});

  @override
  Widget build(BuildContext context) {
    // Calcula total de funcionários
    int totalFuncionarios = 0;
    for (var dep in funcionariosData) {
      totalFuncionarios += (dep['quantidade'] ?? 0) as int;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricCard(
            title: 'Total de Funcionários',
            value: '$totalFuncionarios',
            change: '+5.0%',
            isPositive: true,
            icon: Icons.people,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _MetricCard(
            title: 'Departamentos',
            value: '${funcionariosData.length}',
            change: '0%',
            isPositive: true,
            icon: Icons.business,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Funcionários por Departamento',
            child: funcionariosData.isEmpty
                ? const _EmptyChart(
                    message: 'Nenhum dado de funcionários disponível',
                  )
                : _FuncionariosPieChart(dados: funcionariosData),
          ),
        ],
      ),
    );
  }
}

/// Aba de gráficos de projetos e receita
class _ProjetosTab extends StatelessWidget {
  final List<Map<String, dynamic>> projetosData;
  final List<Map<String, dynamic>> receitaData;

  const _ProjetosTab({required this.projetosData, required this.receitaData});

  @override
  Widget build(BuildContext context) {
    // Calcula total de projetos
    int totalProjetos = 0;
    for (var projeto in projetosData) {
      totalProjetos += (projeto['quantidade'] ?? 0) as int;
    }

    // Calcula receita total
    double receitaTotal = 0;
    for (var receita in receitaData) {
      receitaTotal += (receita['receita'] ?? 0).toDouble();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricCard(
            title: 'Total de Projetos',
            value: '$totalProjetos',
            change: '+15.3%',
            isPositive: true,
            icon: Icons.work,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _MetricCard(
            title: 'Receita Total',
            value: 'R\$ ${receitaTotal.toStringAsFixed(2)}',
            change: '+22.1%',
            isPositive: true,
            icon: Icons.monetization_on,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Projetos por Status',
            child: projetosData.isEmpty
                ? const _EmptyChart(
                    message: 'Nenhum dado de projetos disponível',
                  )
                : _ProjetosBarChart(dados: projetosData),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Top 5 Clientes por Receita',
            child: receitaData.isEmpty
                ? const _EmptyChart(
                    message: 'Nenhum dado de receita disponível',
                  )
                : _ReceitaList(dados: receitaData),
          ),
        ],
      ),
    );
  }
}

/// Card de métrica com indicadores
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.inputHint),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.header.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? AppColors.success : AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Container para gráficos
class _ChartContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label.copyWith(fontSize: 18)),
          const SizedBox(height: AppDimensions.paddingMedium),
          child,
        ],
      ),
    );
  }
}

/// Widget para quando não há dados
class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.description.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras para vendas por mês
class _VendasBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _VendasBarChart({required this.dados});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.primaryDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${dados[group.x]['mes']}\nR\$ ${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(color: AppColors.textPrimary),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < dados.length) {
                    final mes = dados[value.toInt()]['mes'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        mes.substring(5), // Mostra apenas MM
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getMaxValue() / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'R\$ ${(value / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dados.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value['total_vendas'] ?? 0).toDouble(),
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxValue() {
    double max = 0;
    for (var item in dados) {
      final value = (item['total_vendas'] ?? 0).toDouble();
      if (value > max) max = value;
    }
    return max;
  }
}

/// Gráfico de pizza para funcionários por departamento
class _FuncionariosPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _FuncionariosPieChart({required this.dados});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: _criarSecoes(),
          centerSpaceRadius: 60,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
            enabled: true,
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _criarSecoes() {
    final cores = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.textSecondary,
    ];

    return dados.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final quantidade = (item['quantidade'] ?? 0).toInt();

      return PieChartSectionData(
        color: cores[index % cores.length],
        value: quantidade.toDouble(),
        title: '${item['departamento']}\n$quantidade',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }
}

/// Gráfico de barras para projetos por status
class _ProjetosBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _ProjetosBarChart({required this.dados});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.primaryDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${dados[group.x]['status']}\n${rod.toY.toInt()} projetos',
                  const TextStyle(color: AppColors.textPrimary),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < dados.length) {
                    final status = dados[value.toInt()]['status'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _abreviarStatus(status),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getMaxValue() / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dados.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value['quantidade'] ?? 0).toDouble(),
                  color: _getCorPorStatus(entry.value['status']),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxValue() {
    double max = 0;
    for (var item in dados) {
      final value = (item['quantidade'] ?? 0).toDouble();
      if (value > max) max = value;
    }
    return max;
  }

  String _abreviarStatus(String status) {
    switch (status.toLowerCase()) {
      case 'em andamento':
        return 'Andamento';
      case 'concluído':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      case 'em aprovação':
        return 'Aprovação';
      default:
        return status;
    }
  }

  Color _getCorPorStatus(String status) {
    switch (status.toLowerCase()) {
      case 'em andamento':
        return AppColors.primary;
      case 'concluído':
        return AppColors.success;
      case 'cancelado':
        return AppColors.error;
      case 'em aprovação':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Lista de receita por cliente
class _ReceitaList extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _ReceitaList({required this.dados});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: dados.take(5).map((item) {
        final cliente = item['cliente'] as String;
        final receita = (item['receita'] ?? 0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(cliente, style: AppTextStyles.description)),
              Text(
                'R\$ ${receita.toStringAsFixed(2)}',
                style: AppTextStyles.description.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
