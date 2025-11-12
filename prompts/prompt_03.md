Prompt 03: Atualizar Mapper com Categoria (Data Layer)

1. Objetivo Principal

# 03.1 - Objetivo: Atualizar DailyGoalMapper (Conversão Bidirecional)

**Finalidade**
Atualizar o **Mapper** para gerenciar a tradução do campo `category` entre as camadas:
* `String` (DTO) ↔ `GoalCategory` (Entity).

**Arquivo Alvo**
`lib/data/mappers/daily_goal_mapper.dart`

**Requisitos Essenciais**
1.  **`toEntity` (DTO → Entity):** Chamar `GoalCategory.fromString(dto.category)` para garantir o tipo `Enum` e ativar o *fallback* de domínio.
2.  **`toDto` (Entity → DTO):** Usar `entity.category.name` para obter a representação *string* literal (e.g., `"health"`).

**Responsabilidade Única**
O Mapper é estritamente para conversões (`stateless`), sem adição de lógica de negócio.

2. Instruções de Implementação

# 03.2 - Instruções Detalhadas de Conversão (Mapper)

**Passos em `lib/data/mappers/daily_goal_mapper.dart`**

1.  **Atualizar `static DailyGoalEntity toEntity(DailyGoalDto dto)`:**
    * Mapear o campo `category` usando o método de conversão resiliente do enum:
        ```dart
        category: GoalCategory.fromString(dto.category),
        ```

2.  **Atualizar `static DailyGoalDto toDto(DailyGoalEntity entity)`:**
    * Mapear o campo `category` usando o nome literal do enum para o DTO:
        ```dart
        category: entity.category.name,
        ```

**Justificativa Técnica**
* `GoalCategory.fromString()`: Delega a validação de formato e o *fallback* ao Domain Layer.
* `entity.category.name`: Evita o `toString()` (que gera prefixos como `GoalCategory.`) para manter a string compatível com JSON (`"health"`).

3. Contexto Arquitetural e Validação

# 03.3 - Contexto e Decisões Técnicas (Mapper)

**Papel Arquitetural do Mapper**
O Mapper é a ponte, garantindo que a comunicação entre o Data Layer e o Domain Layer seja traduzida corretamente. Ele não implementa regras de negócio (validação de datas, por exemplo).
