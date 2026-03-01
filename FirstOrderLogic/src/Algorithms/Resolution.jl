module Resolution

using ..Types
using ..Unification
using ..NormalForms

# ════════════════════════════════════════════════════════════════════════════
# PARTE 8: RESOLUCIÓN
# ════════════════════════════════════════════════════════════════════════════

export RES_FOL, RES_FOL_with_tracking, RESHistory, RESStep
export RES_VALID, RES_SAT, RES_LC
export verify_argument, verify_argument_detailed
export format_clause_for_display
export extract_proof_path, proof_of_insat_text, proof_of_insat_graph
export to_dot, to_file  # Grafos DOT para resolución y TS


# ----------------------------------------------------------------------------
# 8.1 Resolventes y Resolución
# ----------------------------------------------------------------------------

"""
    resolve_clauses(c1::Clause, c2::Clause) -> Set{Clause}

Calcula todos los resolventes posibles entre dos cláusulas mediante el principio de resolución.

# Teoría
Dadas dos cláusulas C₁ y C₂, un **resolvente** es una nueva cláusula que se obtiene:
1. Encontrando un literal L en C₁ y un literal ¬L' en C₂ (complementarios)
2. Unificando L y L' con el MGU (Unificador Más General) σ
3. Formando la nueva cláusula: (C₁ - {L})σ ∪ (C₂ - {¬L'})σ

Este es el paso fundamental del método de resolución de Robinson.

# Algoritmo
1. Para cada par de literales (l₁, l₂) con l₁ ∈ C₁, l₂ ∈ C₂:
   - Verificar que sean complementarios (uno negado, otro no)
   - Intentar unificar sus predicados con UMG
   - Si unificable, crear resolvente con literales restantes
2. Aplicar la sustitución MGU a todos los literales del resolvente

# Parámetros
- `c1::Clause`: Primera cláusula
- `c2::Clause`: Segunda cláusula

# Retorna
`Set{Clause}` con todos los posibles resolventes (puede estar vacío si no hay unificación)

# Ejemplos
```julia
# Ejemplo 1: Resolución simple
# C₁ = P(x) ∨ Q(x)    C₂ = ¬P(a) ∨ R(a)
# Resolvente: Q(a) ∨ R(a)  (con MGU: {x → a})

x = var("x")
a = constant_("a")
P, Q, R = predicates("P", "Q", "R")

c1 = Clause([Literal(false, P(x)), Literal(false, Q(x))])
c2 = Clause([Literal(true, P(a)), Literal(false, R(a))])

resolvents = resolve_clauses(c1, c2)
# Contiene: {Q(a) ∨ R(a)}

# Ejemplo 2: Múltiples resolventes posibles
# C₁ = P(x) ∨ Q(y)    C₂ = ¬P(a) ∨ ¬Q(b)
# Pueden resolverse sobre P o sobre Q
```

# Notas
- Si las cláusulas no tienen literales unificables complementarios, retorna conjunto vacío
- Puede generar múltiples resolventes si hay varias opciones de resolución
- La cláusula vacía □ indica contradicción (insatisfacibilidad)
"""
function resolve_clauses(c1::Clause, c2::Clause)
    resolvents = Set{Clause}()
    
    for l1 in c1.literals
        for l2 in c2.literals
            # Los literales deben ser complementarios (uno negado, otro no)
            if l1.negated != l2.negated
                # Intentar unificar los predicados
                mgu = UMG(l1.predicate, l2.predicate)
                if mgu !== nothing
                    # Crear nueva cláusula con los literales restantes
                    new_literals = Set{Literal}()
                    
                    # Añadir literales de c1 excepto l1, aplicando sustitución
                    for lit in c1.literals
                        if lit != l1
                            push!(new_literals, apply_substitution(lit, mgu))
                        end
                    end
                    
                    # Añadir literales de c2 excepto l2, aplicando sustitución
                    for lit in c2.literals
                        if lit != l2
                            push!(new_literals, apply_substitution(lit, mgu))
                        end
                    end
                    
                    push!(resolvents, Clause(new_literals))
                end
            end
        end
    end
    
    return resolvents
end

"""
    resolve_clauses_with_info(c1::Clause, c2::Clause) -> Vector{Tuple{Clause, Substitution, Predicate_FOL}}

Versión extendida de resolve_clauses que retorna información sobre el MGU y literal resuelto.
Retorna un vector de tuplas: (cláusula_resolvente, mgu, literal_resuelto)
"""
function resolve_clauses_with_info(c1::Clause, c2::Clause)
    results = Vector{Tuple{Clause, Substitution, Predicate_FOL}}()
    
    for l1 in c1.literals
        for l2 in c2.literals
            # Los literales deben ser complementarios (uno negado, otro no)
            if l1.negated != l2.negated
                # Intentar unificar los predicados
                mgu = UMG(l1.predicate, l2.predicate)
                if mgu !== nothing
                    # Crear nueva cláusula con los literales restantes
                    new_literals = Set{Literal}()
                    
                    # Añadir literales de c1 excepto l1, aplicando sustitución
                    for lit in c1.literals
                        if lit != l1
                            push!(new_literals, apply_substitution(lit, mgu))
                        end
                    end
                    
                    # Añadir literales de c2 excepto l2, aplicando sustitución
                    for lit in c2.literals
                        if lit != l2
                            push!(new_literals, apply_substitution(lit, mgu))
                        end
                    end
                    
                    new_clause = Clause(new_literals)
                    push!(results, (new_clause, mgu, l1.predicate))
                end
            end
        end
    end
    
    return results
end

