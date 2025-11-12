import 'package:flutter/material.dart';
import 'package:mood_journal/domain/entities/daily_goal_entity.dart';
import 'daily_goal_entity_form_dialog.dart';
import 'daily_goal_history_page.dart';

class DailyGoalListPage extends StatefulWidget {
  const DailyGoalListPage({super.key, required this.entity});

  final String entity;

  @override
  State<DailyGoalListPage> createState() => _DailyGoalListPageState();
}

class _DailyGoalListPageState extends State<DailyGoalListPage>
    with SingleTickerProviderStateMixin {
  // Simulação de estado local (não persistente)
  bool showTip = true;
  bool showTutorial = false;
  final List<DailyGoalEntity> items = []; // NOVO: tipado com DailyGoalEntity
  GoalCategory? _selectedCategoryFilter; // NOVO: filtro por categoria

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticInOut),
    );
    if (showTip) _fabController.repeat(reverse: true);
  }

  /// Retorna goals que devem ir para o histórico
  /// Goals histórico = data passada OU concluído
  List<DailyGoalEntity> _getHistoricalGoals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return items.where((goal) {
      final goalDate = DateTime(goal.date.year, goal.date.month, goal.date.day);
      final isPast = goalDate.isBefore(today);
      final isCompleted = goal.isCompleted;
      return isPast || isCompleted;
    }).toList();
  }


  /// Retorna lista filtrada por categoria e apenas goals ativos
  /// Goals ativos = data de hoje ou futura E não concluído
  List<DailyGoalEntity> _getFilteredItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filtrar goals ativos: data >= hoje E não concluído
    var activeGoals = items.where((goal) {
      final goalDate = DateTime(goal.date.year, goal.date.month, goal.date.day);
      final isActive = goalDate.isAtSameMomentAs(today) || goalDate.isAfter(today);
      final isNotCompleted = !goal.isCompleted;
      return isActive && isNotCompleted;
    }).toList();

    if (_selectedCategoryFilter == null) {
      return activeGoals;
    }
    return activeGoals
        .where((goal) => goal.category == _selectedCategoryFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();
    final historicalGoals = _getHistoricalGoals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas Diárias'),
        actions: [
          // Botão para acessar histórico
          if (historicalGoals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DailyGoalHistoryPage(
                          historicalGoals: historicalGoals,
                        ),
                      ),
                    );
                  },
                  child: Badge(
                    label: Text(historicalGoals.length.toString()),
                    child: const Icon(Icons.history),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // NOVO: Chips de filtro por categoria
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Chip "Todas"
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: const Text('Todas'),
                            selected: _selectedCategoryFilter == null,
                            onSelected: (_) {
                              setState(() => _selectedCategoryFilter = null);
                            },
                          ),
                        ),
                        // Chips por categoria
                        ...GoalCategory.values.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              avatar: Text(category.icon),
                              label: Text(category.description),
                              selected: _selectedCategoryFilter == category,
                              onSelected: (_) {
                                setState(() => _selectedCategoryFilter = category);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lista de metas
                  Expanded(
                    child: _buildBody(context, filteredItems),
                  ),
                ],
              ),
            ),
          ),

          // Overlay de tutorial central
          if (showTutorial)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tutorial',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aqui você verá uma lista com ${widget.entity.toUpperCase()}s. Use o botão flutuante para adicionar.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => showTutorial = false),
                          child: const Text('Entendi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Opt-out button positioned bottom-left
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: TextButton(
              onPressed: () => setState(() {
                showTip = false;
                _fabController.stop();
                _fabController.reset();
              }),
              child: const Text(
                'Não exibir dica novamente',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Tip bubble positioned above FAB (bottom-right)
          if (showTip)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 72,
              child: AnimatedBuilder(
                animation: _fabController,
                builder: (context, child) {
                  final v = _fabController.value;
                  return Transform.translate(
                    offset: Offset(0, 10 * (1 - v)),
                    child: child,
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Toque aqui para adicionar ${widget.entity.toLowerCase()}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Standard FAB at bottom-right with subtle scale animation
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () async {
            // Abre a dialog para criar/editar uma DailyGoalEntity
            final result = await showDailyGoalEntityFormDialog(context);
            if (result != null) {
              setState(() {
                // insere no topo da lista
                items.insert(0, result);
              });
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody(BuildContext context, List<DailyGoalEntity> filteredItems) {
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum ${widget.entity.toUpperCase()} cadastrado ainda.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use o botão abaixo para criar o primeiro ${widget.entity.toLowerCase()}.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lista de metas com informações
    return ListView.separated(
      itemBuilder: (context, index) {
        final goal = filteredItems[index];
        return ListTile(
          leading: Text(
            goal.category.icon,
            style: const TextStyle(fontSize: 24),
          ),
          title: Text('${goal.type.icon} ${goal.type.description}'),
          subtitle: Text(
            '${goal.currentValue}/${goal.targetValue} • ${goal.category.description}',
          ),
          trailing: goal.isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : CircularProgressIndicator(
                  value: goal.progress,
                  strokeWidth: 2,
                ),
          onTap: () async {
            final result = await showDailyGoalEntityFormDialog(
              context,
              initial: goal,
            );
            if (result != null) {
              setState(() {
                final idx = items.indexOf(goal);
                if (idx >= 0) {
                  items[idx] = result;
                }
              });
            }
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: filteredItems.length,
    );
  }
}
