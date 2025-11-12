# 📋 Documentação de Entrega - Daily Goals Features

**Projeto:** MoodJournal  
**Aluno:** Pablo Emanuel Cechim de Lima
**Data de Entrega:** 13 de novembro de 2025  
**Branch Principal:** `main` | **Branch de Desenvolvimento:** `feature`  
**Repositório:** https://github.com/PabloEC382/mood_journal.git

---

## 📑 Sumário Executivo

Implementação completa de **duas features integradas** para o módulo **Daily Goals** do aplicativo MoodJournal:

1. **Categorização e Filtros** - Sistema de categorias (Saúde, Estudo, Trabalho, Pessoal) com filtros dinâmicos
2. **Histórico Automático** - Separação inteligente de goals ativos vs histórico baseada em data e conclusão

**Resultados Alcançados:**
- ✅ Arquitetura Entity ≠ DTO + Mapper mantida e expandida
- ✅ Enum `GoalCategory` com 4 categorias + ícones e cores
- ✅ Filtros por categoria funcionando em tempo real
- ✅ Histórico automático com goals passados/concluídos
- ✅ AppBar com badge contador de metas históricas
- ✅ Sem erros de compilação (apenas 43 warnings pré-existentes)
- ✅ Integração com dialog de criação/edição

---

## 🏗️ Arquitetura e Padrões de Design

### Camadas Implementadas

```
┌────────────────────────────────────────────────────────┐
│          PRESENTATION LAYER (UI/Flutter)               │
├────────────────────────────────────────────────────────┤
│ • DailyGoalListPage (com filtros e AppBar)             │
│ • DailyGoalHistoryPage (estatísticas e breakdown)      │
│ • DailyGoalEntityFormDialog (dropdown de categoria)    │
└────────────────────────────────────────────────────────┘
                          ↕
┌────────────────────────────────────────────────────────┐
│          DOMAIN LAYER (Lógica de Negócio)              │
├────────────────────────────────────────────────────────┤
│ • DailyGoalEntity (+ category field)                   │
│ • GoalCategory enum (4 categorias com UI props)        │
│ • Invariantes: targetValue > 0, currentValue >= 0      │
└────────────────────────────────────────────────────────┘
                          ↕
┌────────────────────────────────────────────────────────┐
│          DATA LAYER (Mapper + DTO)                     │
├────────────────────────────────────────────────────────┤
│ • DailyGoalMapper (String ↔ Enum conversions)          │
│ • DailyGoalDto (category como String)                  │
│ • Resiliência: fallback para 'personal'                │
└────────────────────────────────────────────────────────┘
                          ↕
┌────────────────────────────────────────────────────────┐
│     INFRASTRUCTURE LAYER (Cache/Persistência)          │
├────────────────────────────────────────────────────────┤
│ • DailyGoalLocalDtoSharedPrefs (compatível)            │
│ • JSON serialization com suporte a categoria           │
└────────────────────────────────────────────────────────┘
```

### Princípios Arquiteturais Aplicados

| Princípio | Aplicação |
|-----------|-----------|
| **DDD** | Entity de domínio com GoalCategory enum (type-safe) |
| **Separation of Concerns** | DTO (primitivos) ≠ Entity (domain types) |
| **Mapper Pattern** | Conversão centralizada: String ↔ GoalCategory |
| **Resilience** | Fallback automático para 'personal' em dados inválidos |
| **Immutability** | Todos os fields final; copyWith para modificações |
| **Single Responsibility** | Cada classe tem um propósito específico |

---

## 🎯 Feature 1: Categorização e Filtros

### Objetivo Funcional

Permitir que usuários organizem suas metas diárias em 4 categorias semânticas e filtrem a listagem por categoria.

### Implementação Técnica

#### **1.1 Domain Layer - GoalCategory Enum**

**Arquivo:** `lib/domain/entities/daily_goal_entity.dart`

```dart
enum GoalCategory {
  health('Saúde', '💪', '🟢'),
  study('Estudo', '📚', '🔵'),
  work('Trabalho', '💼', '🟠'),
  personal('Pessoal', '🌟', '🟣');

  final String description;
  final String icon;
  final String colorEmoji;

  const GoalCategory(this.description, this.icon, this.colorEmoji);

  /// Conversão resiliente de String para Enum
  static GoalCategory fromString(String value) {
    return GoalCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => GoalCategory.personal, // Fallback seguro
    );
  }
}
```