"""
    RES_FOL(clauses::Set{Clause}; max_iterations::Int = 1000) -> NamedTuple

Algoritmo principal de resolución para lógica de primer orden.

# Descripción
Implementa el método de resolución de Robinson:
1. Comienza con un conjunto inicial de cláusulas
2. Genera resolventes entre pares de cláusulas
3. Añade nuevos resolventes al conjunto
4. Repite hasta:
   - Encontrar la cláusula vacía □ (insatisfacible)
   - No generar nuevas cláusulas (satisfacible)
   - Alcanzar límite de iteraciones (timeout)

# Parámetros
- `clauses::Set{Clause}`: Conjunto inicial de cláusulas
- `max_iterations::Int`: Límite de iteraciones (default: 1000)

# Retorna
NamedTuple con:
- `result::Symbol`: `:unsat` (insatisfacible), `:sat` (satisfacible), o `:timeout`
- `iterations::Int`: Número de iteraciones ejecutadas
- `empty_clause::Bool`: `true` si se encontró la cláusula vacía
- `final_clauses::Set{Clause}`: Conjunto final de cláusulas generadas

# Ejemplos
```julia
# Ejemplo 1: Conjunto insatisfacible
x = var("x")
P = predicate("P")
a = constant_("a")

# {P(a), ¬P(a)} → □
clauses = Set([
    Clause([Literal(false, P(a))]),
    Clause([Literal(true, P(a))])
])

result = RES_FOL(clauses)
result.result  # :unsat
result.empty_clause  # true

# Ejemplo 2: Modus Ponens
# KB: ∀x. P(x) → Q(x), P(a), ¬Q(a)
# Debe derivar □
clauses = to_clauses(∀(x, P(x) > Q(x)) & P(a) & !Q(a))
result = RES_FOL(clauses)
result.result  # :unsat (demuestra que KB implica Q(a))
```

# Complejidad
- Peor caso: exponencial en el número de cláusulas
- Semidecidible: siempre termina para fórmulas insatisfacibles
- Puede no terminar para fórmulas satisfacibles sin límite de iteraciones
"""
function RES_FOL(clauses::Set{Clause}; max_iterations::Int = 1000)
    new_clauses = Set{Clause}()
    all_clauses = copy(clauses)
    
    for iteration in 1:max_iterations
        clause_list = collect(all_clauses)
        
        # Resolver cada par de cláusulas
        for i in 1:length(clause_list)
            for j in i+1:length(clause_list)
                resolvents = resolve_clauses(clause_list[i], clause_list[j])
                
                for resolvent in resolvents
                    # Si encontramos la cláusula vacía, es insatisfacible
                    if isempty(resolvent.literals)
                        return (result = :unsat, 
                               iterations = iteration,
                               empty_clause = true,
                               final_clauses = all_clauses)
                    end
                    
                    push!(new_clauses, resolvent)
                end
            end
        end
        
        # Si no se generaron nuevas cláusulas, terminar
        if issubset(new_clauses, all_clauses)
            return (result = :sat,
                   iterations = iteration,
                   empty_clause = false,
                   final_clauses = all_clauses)
        end
        
        union!(all_clauses, new_clauses)
        new_clauses = Set{Clause}()
    end
    
    return (result = :timeout, 
           iterations = max_iterations,
           empty_clause = false,
           final_clauses = all_clauses)
end

# ──────────────────────────────────────────────────────────────────────────
# 8.2 Funciones de alto nivel: SAT, VALID, CONSECUENCIA LÓGICA
# ──────────────────────────────────────────────────────────────────────────

"""
    RES_VALID(f::FOLFormula) -> Bool

Verifica si una fórmula es válida (tautología en todos los modelos).

# Método
Una fórmula φ es válida ⟺ ¬φ es insatisfacible

# Ejemplo
```julia
x = var("x")
P = predicate("P")

# ∀x. P(x) ∨ ¬P(x) es válida
RES_VALID(∀(x, P(x) | !P(x)))  # true
```
"""
function RES_VALID(f::FOLFormula)
    negated = NotFOL(f)
    skolemized = to_Sk(negated)
    clauses = to_clauses(skolemized)
    result = RES_FOL(clauses)
    return result.result == :unsat
end

"""
    RES_SAT(f::FOLFormula) -> Bool

Verifica si una fórmula es satisfacible (existe al menos un modelo).

# Método
Convierte la fórmula a cláusulas y aplica resolución

# Ejemplo
```julia
x = var("x")
P, Q = predicates("P", "Q")

# Satisfacible: P(x) ∧ Q(x)
RES_SAT(P(x) & Q(x))  # true
```
"""
function RES_SAT(f::FOLFormula)
    skolemized = to_Sk(f)
    clauses = to_clauses(skolemized)
    result = RES_FOL(clauses)
    return result.result == :sat
end

"""
    RES_LC(Γ::Vector{FOLFormula}, φ::FOLFormula) -> Bool

Verifica si un conjunto de premisas Γ implica lógicamente una conclusión φ.

# Método
Γ ⊨ φ ⟺ Γ ∧ ¬φ es insatisfacible

# Ejemplo
```julia
x = var("x")
P, Q = predicates("P", "Q")
a = constant_("a")

premises = [∀(x, P(x) > Q(x)), P(a)]
conclusion = Q(a)

RES_LC(premises, conclusion)  # true (Modus Ponens)
```
"""
function RES_LC(Γ::Vector{FOLFormula}, φ::FOLFormula)
    Γ1 = length(Γ) == 1 ? Γ[1] : reduce(&, Γ)
    formula = Γ1 & !(φ)
    
    skolemized = to_Sk(formula)
    clauses = to_clauses(skolemized)
    result = RES_FOL(clauses)
    return result.result == :unsat
end

# ──────────────────────────────────────────────────────────────────────────
# 8.3 Depuración y análisis paso a paso
# ──────────────────────────────────────────────────────────────────────────

"""
    debug_resolution(f::FOLFormula)

Muestra el proceso completo de transformación de una fórmula FOL a forma clausal.

# Descripción
Imprime cada paso de la transformación:
1. Eliminación de implicaciones y bicondicionales
2. Movimiento de negaciones hacia adentro (NNF)
3. Conversión a forma prenexa
4. Skolemización (eliminación de cuantificadores existenciales)
5. Conversión a CNF (Forma Normal Conjuntiva)
6. Extracción de cláusulas

# Uso
Útil para debugging y propósitos educativos - permite ver cada transformación
aplicada a la fórmula original.

# Parámetros
- `f::FOLFormula`: Fórmula a transformar

# Retorna
`Set{Clause}` con las cláusulas finales

# Ejemplo
```julia
x = var("x")
P, Q = predicates("P", "Q")
a = constant_("a")

f = ∀(x, P(x) > Q(x)) & P(a)
clauses = debug_resolution(f)

# Imprime:
# === DEBUG: Procesando fórmula ===
# Original: (∀x. (P(x) → Q(x))) ∧ P(a)
# 1. Eliminando implicaciones...
# Resultado: (∀x. (¬P(x) ∨ Q(x))) ∧ P(a)
# ...
```
"""
function debug_resolution(f::FOLFormula)
    println("=== DEBUG: Procesando fórmula ===")
    println("Original: $f")
    
    println("\n1. Eliminando implicaciones...")
    step1 = remove_imp(f)
    println("Resultado: $step1")
    
    println("\n2. Moviendo negaciones hacia adentro...")
    step2 = move_!_in(step1)
    println("Resultado: $step2")
    
    println("\n3. Convirtiendo a forma prenex...")
    step3 = to_Px(f)
    println("Resultado: $step3")
    
    println("\n4. Skolemizando...")
    step4 = to_Sk(f)
    println("Resultado: $step4")
    
    println("\n5. Convirtiendo a CNF...")
    step5 = to_cnf(step4)
    println("Resultado: $step5")
    
    println("\n6. Extrayendo cláusulas...")
    step6 = to_clauses(step5)
    println("Cláusulas: $step6")
    
    return step6
