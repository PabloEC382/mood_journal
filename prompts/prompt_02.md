Prompt 02: Atualizar DTO com Categoria (Data Layer)

1. Objetivo Principal

# 02.1 - Objetivo: Atualizar DailyGoalDto com Categoria String

**Finalidade**
Adaptar o **Data Transfer Object (DTO)** para incluir o campo `category` como **tipo primitivo `String`**, refletindo o *schema* do backend/API (Data Layer).

**Arquivo Alvo**
`lib/data/dtos/daily_goal_dto.dart`

**Requisitos Essenciais**
1.  **Field Definition:** Adicionar `required final String category;` (String, não Enum).
2.  **Deserialization:** No `fromJson`, ler `'category'` com *fallback* defensivo para a string `'personal'`.
3.  **Serialization:** Incluir o campo `category` no método `toJson()`.

**Restrição**
O DTO deve ser **agnóstico ao Domain Layer** (não usar `GoalCategory` enum).

2. Instruções de Implementação

# 02.2 - Instruções Detalhadas de Implementação (DTO)

**Passos em `lib/data/dtos/daily_goal_dto.dart`**

1.  **Adicionar Campo:**
    * Incluir `required this.category,` no construtor.
    * Declarar `final String category;` na classe.

2.  **Atualizar `factory fromJson`:**
    * Incluir a leitura e *fallback* da string:
        ```dart
        category: json['category'] as String? ?? 'personal',
        ```
    * *Nota: O `as String?` é crucial para tratar `null` ou ausência.*

3.  **Atualizar `toJson`:**
    * Adicionar o campo ao mapa:
        ```dart
        'category': category,
        ```

4.  **Comparação:**
    * Atualizar `operator ==` e `hashCode` para incluir a comparação da `category` (String).

**Regra Chave**
Garantir que o DTO use sempre o tipo `String` e o *fallback* no `fromJson` para `'personal'`.

3. Contexto Arquitetural e Validação

# 02.3 - Contexto e Resiliência do Data Layer (DTO)

**Princípios do DTO**
* **Agnosticismo:** Uso exclusivo de tipos primitivos (String, Int, Bool). Sem dependência de enums de domínio.
* **Fidelidade ao Schema:** O formato do DTO deve espelhar o JSON da API.
* **Resiliência:** O DTO assume a responsabilidade de não quebrar ao receber dados incompletos ou nulos, aplicando o *fallback* `'personal'` no `fromJson`.

**Divisão de Responsabilidade**
* **DTO:** Transporte de dados e resiliência contra JSON inválido.
* **Mapper:** Conversão de tipo (`String` → `Enum`).
* **Entity:** Validação final e regras de domínio.