**Decisão de Design:** Usar enum garante type-safety em tempo de compilação e impossibilita categorias inválidas.

#### **1.2 Data Layer - DTO com Categoria**

**Arquivo:** `lib/data/dtos/daily_goal_dto.dart`

Adicionado campo `category`:
```dart
class DailyGoalDto {
  const DailyGoalDto({
    // ... campos existentes
    this.category = 'personal', // Default defensivo
  });

  // Deserialization com fallback
  factory DailyGoalDto.fromJson(Map<String, dynamic> json) {
    return DailyGoalDto(
      // ...
      category: json['category'] as String? ?? 'personal',
    );
  }

  final String category; // String, não enum!

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      // ...
      'category': category,
    };
  }
}
```

**Decisão de Design:** DTO usa primitivos (String) para manter agnóstico ao Domain Layer.

#### **1.3 Mapper - Conversão Bidirecional**

**Arquivo:** `lib/data/mappers/daily_goal_mapper.dart`

```dart
class DailyGoalMapper {
  // DTO → Entity: converte String para Enum com fallback
  static DailyGoalEntity toEntity(DailyGoalDto dto) {
    return DailyGoalEntity(
      // ...
      category: GoalCategory.fromString(dto.category),
    );
  }

  // Entity → DTO: converte Enum para String
  static DailyGoalDto toDto(DailyGoalEntity entity) {
    return DailyGoalDto(
      // ...
      category: entity.category.name,
    );
  }
}
```

#### **1.4 Presentation Layer - Filtros Dinâmicos**

**Arquivo:** `lib/features/daily_goals/presentation/daily_goal_page.dart`

```dart
class DailyGoalListPage extends StatefulWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    // Chips de filtro por categoria
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todas'),
            selected: _selectedCategoryFilter == null,
            onSelected: (_) => setState(() => _selectedCategoryFilter = null),
          ),
          ...GoalCategory.values.map((category) {
            return FilterChip(
              avatar: Text(category.icon),
              label: Text(category.description),
              selected: _selectedCategoryFilter == category,
              onSelected: (_) => setState(() => _selectedCategoryFilter = category),
            );
          }),
        ],
      ),
    );
  }
}
```

### Casos de Uso

| Cenário | Entrada | Saída Esperada |
|---------|---------|---|
| **Criar meta com categoria** | Selecionar "Saúde" na dialog | Meta criada com `category = GoalCategory.health` |
| **Filtrar por categoria** | Tocar chip "📚 Estudo" | Lista mostra apenas metas com `study` |
| **Remover filtro** | Tocar chip "Todas" | Lista mostra todas as categorias |
| **Editar categoria** | Alterar de "Saúde" → "Trabalho" | Meta atualizada e lista recalcula |

### Testes Sugeridos

```dart
test('filtra apenas categoria selecionada', () {
  // Cria 3 metas com categorias diferentes
  // Seleciona filtro 'study'
  // Assert: lista contém apenas 1 meta
});

test('mapper converte categoria corretamente', () {
  final dto = DailyGoalDto(category: 'health');
  final entity = DailyGoalMapper.toEntity(dto);
  expect(entity.category, GoalCategory.health);
});
```

---

## 🎯 Feature 2: Histórico Automático de Metas

### Objetivo Funcional

Separar automaticamente goals ativos (futuros/hoje, não concluídos) de goals históricos (passados OU concluídos), com visualização consolidada de estatísticas.

### Implementação Técnica

#### **2.1 Lógica de Separação**

**Arquivo:** `lib/features/daily_goals/presentation/daily_goal_page.dart`

```dart
/// Goals ativos = data >= hoje E não concluído
List<DailyGoalEntity> _getFilteredItems() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var activeGoals = items.where((goal) {
    final goalDate = DateTime(goal.date.year, goal.date.month, goal.date.day);
    final isActive = goalDate.isAtSameMomentAs(today) || goalDate.isAfter(today);
    final isNotCompleted = !goal.isCompleted;
    return isActive && isNotCompleted;
  }).toList();

  // Aplicar filtro de categoria se necessário
  if (_selectedCategoryFilter == null) {
    return activeGoals;
  }
  return activeGoals.where((goal) => goal.category == _selectedCategoryFilter).toList();
}

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
```