end

"""
    verify_argument(Γ::Vector{FOLFormula}, φ::FOLFormula) -> NamedTuple

Verifica si un argumento lógico es válido utilizando el método de resolución.

# Descripción
Un argumento con premisas Γ = {φ₁, φ₂, ..., φₙ} y conclusión φ es **válido** si:
- La implicación (φ₁ ∧ φ₂ ∧ ... ∧ φₙ) → φ es una tautología
- Equivalentemente: Γ ⊨ φ (las premisas implican lógicamente la conclusión)

El método verifica ambas propiedades:
1. **Validez**: ¬((Γ₁ ∧ ... ∧ Γₙ) → φ) es insatisfacible
2. **Implicación**: (Γ₁ ∧ ... ∧ Γₙ) ∧ ¬φ es insatisfacible

# Parámetros
- `Γ::Vector{FOLFormula}`: Vector de premisas (puede estar vacío)
- `φ::FOLFormula`: Conclusión a verificar

# Retorna
NamedTuple con:
- `valid::Bool`: `true` si la implicación es válida (tautología)
- `entails::Bool`: `true` si las premisas implican la conclusión
- `premises::Vector{FOLFormula}`: Premisas originales
- `conclusion::FOLFormula`: Conclusión original

# Ejemplos
```julia
x = var("x")
P, Q = predicates("P", "Q")
a = constant_("a")

# Ejemplo 1: Modus Ponens (válido)
# Premisas: ∀x. P(x) → Q(x), P(a)
# Conclusión: Q(a)
premises = [∀(x, P(x) > Q(x)), P(a)]
conclusion = Q(a)

result = verify_argument(premises, conclusion)
result.valid    # true
result.entails  # true

# Ejemplo 2: Silogismo (válido)
# Todo humano es mortal, Sócrates es humano ⊢ Sócrates es mortal
Human, Mortal = predicates("Human", "Mortal")
socrates = constant_("socrates")

premises = [
    ∀(x, Human(x) > Mortal(x)),
    Human(socrates)
]
conclusion = Mortal(socrates)

verify_argument(premises, conclusion)  # (valid=true, entails=true, ...)

# Ejemplo 3: Argumento inválido
premises = [P(a)]
conclusion = Q(a)  # No se sigue de P(a)

result = verify_argument(premises, conclusion)
result.valid    # false
result.entails  # false

# Ejemplo 4: Sin premisas (verifica si φ es válida)
result = verify_argument(FOLFormula[], ∀(x, P(x) | !P(x)))
result.valid  # true (ley del tercero excluso)
```

# Casos especiales
- Si `Γ` está vacío, solo verifica si `φ` es una tautología
- Ambos resultados (`valid` y `entails`) deberían ser iguales en teoría
- Útil para verificar razonamientos lógicos formales

# Ver también
- [`verify_argument_detailed`](@ref): Versión con output detallado
- [`RES_VALID`](@ref): Verificar validez de una fórmula
- [`RES_LC`](@ref): Consecuencia lógica directa
"""
function verify_argument(Γ::Vector{FOLFormula}, φ::FOLFormula)
    if isempty(Γ)
        return RES_VALID(φ)
    end
    
    # Crear la implicación: (p1 ∧ p2 ∧ ... ∧ pn) → conclusion
    Γ1 = length(Γ) == 1 ? Γ[1] : reduce(&, Γ)
    implication = Γ1 > φ
    
    # Verificar validez directamente para evitar problemas de recursión
    negated_implication = !(implication)
    skolemized_neg = to_Sk(negated_implication)
    matrix = remove_∀_prefix(skolemized_neg)
    clauses_neg = to_clauses(matrix)
    result_valid = RES_FOL(clauses_neg)
    RES_VALID_result = result_valid.result == :unsat
    
    # Verificar implicación directamente 
    entailment_formula = Γ1 & !(φ)
    skolemized_ent = to_Sk(entailment_formula)
    clauses_ent = to_clauses(skolemized_ent)
    result_ent = RES_FOL(clauses_ent)
    entails_result = result_ent.result == :unsat
    
    return (valid = RES_VALID_result, 
           entails = entails_result,
           premises = Γ,
           conclusion = φ)
end

