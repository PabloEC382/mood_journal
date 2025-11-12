import 'package:flutter/material.dart';
import 'package:mood_journal/domain/entities/daily_goal_entity.dart';

/// Página de Histórico de Metas Concluídas
/// Feature 1: Mostra estatísticas e lista de metas dos últimos 7/30 dias
class DailyGoalHistoryPage extends StatefulWidget {
  const DailyGoalHistoryPage({super.key});

  @override
  State<DailyGoalHistoryPage> createState() => _DailyGoalHistoryPageState();
}

class _DailyGoalHistoryPageState extends State<DailyGoalHistoryPage> {
  final List<DailyGoalEntity> _allGoals = []; // TODO: carregar do DAO
  int _selectedPeriod = 7; // 7 ou 30 dias

  @override
  void initState() {
    super.initState();
    // TODO: carregar metas do cache local via DAO
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    // TODO: integrar com DailyGoalLocalDao.listAll()
    // Por enquanto, simulação layout-only
    setState(() {
      // Metas de exemplo seriam carregadas aqui
    });
  }

  /// Filtra metas dos últimos N dias
  List<DailyGoalEntity> get _recentGoals {
    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedPeriod));
    return _allGoals
        .where((goal) => goal.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Calcula percentual de metas concluídas
  double get _completionRate {
    if (_recentGoals.isEmpty) return 0.0;
    final completed = _recentGoals.where((g) => g.isCompleted).length;
    return (completed / _recentGoals.length) * 100;
  }

  /// Conta metas por categoria
  Map<GoalCategory, int> get _goalsByCategory {
    final counts = <GoalCategory, int>{};
    for (final goal in _recentGoals) {
      counts[goal.category] = (counts[goal.category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Metas'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedPeriod,
            onSelected: (period) => setState(() => _selectedPeriod = period),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Últimos 7 dias')),
              const PopupMenuItem(value: 30, child: Text('Últimos 30 dias')),
            ],
          ),
        ],
      ),
      body: _allGoals.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(),
                  const SizedBox(height: 16),
                  _buildGoalsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 72,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withAlpha((0.3 * 255).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma meta registrada ainda.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Comece criando suas metas diárias!',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Card de estatísticas principais
  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Taxa de conclusão
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taxa de conclusão:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${_completionRate.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de progresso
            LinearProgressIndicator(
              value: _completionRate / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            // Resumo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _recentGoals.length.toString(),
                  Icons.calendar_today,
                ),
                _buildStatItem(
                  'Concluídas',
                  _recentGoals.where((g) => g.isCompleted).length.toString(),
                  Icons.check_circle,
                ),
                _buildStatItem(
                  'Pendentes',
                  _recentGoals.where((g) => !g.isCompleted).length.toString(),
                  Icons.pending,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Breakdown por categoria
  Widget _buildCategoryBreakdown() {
    if (_goalsByCategory.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por Categoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._goalsByCategory.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(entry.key.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key.description)),
                    Text(
                      '${entry.value} metas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Lista de metas recentes
  Widget _buildGoalsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metas Recentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentGoals.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final goal = _recentGoals[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        goal.isCompleted ? Colors.green[100] : Colors.grey[200],
                    child: Text(goal.category.icon),
                  ),
                  title: Text(goal.type.description),
                  subtitle: Text(
                    '${goal.category.description} • ${_formatDate(goal.date)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: goal.isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : Text('${goal.progressPercentage}%'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff < 7) return '$diff dias atrás';
    return '${date.day}/${date.month}/${date.year}';
  }
}