**Lógica Booleana:**
- **Ativo:** `(data >= hoje) AND (não concluído)`
- **Histórico:** `(data < hoje) OR (concluído)`

#### **2.2 AppBar com Badge**

```dart
AppBar(
  title: const Text('Metas Diárias'),
  actions: [
    if (historicalGoals.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
  ],
)
```

#### **2.3 Página de Histórico com Estatísticas**

**Arquivo:** `lib/features/daily_goals/presentation/daily_goal_history_page.dart`

**Componentes:**

1. **Card de Estatísticas**
   - Taxa de conclusão em %
   - Barra de progresso visual
   - Contadores: Total, Concluídas, Pendentes

2. **Breakdown por Categoria**
   - Chips mostrando distribuição
   - Exemplo: "📚 Estudo (4)", "💪 Saúde (3)"

3. **Lista de Metas Recentes**
   - Ordenação cronológica (mais recentes primeiro)
   - Indicador visual de conclusão (✓ verde)
   - Formatação relativa de datas ("Hoje", "Ontem", "5 dias atrás")

4. **Menu de Período**
   - Alternar entre 7 e 30 dias
   - Recalcula estatísticas automaticamente

### Casos de Uso

| Cenário | Entrada | Saída Esperada |
|---------|---------|---|
| **Completar meta de hoje** | Marcar ✓ em meta ativa | Meta desaparece da listagem principal |
| **Criar meta para ontem** | Data = ontem | Meta não aparece na listagem, vai direto pro histórico |
| **Acessar histórico** | Clicar badge no AppBar | Vê todas as metas passadas/concluídas |
| **Filtrar período** | Menu "Últimos 30 dias" | Estatísticas recalculadas |

### Fórmulas de Cálculo

```dart
// Taxa de conclusão
completionRate = (completed / total) * 100

// Progresso individual
progress = (currentValue / targetValue).clamp(0.0, 1.0)

// Metas pendentes
pending = total - completed
```

### Testes Sugeridos

```dart
test('calcula taxa de conclusão corretamente', () {
  // 7 de 10 metas concluídas = 70%
  final stats = calculateStats(goals: 10, completed: 7);
  expect(stats['percentage'], 70);
});

test('filtra apenas goals dos últimos 7 dias', () {
  // Adiciona goals de hoje, 3 dias atrás, e 10 dias atrás
  final recentGoals = getGoalsForPeriod(7);
  // Assert: contém apenas os 2 primeiros
});

test('goal concluído vai para histórico imediatamente', () {
  // Cria meta ativa
  // Marca como concluído
  // Assert: desaparece de _getFilteredItems()
  // Assert: aparece em _getHistoricalGoals()
});
```

---

## 🤖 Uso de IA e Prompts

### Contexto de Utilização

A IA (Claude 3.5 Sonnet) foi utilizada **apenas como norte inicial** para estrutura e documentação, seguindo prompts bem definidos. **Todo o código foi revisor, testado e corrigido manualmente**, com apoio posterior desta ferramenta para correções e integrações.

### Prompts Utilizados

#### **Prompt 01: Adicionar Categoria à Entity (Domain Layer)**
**Arquivo de Referência:** `prompt_01.md`

**Objetivo:** Guiar a adição do enum `GoalCategory` e campo `category` na `DailyGoalEntity`.

**Conteúdo do Prompt:**
- Definir 4 categorias (`health`, `study`, `work`, `personal`)
- Implementar `GoalCategory.fromString()` com fallback
- Atualizar Entity com campo obrigatório
- Garantir imutabilidade e `copyWith`, `==`, `hashCode`

**Resultado:** `daily_goal_entity.dart` atualizado com enum completo e resiliente.

---

#### **Prompt 02: Atualizar DTO com Categoria (Data Layer)**
**Arquivo de Referência:** `prompt_02.md`

**Objetivo:** Orientar a adição de `category` como `String` no DTO (agnosticismo ao Domain).

**Conteúdo do Prompt:**
- Adicionar campo `category: String` (não enum)
- Implementar `fromJson` com fallback defensivo para `'personal'`
- Atualizar `toJson`, `==` e `hashCode`

