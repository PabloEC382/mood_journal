Prompt 01: Adicionar Categoria à Entity (Domain Layer)

1. Objetivo Principal

# 01.1 - Objetivo: Adicionar GoalCategory à DailyGoalEntity

**Finalidade**
Integrar o campo `category` (tipo `GoalCategory` enum) na `DailyGoalEntity` para categorização semântica (Saúde, Estudo, Trabalho, Pessoal) no **Domain Layer**.

**Arquivo Alvo**
`lib/domain/entities/daily_goal_entity.dart`

**Requisitos Essenciais**
1. **Enum Creation:** Criar `enum GoalCategory` com 4 valores e propriedades de UI (`description`, `icon`, `colorEmoji`).
2. **Entity Update:** Adicionar `required final GoalCategory category;` à `DailyGoalEntity`.
3. **Resilience:** Implementar `GoalCategory.fromString(String value)` com *fallback* para `GoalCategory.personal`.

**Saída**
`daily_goal_entity.dart` atualizado, com consistência total em `copyWith`, `operator ==`, `hashCode` e `toString`.

2. Instruções de Implementação

# 01.2 - Instruções Detalhadas de Implementação (Entity)

**Passos em `lib/domain/entities/daily_goal_entity.dart`**

1.  **Definir `enum GoalCategory`:**
    * Incluir 4 categorias: `health`, `study`, `work`, `personal`.
    * Definir propriedades `final String description;`, `final String icon;`, `final String colorEmoji;`.

2.  **Implementar `fromString`:**
    * Adicionar `static GoalCategory fromString(String value)` ao enum.
    * A conversão deve ser pelo `category.name == value`.
    * Usar `orElse: () => GoalCategory.personal` como *fallback*.

3.  **Modificar `DailyGoalEntity`:**
    * Adicionar `required this.category,` ao construtor.
    * Incluir `final GoalCategory category;` na declaração de campos.
    * Atualizar `copyWith`, `operator ==`, `hashCode` e `toString` para incluir o novo campo.

**Regra Chave**
O campo `category` é obrigatório (`required`) e imutável (`final`).

3. Contexto Arquitetural e Validação

# 01.3 - Contexto e Invariantes de Domínio (Entity)

**Princípios Arquiteturais**
* **Imutabilidade:** A Entity deve manter-se imutável (`final` fields).
* **Integridade:** O uso do `enum GoalCategory` (ao invés de `String`) garante *type safety* em tempo de compilação.
* **Resiliência:** O *fallback* em `GoalCategory.fromString()` absorve dados inválidos do Data Layer sem quebrar o Domínio.