"""
    verify_argument_detailed(Γ::Vector{FOLFormula}, φ::FOLFormula) -> NamedTuple

Versión verbose de `verify_argument` que imprime cada paso del proceso de verificación.

# Descripción
Ejecuta la misma verificación que `verify_argument` pero:
- Imprime las premisas y conclusión formateadas
- Muestra la implicación a verificar
- Imprime cada paso de transformación (skolemización, clausificación)
- Muestra las cláusulas generadas
- Reporta resultados de forma detallada
- Útil para debugging y propósitos educativos

# Parámetros
- `Γ::Vector{FOLFormula}`: Vector de premisas
- `φ::FOLFormula`: Conclusión

# Retorna
NamedTuple idéntico a `verify_argument`, o `nothing` si ocurre un error

# Salida por consola
Imprime:
```
=== VERIFICACIÓN DE ARGUMENTO ===
Premisas:
  1. ...
  2. ...
Conclusión: ...

Implicación a verificar: ...

Verificando validez...
Negación: ...
Skolemizando la negación...
Negación skolemizada: ...
Cláusulas de la negación: ...

Verificando implicación (premises ∧ ¬conclusion)...
Fórmula para implicación: ...
Skolemizada: ...
Cláusulas: ...

=== RESULTADOS ===
¿El argumento es válido? ...
¿Las premisas implican la conclusión? ...
```

# Ejemplos
```julia
x = var("x")
P, Q = predicates("P", "Q")
a = constant_("a")

# Modus Ponens con output detallado
premises = [∀(x, P(x) > Q(x)), P(a)]
conclusion = Q(a)

verify_argument_detailed(premises, conclusion)
# Imprime todo el proceso paso a paso
# Retorna: (valid=true, entails=true, premises=[...], conclusion=Q(a))

# Útil para entender POR QUÉ un argumento es válido o inválido
premises = [P(a)]
conclusion = Q(a)

verify_argument_detailed(premises, conclusion)
# Muestra exactamente qué cláusulas se generan y por qué no se deriva □
```

# Casos de uso
- **Educación**: Mostrar a estudiantes el proceso completo
- **Debugging**: Identificar dónde falla un argumento
- **Verificación**: Confirmar que la transformación es correcta
- **Demostración**: Explicar razonamientos lógicos paso a paso

# Ver también
- [`verify_argument`](@ref): Versión sin output (más rápida)
- [`debug_resolution`](@ref): Debug de transformación de fórmulas
- [`proof_of_insat_text`](@ref): Visualización de prueba de insatisfacibilidad
"""
function verify_argument_detailed(Γ::Vector{FOLFormula}, φ::FOLFormula)
    println("=== VERIFICACIÓN DE ARGUMENTO ===")
    println("Premisas:")
    for (i, p) in enumerate(Γ)
        println("  $i. $p")
    end
    println("Conclusión: $φ")
    
    if isempty(Γ)
        println("\nSin premisas, verificando si la conclusión es válida...")
        result = RES_VALID(φ)
        println("¿Es válida? $result")
        return result
    end
    
    # Crear la implicación: (p1 ∧ p2 ∧ ... ∧ pn) → conclusion
    Γ1 = length(Γ) == 1 ? Γ[1] : reduce(&, Γ)
    implication = Γ1 > φ
    
    println("\nImplicación a verificar: $implication")
    
    # Verificar validez - método directo sin usar RES_VALID para evitar problemas
    println("\nVerificando validez...")
    negated_implication = !(implication)
    println("Negación: $negated_implication")
    
    try
        # Verificar validez directamente
        println("Skolemizando la negación...")
        skolemized_neg = to_Sk(negated_implication)
        println("Negación skolemizada: $skolemized_neg")
        
        clauses_neg = to_clauses(skolemized_neg)
        println("Cláusulas de la negación: $clauses_neg")
        
        result_valid_direct = RES_FOL(clauses_neg)
        RES_VALID_result = result_valid_direct.result == :unsat
        
        # Verificar implicación directamente 
        println("\nVerificando implicación (premises ∧ ¬conclusion)...")
        entailment_formula = Γ1 & !(φ)
        println("Fórmula para implicación: $entailment_formula")
        
        skolemized_ent = to_Sk(entailment_formula)
        println("Skolemizada: $skolemized_ent")
        
        clauses_ent = to_clauses(skolemized_ent)
        println("Cláusulas: $clauses_ent")
        
        result_ent = RES_FOL(clauses_ent)
        entails_result = result_ent.result == :unsat
        
        println("\n=== RESULTADOS ===")
        println("¿El argumento es válido? $RES_VALID_result")
        println("¿Las premisas implican la conclusión? $entails_result")
        
        return (valid = RES_VALID_result, 
               entails = entails_result,
               premises = Γ,
               conclusion = φ)
    catch e
        println("Error durante la verificación: $e")
        return nothing
    end
end



# ──────────────────────────────────────────────────────────────────────────
# 8.4. Resolución con tracking
# ──────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────
# 8.4.1 Estructuras para tracking
# ──────────────────────────────────────────────────────────────────────────
struct RESStep
    iteration::Int
    parent1::Int  # Índice de la primera cláusula padre
    parent2::Int  # Índice de la segunda cláusula padre
    resolvent::Clause
    resolvent_index::Int  # Índice de la nueva cláusula
    is_empty::Bool  # ¿Es la cláusula vacía?
    mgu::Union{Substitution, Nothing}  # MGU usado en la resolución
    resolved_literal::Union{Predicate_FOL, Nothing}  # Literal que se resolvió
end

struct RESHistory
    initial_clauses::Vector{Clause}
    steps::Vector{RESStep}
    final_result::Symbol  # :unsat, :sat, :timeout
    iterations::Int
end

# ──────────────────────────────────────────────────────────────────────────
# 8.4.2 Resolución con tracking
# ──────────────────────────────────────────────────────────────────────────