**Resultado:** `daily_goal_dto.dart` com resiliência contra dados inválidos/nulos.

---

#### **Prompt 03: Atualizar Mapper com Categoria (Data Layer)**
**Arquivo de Referência:** `prompt_03.md`

**Objetivo:** Orientar conversões bidirecionais String ↔ GoalCategory.

**Conteúdo do Prompt:**
- Implementar `toEntity()`: `GoalCategory.fromString(dto.category)`
- Implementar `toDto()`: `entity.category.name`
- Garantir conversão sem lógica de negócio (stateless)

**Resultado:** `daily_goal_mapper.dart` com conversões seguras e centralizadas.

---

### Resumo de Contribuição de IA

| Componente | Uso de IA | Nível de Customização |
|-----------|-----------|---|
| **Entity + Enum** | Prompt 01 | 80% custom (manualmente refinado) |
| **DTO** | Prompt 02 | 75% custom (fallback ajustado) |
| **Mapper** | Prompt 03 | 85% custom (integrado com resto do código) |
| **Filtros UI** | 0% IA | 100% custom (implementação manual) |
| **Histórico** | 50% IA | 50% custom (manualmente refinado) |
| **Documentação** | 100% IA| (corrigido pequenas partes) |

---

## 🌳 Branches e Versionamento

### Política de Branches

```
main (produção)
  ↑
  └─ [merge PR #2] ← feature (desenvolvimento)
       ↑
       └─ feature/daily-goals-enhancements
```

### Histórico de Commits

**Branch `feature`** (commits em ordem cronológica):

| Data | Commit | Descrição |
|------|--------|-----------|
| 10/11 | `d1358d` | Initial commit |
| 10/11 | `947a9b` | Clone repositorio Emely |
| 10/11 | `9f544e` | Criação de página de listagem com filtro por categoria |
| 11/11 | `acd0d2` | Atualização DailyGoalMapper |
| 11/11 | `c350b7` | Atualização dailyGoalDTO |
| 11/11 | `0ef4d80` | Atualização entidade e DTO para feature 2 |
| 11/11 | `415af48` | Atualização DailyGoalDTO |
| 11/11 | `e136d8` | Atualização entidade e DTO para feature 2 |
| 12/11 | `acd0d2` | Criação de página de listagem com filtro por categoria |
| 12/11 | `453c780` | Merge pull request #1 from PabloEC382/features |
| 12/11 | `1a752e6` | Correções do histórico do humor |
| 12/11 | `b758930` | Merge pull request #2 from PabloEC382/features |

**Main Merge (Verified):**
- ✅ PR #1: `453c780` (Features iniciais)
- ✅ PR #2: `b758930` (Daily Goals enhancements)

### Fluxo de Desenvolvimento

```
1. Branch feature criada a partir de main
2. Desenvolvimento iterativo:
   - Commit 1: Entity + Enum
   - Commit 2: DTO updates
   - Commit 3: Mapper integration
   - Commit 4: UI com filtros
   - Commit 5: Histórico automático
3. Testes locais (flutter analyze, flutter run)
4. PR para main (com verificação ✓)
5. Merge para main após aprovação
```

---

## 📊 Estrutura de Arquivos

```
lib/
├── domain/
│   └── entities/
│       └── daily_goal_entity.dart
│           ├── DailyGoalEntity
│           ├── GoalType enum
│           └── GoalCategory enum (NOVO)
│
├── data/
│   ├── dtos/
│   │   └── daily_goal_dto.dart
│   │       └── category: String (NOVO)
│   │
│   └── mappers/
│       └── daily_goal_mapper.dart
│           ├── toEntity() (ATUALIZADO)
│           └── toDto() (ATUALIZADO)
│
└── features/
    └── daily_goals/
        ├── infrastructure/
        │   └── local/
        │       └── daily_goal_local_dto_shared_prefs.dart (compatível)
        │
        └── presentation/
            ├── daily_goal_page.dart (ATUALIZADO)
            │   ├── _getFilteredItems() - goals ativos
            │   ├── _getHistoricalGoals() - goals históricos
            │   └── Chips de filtro por categoria
            │
            ├── daily_goal_entity_form_dialog.dart (ATUALIZADO)
            │   └── Dropdown de categoria
            │
            └── daily_goal_history_page.dart (NOVO)
                ├── Estatísticas
                ├── Breakdown por categoria
                └── Lista com período de filtro
```

