import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Página de gráficos e relatórios do sistema Kodiak ERP
///
/// Esta página exibe dashboards com gráficos e métricas importantes
/// do sistema, incluindo vendas, estoque e desempenho.
class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Relatórios e Gráficos',
          style: AppTextStyles.subtitle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () {
              // Simula atualização dos dados
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dados atualizados!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
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
          Expanded(child: _getTabContent(_selectedTabIndex)),
        ],
      ),
    );
  }

  /// Retorna o conteúdo da aba selecionada
  Widget _getTabContent(int index) {
    switch (index) {
      case 0:
        return const _SalesChartsTab();
      case 1:
        return const _InventoryChartsTab();
      case 2:
        return const _PerformanceChartsTab();
      default:
        return const _SalesChartsTab();
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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
            title: 'Estoque',
            icon: Icons.inventory,
            isSelected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          _TabButton(
            title: 'Performance',
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
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusLarge,
            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aba de gráficos de vendas
class _SalesChartsTab extends StatelessWidget {
  const _SalesChartsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricCard(
            title: 'Vendas do Mês',
            value: 'R\$ 125.430,00',
            change: '+12.5%',
            isPositive: true,
            icon: Icons.attach_money,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _MetricCard(
            title: 'Pedidos Hoje',
            value: '47',
            change: '+8.2%',
            isPositive: true,
            icon: Icons.shopping_cart,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(title: 'Vendas por Período', child: _MockBarChart()),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(title: 'Top Produtos', child: _MockProductList()),
        ],
      ),
    );
  }
}

/// Aba de gráficos de estoque
class _InventoryChartsTab extends StatelessWidget {
  const _InventoryChartsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricCard(
            title: 'Produtos em Estoque',
            value: '1.247',
            change: '-2.1%',
            isPositive: false,
            icon: Icons.inventory_2,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _MetricCard(
            title: 'Valor Total',
            value: 'R\$ 89.320,00',
            change: '+3.7%',
            isPositive: true,
            icon: Icons.account_balance_wallet,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Movimentação de Estoque',
            child: _MockLineChart(),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Produtos em Falta',
            child: _MockLowStockList(),
          ),
        ],
      ),
    );
  }
}

/// Aba de gráficos de performance
class _PerformanceChartsTab extends StatelessWidget {
  const _PerformanceChartsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricCard(
            title: 'Performance Geral',
            value: '94.5%',
            change: '+5.2%',
            isPositive: true,
            icon: Icons.speed,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _MetricCard(
            title: 'Eficiência',
            value: '87.3%',
            change: '+1.8%',
            isPositive: true,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Métricas de Performance',
            child: _MockPieChart(),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _ChartContainer(
            title: 'Comparativo Mensal',
            child: _MockComparisonChart(),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusLarge,
              ),
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
                Text(
                  value,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 24),
                ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
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

/// Mock de gráfico de barras
class _MockBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: const Center(
        child: Text(
          'Gráfico de Barras\n(Integração com biblioteca de gráficos)',
          style: AppTextStyles.description,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Mock de gráfico de linha
class _MockLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: const Center(
        child: Text(
          'Gráfico de Linha\n(Integração com biblioteca de gráficos)',
          style: AppTextStyles.description,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Mock de gráfico de pizza
class _MockPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: const Center(
        child: Text(
          'Gráfico de Pizza\n(Integração com biblioteca de gráficos)',
          style: AppTextStyles.description,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Mock de gráfico comparativo
class _MockComparisonChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: const Center(
        child: Text(
          'Gráfico Comparativo\n(Integração com biblioteca de gráficos)',
          style: AppTextStyles.description,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Mock de lista de produtos
class _MockProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final products = [
      'Produto A - 127 vendas',
      'Produto B - 89 vendas',
      'Produto C - 76 vendas',
      'Produto D - 54 vendas',
    ];

    return Column(
      children: products
          .map(
            (product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.primary, size: 8),
                  const SizedBox(width: 8),
                  Text(product, style: AppTextStyles.description),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Mock de lista de produtos em falta
class _MockLowStockList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final products = [
      'Produto X - 3 unidades',
      'Produto Y - 1 unidade',
      'Produto Z - 5 unidades',
    ];

    return Column(
      children: products
          .map(
            (product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(product, style: AppTextStyles.description),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