"""
    RES_FOL_with_tracking(clauses::Set{Clause}; max_iterations::Int = 1000) -> RESHistory

Ejecuta el algoritmo de resolución manteniendo un historial completo de todos los pasos.

# Descripción
Versiona extendida de `RES_FOL` que registra:
- Cada paso de resolución (cláusulas padre, resolvente, MGU usado)
- Iteración en la que se generó cada cláusula
- Índices globales para rastrear dependencias
- Información para reconstruir el árbol de prueba

Esto permite:
- Visualizar el árbol de resolución completo
- Extraer el camino de prueba mínimo hasta □
- Generar explicaciones textuales y gráficas
- Debugging detallado del proceso

# Parámetros
- `clauses::Set{Clause}`: Conjunto inicial de cláusulas
- `max_iterations::Int`: Límite de iteraciones (default: 1000)

# Retorna
`RESHistory` con:
- `initial_clauses::Vector{Clause}`: Cláusulas iniciales (KB)
- `steps::Vector{RESStep}`: Todos los pasos de resolución ejecutados
- `final_result::Symbol`: `:unsat`, `:sat`, o `:timeout`
- `iterations::Int`: Número de iteraciones

Cada `RESStep` contiene:
- `iteration::Int`: Número de iteración
- `parent1, parent2::Int`: Índices de las cláusulas padre
- `resolvent::Clause`: Cláusula resultado
- `resolvent_index::Int`: Índice global del resolvente
- `is_empty::Bool`: Si es la cláusula vacía □
- `mgu::Substitution`: MGU utilizado en la resolución
- `resolved_literal::Predicate_FOL`: Literal sobre el que se resolvió

# Ejemplos
```julia
# Rastrear prueba de Modus Ponens
x = var("x")
P, Q = predicates("P", "Q")
a = constant_("a")

f = ∀(x, P(x) > Q(x)) & P(a) & !Q(a)
clauses = to_clauses(f)

history = RES_FOL_with_tracking(clauses)

# Inspeccionar resultado
history.final_result  # :unsat
length(history.steps)  # Número de resoluciones ejecutadas

# Visualizar
proof_of_insat_text(f)  # Árbol textual
g = to_dot(history)     # Grafo Graphviz
```

# Casos de uso
- Generar visualizaciones de pruebas
- Explicar por qué una fórmula es insatisfacible
- Enseñanza: mostrar cada paso del algoritmo
- Debugging: identificar cláusulas problemáticas
"""
function RES_FOL_with_tracking(clauses::Set{Clause}; max_iterations::Int = 1000)
    new_clauses = Set{Clause}()
    all_clauses = copy(clauses)
    
    # Convertir a vector para indexación
    clause_list = collect(all_clauses)
    initial_clauses = copy(clause_list)
    steps = RESStep[]
    clause_counter = length(clause_list)
    
    # Mapeo de cláusula a índice global (para tracking correcto)
    clause_to_index = Dict{Clause, Int}()
    for (idx, clause) in enumerate(initial_clauses)
        clause_to_index[clause] = idx
    end
    
    for iteration in 1:max_iterations
        clause_list = collect(all_clauses)
        iteration_steps = RESStep[]
        
        # Resolver cada par de cláusulas
        for i in 1:length(clause_list)
            for j in i+1:length(clause_list)
                # Usar la versión extendida que retorna MGU
                resolutions = resolve_clauses_with_info(clause_list[i], clause_list[j])
                
                for (resolvent, mgu, resolved_pred) in resolutions
                    clause_counter += 1
                    is_empty = isempty(resolvent.literals)
                    
                    # Obtener índices globales correctos de las cláusulas padre
                    parent1_idx = clause_to_index[clause_list[i]]
                    parent2_idx = clause_to_index[clause_list[j]]
                    
                    step = RESStep(
                        iteration,
                        parent1_idx, parent2_idx,
                        resolvent,
                        clause_counter,
                        is_empty,
                        mgu,  # Almacenar el MGU
                        resolved_pred  # Almacenar el predicado resuelto
                    )
                    push!(iteration_steps, step)
                    
                    # Actualizar el mapeo para la nueva cláusula
                    clause_to_index[resolvent] = clause_counter
                    
                    # Si encontramos la cláusula vacía, es insatisfacible
                    if is_empty
                        append!(steps, iteration_steps)
                        return RESHistory(
                            initial_clauses,
                            steps,
                            :unsat,
                            iteration
                        )
                    end
                    
                    push!(new_clauses, resolvent)
                end
            end
        end
        
        append!(steps, iteration_steps)
        
        # Si no se generaron nuevas cláusulas, terminar
        if issubset(new_clauses, all_clauses)
            return RESHistory(
                initial_clauses,
                steps,
                :sat,
                iteration
            )
        end
        
        union!(all_clauses, new_clauses)
        new_clauses = Set{Clause}()
    end
    
    return RESHistory(
        initial_clauses,
        steps,
        :timeout,
        max_iterations
    )
end

# ──────────────────────────────────────────────────────────────────────────
# 8.4.3 Funciones para representación
# ──────────────────────────────────────────────────────────────────────────

# Función para formatear una cláusula para visualización
function format_clause_for_display(clause::Clause; max_length::Int = 20)
    if isempty(clause.literals)
        return "□"  # Cláusula vacía
    end
    
    # Convertir literales a strings
    literal_strs = String[]
    for literal in clause.literals
        if literal.negated
            push!(literal_strs, "¬$(literal.predicate)")
        else
            push!(literal_strs, "$(literal.predicate)")
        end
    end
    
    # Unir con ∨
    clause_str = join(literal_strs, " ∨ ")
    
    # Truncar si es muy largo (usando caracteres, no bytes)
    if length(clause_str) > max_length
        # Usar prevind para manejar correctamente caracteres multi-byte
        safe_end = prevind(clause_str, max_length)
        return clause_str[1:safe_end] * "..."
    end
    
    return clause_str
end

"""
    get_clause_content(index::Int, initial_clauses::Vector{Clause}, steps::Vector{RESStep}) -> Clause

Obtiene el contenido de una cláusula dado su índice global en el historial de resolución.

# Descripción
Las cláusulas en el historial tienen índices globales:
- Índices 1..n: Cláusulas iniciales (KB)
- Índices n+1...: Cláusulas derivadas (en `steps`)

Esta función resuelve el índice al contenido real de la cláusula.

# Parámetros
- `index::Int`: Índice global de la cláusula
- `initial_clauses::Vector{Clause}`: Cláusulas iniciales del historial
- `steps::Vector{RESStep}`: Pasos de resolución ejecutados

# Retorna
`Clause` correspondiente al índice, o cláusula vacía si no se encuentra

# Ejemplo (uso interno)
```julia
history = RES_FOL_with_tracking(clauses)

# Obtener cláusula inicial (índice 1)
c1 = get_clause_content(1, history.initial_clauses, history.steps)

# Obtener cláusula derivada
step_idx = length(history.initial_clauses) + 1
derived = get_clause_content(step_idx, history.initial_clauses, history.steps)
```
"""
function get_clause_content(index::Int, initial_clauses::Vector{Clause}, steps::Vector{RESStep})
    if index <= length(initial_clauses)
        return initial_clauses[index]
    else
        # Es una cláusula generada, buscarla en los pasos
        step_index = index - length(initial_clauses)
        if step_index <= length(steps)
            return steps[step_index].resolvent
        else
            # Fallback: crear cláusula vacía
            return Clause(Set{Literal}())
        end
    end
end

# ──────────────────────────────────────────────────────────────────────────
# 8.4.4 Pruebas por Refutación
# ──────────────────────────────────────────────────────────────────────────