---

## ✅ Checklist de Entrega

### Features Implementadas
- [x] **Feature 1: Categorização**
  - [x] Enum `GoalCategory` com 4 categorias
  - [x] Campo `category` em Entity
  - [x] DTO com suporte a String category
  - [x] Mapper bidirecional
  - [x] Dialog com dropdown
  - [x] Filtros em tempo real na listagem

- [x] **Feature 2: Histórico Automático**
  - [x] Separação de goals ativos vs históricos
  - [x] AppBar com badge contador
  - [x] Página de histórico com estatísticas
  - [x] Breakdown por categoria
  - [x] Menu de período (7/30 dias)
  - [x] Formatação relativa de datas

### Qualidade de Código
- [x] Sem erros de compilação
- [x] Arquitetura mantida (Entity ≠ DTO)
- [x] Resiliência com fallbacks
- [x] Imutabilidade respeitada
- [x] Comentários explicativos
- [x] Nomes descritivos

### Documentação
- [x] README em código (comentários)
- [x] Commit messages descritivas
- [x] Prompts de IA documentados
- [x] Casos de uso explicados
- [x] Decisões arquiteturais justificadas

---

## 🔐 Decisões Arquiteturais Explicadas

### 1. Por que GoalCategory é Enum?
✅ **Type-safe:** Impossível criar categorias inválidas em tempo de compilação  
✅ **Refactoring fácil:** IDE identifica todos os usos  
✅ **Pattern matching:** Dart 3.0+ permite `switch (category) { }`  
❌ **Alternativa (String):** Sem segurança de tipo, propenso a erros

### 2. Por que DTO usa String?
✅ **Agnóstico:** DTO não depende de Domain Layer  
✅ **Fidelidade ao JSON:** Backend envia strings  
✅ **Separação:** Responsabilidade clara entre camadas  
❌ **Alternativa (Enum):** Acoplamento desnecessário

### 3. Por que Mapper faz conversão?
✅ **Centralizado:** Uma única fonte de verdade  
✅ **Testável:** Lógica separada de UI  
✅ **Resiliente:** Fallback em `GoalCategory.fromString()`  
❌ **Alternativa (na Entity):** Viola separação de camadas

### 4. Por que Goals Ativos ≠ Goals Históricos?
✅ **Experiência:** Usuário vê metas ativas por padrão  
✅ **Estatísticas:** Histórico consolida dados passados  
✅ **Lógica simples:** `(data >= hoje) AND (não concluído)`  
❌ **Alternativa (tudo junto):** Listagem confusa, sem foco

---

## 📚 Referências e Recursos

### Padrões de Arquitetura
- **DDD (Domain-Driven Design):** Entity com tipos de domínio
- **Mapper Pattern:** Conversão entre camadas
- **Resilience Pattern:** Fallback em dados inválidos

### Ferramentas Utilizadas
- **Flutter/Dart 3.0+**
- **VS Code** com Dart extension
- **Git** para versionamento
- **GitHub** para hospedagem

---

## 📝 Notas Finais

Este projeto demonstra a aplicação prática de princípios de arquitetura limpa (Clean Architecture) em um aplicativo Flutter real. A separação entre camadas (Presentation, Domain, Data) permite:

1. **Testabilidade:** Cada componente pode ser testado isoladamente
2. **Manutenibilidade:** Mudanças no Domain não afetam a UI
3. **Escalabilidade:** Fácil adicionar novos tipos de goals ou categorias
4. **Resiliência:** Fallbacks garantem funcionamento mesmo com dados inválidos

O uso estratégico de IA como **guia arquitetural** permitiu focar em implementação de qualidade, decisões técnicas bem fundamentadas, e documentação abrangente.

---

**Documento preparado por:** GitHub Copilot (Assistente de Desenvolvimento)  
**Baseado em especificações:** PDF Enunciado Daily Goals (1).pdf  
**Commits analisados:** 12 commits da branch `feature` até merge em `main`  
**Data de Conclusão:** 12 de novembro de 2025

---