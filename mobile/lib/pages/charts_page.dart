import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/message_service.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;
  late TabController _tabController;
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  List<Map<String, dynamic>> _vendasData = [];
  List<Map<String, dynamic>> _funcionariosData = [];
  List<Map<String, dynamic>> _projetosData = [];
  List<Map<String, dynamic>> _receitaData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.elasticOut),
    );
    _carregarDados();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    if (_refreshController.isAnimating) {
      _refreshController.stop();
    }
    _refreshController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (_isLoading || _isDisposed) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (mounted && !_isDisposed && !_refreshController.isAnimating) {
      _refreshController.forward();
    }

    try {
      final results = await Future.wait([
        _apiService.buscarVendasPorMes(),
        _apiService.buscarFuncionariosPorDepartamento(),
        _apiService.buscarProjetosPorStatus(),
        _apiService.buscarReceitaPorCliente(),
      ]);

      if (mounted) {
        setState(() {
          _vendasData = results[0];
          _funcionariosData = results[1];
          _projetosData = results[2];
          _receitaData = results[3];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _tratarErro(e);
        });
        _mostrarErro(_errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (!_isDisposed &&
            !_refreshController.isAnimating &&
            !_refreshController.isDismissed) {
          _refreshController.reset();
        }
      }
    }
  }

  String _tratarErro(dynamic erro) {
    if (erro is ApiException) {
      switch (erro.statusCode) {
        case 404:
          return 'Dados não encontrados. Verifique se o servidor está funcionando.';
        case 500:
          return 'Erro interno do servidor. Tente novamente em alguns minutos.';
        case null:
          return 'Erro de conexão. Verifique sua internet e tente novamente.';
        default:
          return 'Erro no servidor (${erro.statusCode}). Tente novamente.';
      }
    }
    return 'Erro ao carregar dados: ${erro.toString()}';
  }

  void _mostrarErro(String mensagem) {
    MessageService.showError(
      context,
      message: mensagem,
      title: 'Erro ao carregar dados',
      duration: const Duration(seconds: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingIndicator() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: const Text('Relatórios e Gráficos', style: AppTextStyles.title),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Builder(
          builder: (context) {
            if (!mounted || _isDisposed) {
              return IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _isLoading ? null : _carregarDados,
                tooltip: 'Atualizar dados',
              );
            }

            return AnimatedBuilder(
              animation: _refreshAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshAnimation.value * 2 * 3.14159,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _isLoading ? null : _carregarDados,
                    tooltip: 'Atualizar dados',
                  ),
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
          onPressed: _mostrarInformacoes,
          tooltip: 'Informações',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.trending_up), text: 'Vendas'),
          Tab(icon: Icon(Icons.people), text: 'Funcionários'),
          Tab(icon: Icon(Icons.work), text: 'Projetos'),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text('Carregando dados...', style: AppTextStyles.primaryText),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _VendasTab(vendasData: _vendasData),
        _FuncionariosTab(funcionariosData: _funcionariosData),
        _ProjetosTab(projetosData: _projetosData, receitaData: _receitaData),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: AppTextStyles.title.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erro desconhecido',
              style: AppTextStyles.primaryText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregarDados,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarInformacoes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elementsBackground,
        title: const Text('Sobre os Gráficos', style: AppTextStyles.title),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vendas: Mostra o total de vendas por mês',
                style: AppTextStyles.primaryText,
              ),
              SizedBox(height: 8),
              Text(
                'Funcionários: Distribuição por departamento',
                style: AppTextStyles.primaryText,
              ),
              SizedBox(height: 8),
              Text(
                'Projetos: Status dos projetos e receita por cliente',
                style: AppTextStyles.primaryText,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendasTab extends StatelessWidget {
  final List<Map<String, dynamic>> vendasData;

  const _VendasTab({required this.vendasData});

  @override
  Widget build(BuildContext context) {
    if (vendasData.isEmpty) {
      return const _EmptyChart(
        message: 'Nenhum dado de vendas disponível',
        icon: Icons.trending_up,
      );
    }

    final totalVendas = _calcularTotalVendas();
    final mediaVendas = totalVendas / vendasData.length;
    final melhorMes = _encontrarMelhorMes();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total de Vendas',
                  value: _formatarMoeda(totalVendas),
                  change: '+12.5%',
                  isPositive: true,
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Média Mensal',
                  value: _formatarMoeda(mediaVendas),
                  change: '+8.2%',
                  isPositive: true,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ChartContainer(
            title: 'Vendas por Mês',
            subtitle: melhorMes.isNotEmpty ? 'Melhor mês: $melhorMes' : null,
            child: _VendasBarChart(dados: vendasData),
          ),
        ],
      ),
    );
  }

  double _calcularTotalVendas() {
    return vendasData.fold(0.0, (total, item) {
      return total + ((item['total_vendas'] ?? 0) as num).toDouble();
    });
  }

  String _encontrarMelhorMes() {
    if (vendasData.isEmpty) return '';

    final melhor = vendasData.reduce((a, b) {
      final valorA = (a['total_vendas'] ?? 0) as num;
      final valorB = (b['total_vendas'] ?? 0) as num;
      return valorA > valorB ? a : b;
    });

    return melhor['mes']?.toString() ?? '';
  }

  String _formatarMoeda(double valor) {
    if (valor >= 1000000) {
      return 'R\$ ${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return 'R\$ ${(valor / 1000).toStringAsFixed(1)}K';
    }
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}