"""
    extract_proof_path(history::RESHistory) -> Vector{RESStep}

Extrae el camino mínimo desde las cláusulas iniciales hasta la cláusula vacía.
Solo devuelve los pasos que son RELEVANTES para la prueba.
"""
function extract_proof_path(history::RESHistory)::Vector{RESStep}
    # Si no hay cláusula vacía, no hay prueba
    if history.final_result != :unsat
        return RESStep[]
    end
    
    # Encontrar el paso que produce la cláusula vacía
    empty_clause_step = nothing
    for step in history.steps
        if step.is_empty
            empty_clause_step = step
            break
        end
    end
    
    if empty_clause_step === nothing
        return RESStep[]
    end
    
    # Reconstruir el árbol de dependencias (backward search)
    # Mapear índice de cláusula → pasos que la producen
    clause_producer = Dict{Int, RESStep}()
    
    for step in history.steps
        clause_producer[step.resolvent_index] = step
    end
    
    # Backward search desde el paso vacío
    relevant_steps = Set{Int}()  # Índices de pasos relevantes
    visited_clauses = Set{Int}()
    
    function backtrack(step_idx::Int)
        if step_idx in relevant_steps
            return
        end
        
        step = history.steps[step_idx]
        push!(relevant_steps, step_idx)
        
        # Procesar clausulas padre
        if step.parent1 > length(history.initial_clauses)
            # Es una cláusula derivada, buscar quién la produjo
            producer_step = findfirst(s -> s.resolvent_index == step.parent1, history.steps)
            if producer_step !== nothing
                backtrack(producer_step)
            end
        end
        
        if step.parent2 > length(history.initial_clauses)
            # Es una cláusula derivada, buscar quién la produjo
            producer_step = findfirst(s -> s.resolvent_index == step.parent2, history.steps)
            if producer_step !== nothing
                backtrack(producer_step)
            end
        end
    end
    
    # Comenzar desde el paso de la cláusula vacía
    empty_step_idx = findfirst(s -> s.is_empty, history.steps)
    if empty_step_idx !== nothing
        backtrack(empty_step_idx)
    end
    
    # Convertir a vector ordenado
    proof_steps = [history.steps[i] for i in sort(collect(relevant_steps))]
    return proof_steps
end

"""
    proof_of_insat_text(formula::FOLFormula; show_mgu=true)

Visualiza como árbol ASCII SOLO el camino de la prueba de insatisfacibilidad.
Muestra cada paso de resolución con sus MGUs (si show_mgu=true).
"""
function proof_of_insat_text(formula::FOLFormula; show_mgu::Bool=true)
    println("╔═══════════════════════════════════════════════════════════╗")
    println("║     PRUEBA DE INSATISFACIBILIDAD (RESOLUCIÓN FOL)         ║")
    println("╚═══════════════════════════════════════════════════════════╝")
    println()
    
    try
        # Preparar la fórmula
        skolemized = to_Sk(formula)
        clauses = to_clauses(skolemized)
        
        println("📋 CLÁUSULAS INICIALES:")
        println("─" ^ 60)
        for (i, clause) in enumerate(clauses)
            clause_str = format_clause_for_display(clause; max_length=100)
            println("  C$i: $clause_str")
        end
        println()
        
        # Ejecutar resolución con tracking
        history = RES_FOL_with_tracking(clauses; max_iterations=1000)
        
        if history.final_result != :unsat
            println("⚠️  La fórmula NO es insatisfacible (no se encontró prueba)")
            return nothing
        end
        
        # Extraer solo el camino relevante
        proof_path = extract_proof_path(history)
        
        if isempty(proof_path)
            println("⚠️  No se pudo extraer el camino de prueba")
            return nothing
        end
        
        println("✓ FÓRMULA INSATISFACIBLE - Prueba encontrada en $(length(proof_path)) pasos")
        println()
        println("🔍 SECUENCIA DE RESOLUCIONES (solo pasos relevantes):")
        println("═" ^ 60)
        println()
        
        # Mostrar cada paso de la prueba
        for (idx, step) in enumerate(proof_path)
            # Obtener cláusulas padre
            if step.parent1 <= length(history.initial_clauses)
                parent1 = history.initial_clauses[step.parent1]
                parent1_label = "C$(step.parent1)"
            else
                # Es una cláusula derivada - buscar en pasos
                parent_step = findfirst(s -> s.resolvent_index == step.parent1, proof_path)
                if parent_step !== nothing
                    parent1 = proof_path[parent_step].resolvent
                    parent1_label = "R$parent_step"
                else
                    parent1 = history.initial_clauses[1]  # Fallback
                    parent1_label = "R?"
                end
            end
            
            if step.parent2 <= length(history.initial_clauses)
                parent2 = history.initial_clauses[step.parent2]
                parent2_label = "C$(step.parent2)"
            else
                parent_step = findfirst(s -> s.resolvent_index == step.parent2, proof_path)
                if parent_step !== nothing
                    parent2 = proof_path[parent_step].resolvent
                    parent2_label = "R$parent_step"
                else
                    parent2 = history.initial_clauses[1]  # Fallback
                    parent2_label = "R?"
                end
            end
            
            # Formatear para visualizar
            parent1_str = format_clause_for_display(parent1; max_length=50)
            parent2_str = format_clause_for_display(parent2; max_length=50)
            resolvent_str = format_clause_for_display(step.resolvent; max_length=50)
            
            # Mostrar el paso
            println("┌─ PASO $idx ─────────────────────────────────────────────┐")
            println("│")
            println("│  Padre 1 ($parent1_label): $parent1_str")
            println("│  Padre 2 ($parent2_label): $parent2_str")
            
            if show_mgu && idx < length(proof_path)
                println("│  ├─ (Literales resueltos por MGU)")
            end
            
            println("│  └─ Resolvente (R$idx): $resolvent_str")
            
            if step.is_empty
                println("│     🎯 ¡CLÁUSULA VACÍA! ✓")
            end
            println("│")
            println("└──────────────────────────────────────────────────────┘")
            println()
        end
        
        println("═" ^ 60)
        println("✅ CONCLUSIÓN: La fórmula es INSATISFACIBLE")
        println("   Prueba completada en $(length(proof_path)) resoluciones")
        println()
        
        return (proof_path=proof_path, history=history)
        
    catch e
        println("❌ Error: $e")
        return nothing
    end
end

