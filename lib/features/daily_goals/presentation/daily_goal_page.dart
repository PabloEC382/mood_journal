import 'package:flutter/material.dart';
import 'package:mood_journal/domain/entities/daily_goal_entity.dart';
import 'daily_goal_entity_form_dialog.dart';

class DailyGoalListPage extends StatefulWidget {
  const DailyGoalListPage({super.key, required this.entity});

  final String entity;

  @override
  State<DailyGoalListPage> createState() => _DailyGoalListPageState();
}

class _DailyGoalListPageState extends State<DailyGoalListPage>
    with SingleTickerProviderStateMixin {
  bool showTip = true;
  bool showTutorial = false;
  final List<DailyGoalEntity> items = []; // Layout-only: sem persistência
  GoalCategory? _selectedFilter; // NOVO: filtro de categoria

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

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  /// NOVO: Filtra itens por categoria selecionada
  List<DailyGoalEntity> get _filteredItems {
    if (_selectedFilter == null) return items;
    return items.where((item) => item.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // NOVO: Chips de filtro por categoria
                  if (items.isNotEmpty) _buildCategoryFilters(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildBody(context)),
                ],
              ),
            ),
          ),

          // Overlay de tutorial central
          if (showTutorial) _buildTutorialOverlay(context),

          // Opt-out button positioned bottom-left
          _buildOptOutButton(context),

          // Tip bubble positioned above FAB (bottom-right)
          if (showTip) _buildTipBubble(context),
        ],
      ),
      // Standard FAB at bottom-right with subtle scale animation
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await showDailyGoalEntityFormDialog(context);
            if (result != null) {
              setState(() {
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

  /// NOVO: Chips de filtro por categoria
  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip "Todas"
          FilterChip(
            label: const Text('Todas'),
            selected: _selectedFilter == null,
            onSelected: (selected) {
              setState(() => _selectedFilter = null);
            },
          ),
          const SizedBox(width: 8),
          // Chips de categorias
          ...GoalCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${category.icon} ${category.description}'),
                selected: _selectedFilter == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? category : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_filteredItems.isEmpty && items.isEmpty) {
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

    if (_filteredItems.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma meta na categoria ${_selectedFilter!.description}.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemBuilder: (context, index) {
        final goal = _filteredItems[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(goal.category.icon),
          ),
          title: Text('${goal.type.description} - ${goal.category.description}'),
          subtitle: Text(
            'Progresso: ${goal.progressPercentage}% (${goal.currentValue}/${goal.targetValue})',
          ),
          trailing: goal.isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _filteredItems.length,
    );
  }

  Widget _buildTutorialOverlay(BuildContext context) => Positioned.fill(
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
                  Text('Tutorial',
                      style: Theme.of(context).textTheme.titleLarge),
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
      );

  Widget _buildOptOutButton(BuildContext context) => Positioned(
        left: 16,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        child: TextButton(
          onPressed: () => setState(() {
            showTip = false;
            _fabController.stop();
            _fabController.reset();
          }),
          child: const Text('Não exibir dica novamente',
              overflow: TextOverflow.ellipsis),
        ),
      );

  Widget _buildTipBubble(BuildContext context) => Positioned(
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
                maxWidth: MediaQuery.of(context).size.width * 0.8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3))
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
      );
}