class _FuncionariosTab extends StatelessWidget {
  final List<Map<String, dynamic>> funcionariosData;

  const _FuncionariosTab({required this.funcionariosData});

  @override
  Widget build(BuildContext context) {
    if (funcionariosData.isEmpty) {
      return const _EmptyChart(
        message: 'Nenhum dado de funcionários disponível',
        icon: Icons.people,
      );
    }

    final totalFuncionarios = funcionariosData.fold(0, (total, item) {
      return total + ((item['quantidade'] ?? 0) as int);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total de Funcionários',
                  value: totalFuncionarios.toString(),
                  change: '+5.2%',
                  isPositive: true,
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Departamentos',
                  value: funcionariosData.length.toString(),
                  change: 'Ativos',
                  isPositive: true,
                  icon: Icons.business,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ChartContainer(
            title: 'Funcionários por Departamento',
            child: _FuncionariosPieChart(dados: funcionariosData),
          ),
        ],
      ),
    );
  }
}

class _ProjetosTab extends StatelessWidget {
  final List<Map<String, dynamic>> projetosData;
  final List<Map<String, dynamic>> receitaData;

  const _ProjetosTab({required this.projetosData, required this.receitaData});

  @override
  Widget build(BuildContext context) {
    if (projetosData.isEmpty && receitaData.isEmpty) {
      return const _EmptyChart(
        message: 'Nenhum dado de projetos disponível',
        icon: Icons.work,
      );
    }

    final totalProjetos = projetosData.fold(0, (total, item) {
      return total + ((item['quantidade'] ?? 0) as int);
    });

    final receitaTotal = receitaData.fold(0.0, (total, item) {
      return total + ((item['receita'] ?? 0) as num).toDouble();
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total de Projetos',
                  value: totalProjetos.toString(),
                  change: '+15.3%',
                  isPositive: true,
                  icon: Icons.work,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Receita Total',
                  value: _formatarMoeda(receitaTotal),
                  change: '+22.1%',
                  isPositive: true,
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (projetosData.isNotEmpty)
            _ChartContainer(
              title: 'Projetos por Status',
              child: _ProjetosBarChart(dados: projetosData),
            ),
          if (projetosData.isNotEmpty && receitaData.isNotEmpty)
            const SizedBox(height: 20),
          if (receitaData.isNotEmpty)
            _ChartContainer(
              title: 'Top Clientes por Receita',
              child: _ReceitaList(dados: receitaData),
            ),
        ],
      ),
    );
  }

  String _formatarMoeda(double valor) {
    if (valor >= 1000000) {
      return 'R\$ ${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return 'R\$ ${(valor / 1000).toStringAsFixed(1)}K';
    }
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}

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
        color: AppColors.elementsBackground,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.primaryText.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.title.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AppColors.success : AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _ChartContainer({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.elementsBackground,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 18)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.primaryText),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyChart({
    required this.message,
    this.icon = Icons.analytics_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.primaryText.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VendasBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _VendasBarChart({required this.dados});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.primaryDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final mes = dados[group.x]['mes'].toString();
                final valor = rod.toY;
                return BarTooltipItem(
                  '$mes\n${_formatarMoeda(valor)}',
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
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
                  final index = value.toInt();
                  if (index >= 0 && index < dados.length) {
                    final mes = dados[index]['mes'].toString();
                    final mesFormatado = mes.length >= 7
                        ? mes.substring(5)
                        : mes;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        mesFormatado,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                interval: _getMaxValue() / 4,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatarValorEixo(value),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxValue() / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: dados.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final valor = (item['total_vendas'] ?? 0).toDouble();

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: valor,
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
    if (dados.isEmpty) return 100;
    final maxValue = dados
        .map((item) => (item['total_vendas'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue : 100;
  }

  String _formatarValorEixo(double valor) {
    if (valor >= 1000000) {
      return '${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return '${(valor / 1000).toStringAsFixed(0)}K';
    }
    return valor.toStringAsFixed(0);
  }

  String _formatarMoeda(double valor) {
    if (valor >= 1000000) {
      return 'R\$ ${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return 'R\$ ${(valor / 1000).toStringAsFixed(1)}K';
    }
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}

class _FuncionariosPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _FuncionariosPieChart({required this.dados});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: _criarSecoes(),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _buildLegenda()),
        ],
      ),
    );
  }

  Widget _buildLegenda() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dados.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final cor = _getCor(index);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['departamento']?.toString() ?? 'N/A',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _criarSecoes() {
    final total = dados.fold(
      0,
      (sum, item) => sum + ((item['quantidade'] ?? 0) as int),
    );

    return dados.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final quantidade = (item['quantidade'] ?? 0).toInt();
      final porcentagem = total > 0 ? (quantidade / total * 100) : 0;

      return PieChartSectionData(
        color: _getCor(index),
        value: quantidade.toDouble(),
        title: '${porcentagem.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
    }).toList();
  }

  Color _getCor(int index) {
    final cores = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
    ];
    return cores[index % cores.length];
  }
}