"""
    proof_of_insat_graph(formula::FOLFormula; save_path=nothing)

Crea una visualización gráfica SOLO del camino de prueba.
Retorna un plot con el árbol de resoluciones mínimo.
"""
function proof_of_insat_graph(formula::FOLFormula; save_path=nothing)
    println("═" ^ 60)
    println("GENERANDO VISUALIZACIÓN GRÁFICA DE LA PRUEBA...")
    println("═" ^ 60)
    
    try
        # Preparar
        skolemized = to_Sk(formula)
        clauses = to_clauses(skolemized)
        history = RES_FOL_with_tracking(clauses; max_iterations=1000)
        
        if history.final_result != :unsat
            println("⚠️  La fórmula NO es insatisfacible")
            return nothing
        end
        
        # Extraer camino
        proof_path = extract_proof_path(history)
        
        if isempty(proof_path)
            println("⚠️  No se pudo extraer el camino")
            return nothing
        end
        
        # Construir grafo (versión simplificada con Plots.jl)
        # Para una versión completa, se podría usar GraphRecipes.jl o Graphs.jl
        
        println("📊 Estructura de prueba:")
        println("   • Cláusulas iniciales: $(length(history.initial_clauses))")
        println("   • Pasos en prueba: $(length(proof_path))")
        println()
        
        # Crear representación de árbol en texto para ahora
        
        println("🌳 ÁRBOL DE PRUEBA (representación textual):")
        println()
        
        # Mapear índices de cláusulas a niveles en el árbol
        clause_level = Dict{Int, Int}()
        
        # Cláusulas iniciales en nivel 0
        for i in 1:length(history.initial_clauses)
            clause_level[i] = 0
        end
        
        # Calcular niveles para derivadas
        for step in proof_path
            level1 = get(clause_level, step.parent1, 0)
            level2 = get(clause_level, step.parent2, 0)
            clause_level[step.resolvent_index] = max(level1, level2) + 1
        end
        
        # Visualizar árbol
        max_level = maximum(values(clause_level))
        
        for level in 0:max_level
            println("Nivel $level:")
            for step in proof_path
                if clause_level[step.resolvent_index] == level && level > 0
                    parent1_str = format_clause_for_display(
                        step.parent1 <= length(history.initial_clauses) ? 
                        history.initial_clauses[step.parent1] : 
                        step.resolvent, 
                        max_length=40
                    )
                    parent2_str = format_clause_for_display(
                        step.parent2 <= length(history.initial_clauses) ? 
                        history.initial_clauses[step.parent2] : 
                        step.resolvent, 
                        max_length=40
                    )
                    result_str = format_clause_for_display(step.resolvent; max_length=40)
                    
                    symbol = step.is_empty ? "□" : "R"
                    println("  ├─ $symbol: ($parent1_str) ∨ ($parent2_str) ⟹ $result_str")
                end
            end
        end
        
        println()
        println("✅ Visualización completada")
        
        return (proof_path=proof_path, history=history, clause_level=clause_level)
        
    catch e
        println("❌ Error: $e")
        return nothing
    end
end

# ──────────────────────────────────────────────────────────────────────────
# 8.5 Visualización de Resolución con Graphviz DOT
# ──────────────────────────────────────────────────────────────────────────

# Detectar e importar GraphvizDotLang si está disponible
const GRAPHVIZ_DOTLANG_AVAILABLE = try
    Base.find_package("GraphvizDotLang") !== nothing
catch
    false
end

if GRAPHVIZ_DOTLANG_AVAILABLE
    using GraphvizDotLang: graph, digraph, node, edge, attr, save
end

"""
    to_dot(history::RESHistory; 
                           only_proof_path::Bool=true,
                           max_clause_length::Int=40,
                           show_iterations::Bool=true)

Genera una representación en formato DOT del árbol de resolución.

# Parámetros
- `history`: Historial completo de la resolución
- `only_proof_path`: Si es true, solo muestra el camino de prueba (desde iniciales hasta □)
- `max_clause_length`: Longitud máxima para mostrar cláusulas
- `show_iterations`: Mostrar números de iteración en los nodos

# Características del grafo
- **Cláusulas iniciales** (KB): Fondo cian, forma de caja
- **Cláusulas intermedias**: Fondo verde claro, forma elipse
- **Cláusula vacía □**: Fondo rojo, forma de caja doble
- **Aristas**: Muestran el literal resuelto (si es posible detectarlo)
- **Dirección**: De arriba (iniciales) hacia abajo (□)

# Retorna
- Si GraphvizDotLang disponible: objeto digraph (visualizable interactivamente)
- Si no: String con código DOT

# Ejemplo
```julia
clauses = to_clauses(∀(x, P(x) > Q(x)) & P(a) & !Q(a))
history = RES_FOL_with_tracking(clauses)
g = to_dot(history)  # Muestra el grafo en Pluto/Jupyter
```
"""
function to_dot(history::RESHistory; 
                                only_proof_path::Bool=true,
                                max_clause_length::Int=40,
                                show_iterations::Bool=false)
    
    if !GRAPHVIZ_DOTLANG_AVAILABLE
        error("GraphvizDotLang no está disponible. Instálalo con: using Pkg; Pkg.add(\"GraphvizDotLang\")")
    end
    
    # Si solo queremos el camino de prueba
    steps_to_show = if only_proof_path && history.final_result == :unsat
        extract_proof_path(history)
    else
        history.steps
    end
    
    # Mapeo de índices de cláusulas involucradas
    clause_indices = Set{Int}()
    
    # Añadir cláusulas iniciales usadas
    for step in steps_to_show
        push!(clause_indices, step.parent1)
        push!(clause_indices, step.parent2)
        push!(clause_indices, step.resolvent_index)
    end
    
    # Crear grafo dirigido usando API fluida
    g = digraph(rankdir="TB")  # Top to Bottom
    font = "sans-serif"
    
    # Añadir atributos globales
    g = g |> attr(:graph; 
                  splines="true", 
                  nodesep="0.5", 
                  ranksep="0.8", 
                  fontname=font,
                  bgcolor="white",
                  label="Árbol de Resolución - $(history.final_result)",
                  labelloc="t")
    g = g |> attr(:node; fontname=font, fontsize="11", margin="0.2,0.1")
    g = g |> attr(:edge; fontname=font, fontsize="9", color="gray40")
    
    # Crear nodos para cláusulas iniciales
    n_initial = length(history.initial_clauses)
    
    for i in 1:n_initial
        if i in clause_indices
            clause_str = format_clause_for_display(history.initial_clauses[i]; 
                                                   max_length=max_clause_length)
            label = "C$i: $clause_str"
            
            g = g |> node("clause_$i"; 
                         label=label,
                         shape="box",
                         style="filled",
                         fillcolor="cyan",
                         color="darkblue",
                         fontcolor="black")
        end
    end
    
    # Crear nodos para cláusulas derivadas (solo las del camino de prueba)
    for step in steps_to_show
        idx = step.resolvent_index
        clause_str = format_clause_for_display(step.resolvent; 
                                               max_length=max_clause_length)
        
        # Determinar atributos según tipo de cláusula
        if step.is_empty
            label = "□"  # Cláusula vacía
            g = g |> node("clause_$idx";
                         label=label,
                         shape="circle",
                         style="filled",
                         fillcolor="red",
                         color="darkred",
                         fontsize="30",
                         margin="0,0",
                         fixedsize="true",
                         width="0.5",
                         fontcolor="white")
        else
            label = if show_iterations
                "C$idx [iter $(step.iteration)]: $clause_str"
            else
                "C$idx: $clause_str"
            end
            g = g |> node("clause_$idx";
                         label=label,
                         shape="box",
                         style="",
                         fillcolor="lightgreen",
                         color="black",
                         fontcolor="black")
        end
    end
    
    # Crear aristas (padre → resolvente) con información del MGU
    for step in steps_to_show
        parent1_id = "clause_$(step.parent1)"
        parent2_id = "clause_$(step.parent2)"
        child_id = "clause_$(step.resolvent_index)"
        
        # Formatear el MGU para mostrar en la arista
        mgu_label = ""
        if step.mgu !== nothing && !isempty(step.mgu.bindings)
            mgu_parts = String[]
            for (var, term) in step.mgu.bindings
                push!(mgu_parts, "$(var)→$(term)")
            end
            mgu_label = join(mgu_parts, ", ")
        end
        
        # Formatear el literal resuelto
        resolved_label = ""
        if step.resolved_literal !== nothing
            resolved_label = string(step.resolved_literal)
        end
        
        # Combinar información para la etiqueta de la arista
        edge_label = ""
        if !isempty(resolved_label) && !isempty(mgu_label)
            edge_label = "$(resolved_label)\\n{$(mgu_label)}"
        elseif !isempty(resolved_label)
            edge_label = resolved_label
        elseif !isempty(mgu_label)
            edge_label = "{$(mgu_label)}"
        end
        
        # Arista del primer padre con etiqueta
        if !isempty(edge_label)
            g = g |> edge(parent1_id, child_id; 
                         color="gray50", 
                         penwidth="1.5",
                         label=edge_label,
                         fontsize="9",
                         fontcolor="blue")
        else
            g = g |> edge(parent1_id, child_id; color="gray50", penwidth="1.5")
        end
        
        # Arista del segundo padre (sin etiqueta para evitar duplicación)
        g = g |> edge(parent2_id, child_id; 
                     color="gray50", 
                     penwidth="1.5",
                     style="dashed")  # Línea punteada para diferenciar
    end
    
    return g  # Devolver objeto digraph directamente