class _ProjetosBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _ProjetosBarChart({required this.dados});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.primaryDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final status = dados[group.x]['status'].toString();
                final quantidade = rod.toY.toInt();
                return BarTooltipItem(
                  '$status\n$quantidade projetos',
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
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
                  final index = value.toInt();
                  if (index >= 0 && index < dados.length) {
                    final status = dados[index]['status'].toString();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _abreviarStatus(status),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
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
                interval: _getMaxValue() / 4,
                reservedSize: 40,
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
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxValue() / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: dados.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final quantidade = (item['quantidade'] ?? 0).toDouble();
            final status = item['status'].toString();

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: quantidade,
                  color: _getCorPorStatus(status),
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
    if (dados.isEmpty) return 10;
    final maxValue = dados
        .map((item) => (item['quantidade'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue : 10;
  }

  String _abreviarStatus(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'em andamento':
        return 'Andamento';
      case 'concluído':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      case 'em aprovação':
        return 'Aprovação';
      case 'pausado':
        return 'Pausado';
      default:
        return status.length > 10 ? status.substring(0, 10) : status;
    }
  }

  Color _getCorPorStatus(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'em andamento':
        return AppColors.primary;
      case 'concluído':
        return AppColors.success;
      case 'cancelado':
        return AppColors.error;
      case 'em aprovação':
        return AppColors.warning;
      case 'pausado':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }
}

class _ReceitaList extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const _ReceitaList({required this.dados});

  @override
  Widget build(BuildContext context) {
    final topClientes = dados.take(5).toList();

    return Column(
      children: topClientes.asMap().entries.map((entry) {
        final index = entry.key;
        final cliente = entry.value;
        final receita = (cliente['receita'] ?? 0).toDouble();
        final nomeCliente = cliente['cliente']?.toString() ?? 'Cliente N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: index == 0
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: index == 0
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getCorRanking(index),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeCliente,
                      style: AppTextStyles.primaryText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _calcularPorcentagem(receita),
                      style: AppTextStyles.primaryText.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatarMoeda(receita),
                    style: AppTextStyles.primaryText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (index == 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getRankingLabel(index),
                      style: TextStyle(
                        color: _getCorRanking(index),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCorRanking(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primary;
    }
  }

  String _getRankingLabel(int index) {
    switch (index) {
      case 0:
        return 'Premium';
      case 1:
        return 'Gold';
      case 2:
        return 'Silver';
      default:
        return 'Cliente';
    }
  }

  String _formatarMoeda(double valor) {
    if (valor >= 1000000) {
      return 'R\$ ${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return 'R\$ ${(valor / 1000).toStringAsFixed(1)}K';
    }
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }

  String _calcularPorcentagem(double receita) {
    final total = dados.fold(
      0.0,
      (sum, item) => sum + ((item['receita'] ?? 0) as num).toDouble(),
    );
    if (total == 0) return '0%';
    final porcentagem = (receita / total * 100).toStringAsFixed(1);
    return '$porcentagem% do total';
  }
}