end

"""
    to_dot(formula::FOLFormula; kwargs...)

Versión conveniente que toma una fórmula FOL y genera directamente el grafo DOT
del proceso de resolución.

# Parámetros
- `formula`: Fórmula FOL a procesar
- `kwargs...`: Parámetros adicionales para `to_dot(history; ...)`

# Retorna
Objeto digraph de GraphvizDotLang (visualizable interactivamente)

# Ejemplo
```julia
f = ∀(x, P(x) > Q(x)) & P(a) & !Q(a)
g = to_dot(f)  # Muestra automáticamente en Pluto/Jupyter
```
"""
function to_dot(formula::FOLFormula; kwargs...)
    # Preparar fórmula
    skolemized = to_Sk(formula)
    clauses = to_clauses(skolemized)
    
    # Ejecutar resolución
    history = RES_FOL_with_tracking(clauses; max_iterations=1000)
    
    # Generar DOT
    return to_dot(history; kwargs...)
end

"""
    to_file(history::RESHistory; 
                       save_path::Union{String,Nothing}=nothing,
                       format::String="svg",
                       kwargs...)

Visualiza el grafo de resolución y opcionalmente lo guarda en archivo.

# Parámetros
- `history`: Historial de resolución
- `save_path`: Ruta para guardar (sin extensión). Si es `nothing`, solo visualiza
- `format`: Formato de salida ("svg", "png", "pdf", etc.)
- `kwargs...`: Parámetros para `to_dot`

# Retorna
Objeto digraph de GraphvizDotLang

# Ejemplo
```julia
clauses = to_clauses(formula)
history = RES_FOL_with_tracking(clauses)

# Solo visualizar (en Pluto/Jupyter)
g = to_file(history)

# Visualizar y guardar
g = to_file(history, save_path="mi_prueba", format="png")
```
"""
function to_file(history::RESHistory; 
                            save_path::Union{String,Nothing}=nothing,
                            format::String="svg",
                            kwargs...)
    
    if !GRAPHVIZ_DOTLANG_AVAILABLE
        error("GraphvizDotLang no está disponible. Instálalo con: using Pkg; Pkg.add(\"GraphvizDotLang\")")
    end
    
    # Generar grafo DOT
    g = to_dot(history; kwargs...)
    
    # Guardar si se especifica ruta
    if save_path !== nothing
        # Escribir archivo .dot
        dot_file = "$(save_path).dot"
        open(dot_file, "w") do io
            write(io, string(g))
        end
        
        println("✅ Archivo DOT guardado: $dot_file")
        
        # Intentar compilar con Graphviz si está disponible
        output_file = "$(save_path).$(format)"
        try
            run(`dot -T$(format) $(dot_file) -o $(output_file)`)
            println("✅ Grafo renderizado: $output_file")
        catch e
            println("⚠️  No se pudo renderizar automáticamente (Graphviz no disponible)")
            println("   Usa: dot -T$(format) $(dot_file) -o $(output_file)")
        end
    end
    
    return g  # Devolver objeto digraph para visualización interactiva
end

"""
    to_file(formula::FOLFormula; kwargs...)

Versión conveniente que toma una fórmula y genera directamente el grafo.

# Ejemplo
```julia
f = (∀(x, P(x) > Q(x)) & P(a) & !Q(a))

# Solo visualizar
g = to_file(f)

# Visualizar y guardar
g = to_file(f, save_path="modus_ponens", format="svg")
```
"""
function to_file(formula::FOLFormula; kwargs...)
    # Preparar fórmula
    skolemized = to_Sk(formula)
    clauses = to_clauses(skolemized)
    
    # Ejecutar resolución
    history = RES_FOL_with_tracking(clauses; max_iterations=1000)
    
    # Generar y opcionalmente guardar
    return to_file(history; kwargs...)
end

end