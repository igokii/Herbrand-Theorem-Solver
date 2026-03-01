"""
# Algorithms.Resolution - Algoritmo de Resolución

Este submódulo implementa el algoritmo de resolución para la verificación
de satisfactibilidad de fórmulas en forma clausal (CF).

## Descripción del algoritmo:
La resolución es un método refutacional que busca derivar la cláusula vacía
(contradicción) a partir de un conjunto de cláusulas.

## Principio de resolución:
Dadas dos cláusulas que contienen literales complementarios, se puede
inferir una nueva cláusula (resolvente) que combina el resto de literales.

## Regla de resolución:
- C₁ ∨ p, C₂ ∨ ¬p ⊢ C₁ ∨ C₂
- Si C₁ = ∅ y C₂ = ∅, entonces la resolvente es ☐ (cláusula vacía)

## Aplicaciones:
- Verificación de satisfactibilidad (SAT)
- Verificación de consecuencia lógica
- Demostración automática de teoremas
- Fundamento de la programación lógica

## Ventajas:
- Completo y correcto
- Mecanizable
- Base teórica sólida

## Autor: Fernando Sancho Caparrini
## Curso: Lógica Informática 2025-2026
"""
module Resolution

using ..Types
using ..Evaluation
using ..NormalForms
using ..DPLL_module
import Base: show

export ExtendedClause, literals, resolve, find_complementary_pairs,
       is_subsumed, remove_subsumed, clean_resolution_clauses,
       to_resolution_clauses, RES, RES_Regular, RES_SAT, RES_TAUT, RES_LC, RES_solve,
       RES_Regular_SAT, RES_Regular_TAUT, RES_Regular_LC, RES_Regular_solve,
       show_resolution_trace, resolution_statistics

# ==================== ESTRUCTURA EXTENDIDA DE CLÁUSULAS ====================

"""
    ExtendedClause

Tipo extendido de cláusula que incluye información de traza para resolución.

# Campos
- `base::Clause`: Cláusula base con los literales
- `parents::Vector{Int}`: Índices de las cláusulas padre que generaron esta
- `rule::String`: Descripción de la regla aplicada para generar la cláusula

# Información de traza
Permite seguir la derivación completa desde las cláusulas iniciales
hasta la cláusula vacía, facilitando la comprensión del proceso de prueba.
"""
struct ExtendedClause
    base::Clause
    parents::Vector{Int}  # Índices de las cláusulas padre (para traza)
    rule::String          # Regla aplicada para generar esta cláusula
end

"""
    ExtendedClause(literals::Set{Literal}) -> ExtendedClause

Constructor para crear una cláusula inicial desde un conjunto de literales.
"""
function ExtendedClause(literals::Set{Literal})
    return ExtendedClause(Clause(literals), Int[], "inicial")
end

"""
    ExtendedClause(clause::Clause) -> ExtendedClause

Constructor para crear una cláusula inicial desde una Clause.
"""
function ExtendedClause(clause::Clause)
    return ExtendedClause(clause, Int[], "inicial")
end

function Base.show(io::IO, C::ExtendedClause)
    print(io, C.base)
end

"""
    literals(C::ExtendedClause) -> Set{Literal}

Función de acceso para obtener los literales de una cláusula extendida.
Proporciona compatibilidad con código que espera .literals directamente.
"""
function literals(C::ExtendedClause)
    return C.base.literals
end

# ==================== OPERACIONES DE RESOLUCIÓN ====================

"""
    find_complementary_pairs(C1::ExtendedClause, C2::ExtendedClause) -> Vector{Tuple{Literal,Literal}}

Encuentra todos los pares de literales complementarios entre dos cláusulas.

# Definición
Dos literales L₁ y L₂ son complementarios si se refieren a la misma variable
pero con polaridades opuestas (p y ¬p).

# Retorna
Vector de tuplas (L1, L2) donde L1 ∈ C1, L2 ∈ C2 y L1, L2 son complementarios.

# Ejemplos
```julia
# C1: {p, q}, C2: {¬p, r}
# Pares complementarios: [(p, ¬p)]
```

# Uso en resolución
Cada par complementario representa una oportunidad de aplicar la regla de resolución.
"""
function find_complementary_pairs(C1::ExtendedClause, C2::ExtendedClause)
    return [(L1, L2) for L1 in C1.base.literals, L2 in C2.base.literals if are_complementary(L1, L2)]
end

"""
    resolve(C1::ExtendedClause, C2::ExtendedClause, L1::Literal, L2::Literal, idx1::Int, idx2::Int) -> Union{ExtendedClause, Nothing}

Aplica la regla de resolución entre dos cláusulas sobre literales complementarios.

# Regla de resolución
Dadas C₁ ∨ L₁ y C₂ ∨ L₂ donde L₁ y L₂ son complementarios,
la resolvente es C₁ ∨ C₂.

# Argumentos
- `C1, C2`: Cláusulas a resolver
- `L1, L2`: Literales complementarios específicos
- `idx1, idx2`: Índices de las cláusulas (para traza)

# Retorna
- `ExtendedClause`: Nueva cláusula resolvente con información de traza
- `nothing`: Si se genera una tautología (se descarta)

# Casos especiales
- Si ambas cláusulas son unitarias con literales complementarios: ☐ (cláusula vacía)
- Si la resolvente contiene literales complementarios: tautología (se descarta)

# Ejemplos
```julia
# C1: {p, q}, C2: {¬p, r}, L1: p, L2: ¬p
# Resolvente: {q, r}
```
"""
function resolve(C1::ExtendedClause, C2::ExtendedClause, L1::Literal, L2::Literal, idx1::Int, idx2::Int)
    # Verificar que los literales sean complementarios
    if !are_complementary(L1, L2)
        return nothing
    end

    # Crear nueva cláusula eliminando los literales complementarios
    # C12 = C1 ∪ C2 - {L1, L2}
    C12 = union(C1.base.literals, C2.base.literals)
    delete!(C12, L1)
    delete!(C12, L2) 
    
    if isempty(C12)
        return nothing  # Cláusula tautológica
    end
    
    # Crear información de traza
    rule = "Resolución($idx1, $idx2) respecto a $(L1.variable)"
    parents = [idx1, idx2]
    return ExtendedClause(Clause(C12), parents, rule)
end

# ==================== OPTIMIZACIONES Y FILTROS ====================

"""
    is_subsumed(C1::ExtendedClause, C2::ExtendedClause) -> Bool

Verifica si una cláusula está subsumida por otra.

# Definición de subsunción
C₁ está subsumida por C₂ si todos los literales de C₂ están en C₁.
En este caso, C₂ es más general y C₁ puede eliminarse.

# Ejemplos
```julia
# C1: {p, q, r}, C2: {p, q}
# C1 está subsumida por C2 porque {p, q} ⊆ {p, q, r}
```

# Optimización
Eliminar cláusulas subsumidas reduce el espacio de búsqueda sin afectar
la satisfactibilidad del conjunto.
"""
function is_subsumed(C1::ExtendedClause, C2::ExtendedClause)
    # C1 está subsumida por C2 si todos los literales de C2 están en C1
    return issubset(C2.base.literals, C1.base.literals)
end

"""
    remove_subsumed(clauses::Vector{ExtendedClause}) -> Vector{ExtendedClause}

Elimina cláusulas subsumidas de un conjunto de cláusulas.

# Algoritmo
Para cada cláusula C₁, verifica si existe otra cláusula C₂ tal que
C₁ está subsumida por C₂. Si es así, elimina C₁.

# Complejidad
O(n²) donde n es el número de cláusulas.

# Efecto
Reduce el tamaño del conjunto sin cambiar la satisfactibilidad.
"""
function remove_subsumed(clauses::Vector{ExtendedClause})
    filtered = ExtendedClause[]
    
    for (i, C1) in enumerate(clauses)
        is_subsumed_by_any = false
        
        for (j, C2) in enumerate(clauses)
            if i != j && is_subsumed(C1, C2)
                is_subsumed_by_any = true
                break
            end
        end
        
        if !is_subsumed_by_any
            push!(filtered, C1)
        end
    end
    
    return filtered
end

"""
    clean_resolution_clauses(clauses::Vector{ExtendedClause}) -> Vector{ExtendedClause}

Aplica optimizaciones de limpieza a un conjunto de cláusulas.

# Optimizaciones aplicadas:
1. Eliminación de tautologías
2. Eliminación de cláusulas subsumidas

# Uso
Se aplica periódicamente durante el algoritmo de resolución para
mantener el conjunto de cláusulas optimizado.
"""
function clean_resolution_clauses(clauses::Vector{ExtendedClause})
    # Primero eliminar tautologías
    non_tautological = [C for C in clauses if !is_tautological(C.base)]
    
    # Luego eliminar subsumidas
    return remove_subsumed(non_tautological)
end

"""
    to_resolution_clauses(clauses::Vector{Clause}) -> Vector{ExtendedClause}

Convierte cláusulas normales a cláusulas extendidas para resolución.

# Uso
Función de interfaz para preparar cláusulas provenientes de la conversión CNF
para su uso en el algoritmo de resolución.
"""
function to_resolution_clauses(clauses::Vector{Clause})
    return [ExtendedClause(C) for C in clauses]
end

# ==================== FUNCIONES DE UTILIDAD ====================

"""
    show_resolution_trace(clauses::Vector{ExtendedClause})

Muestra la traza completa de derivación de cláusulas.

# Formato de salida
Para cada cláusula muestra:
- Su índice
- Su contenido
- Sus cláusulas padre (si las tiene)
- La regla aplicada para generarla

# Utilidad educativa
Permite seguir el proceso completo de derivación desde las premisas
iniciales hasta la cláusula vacía.
"""
function show_resolution_trace(clauses::Vector{ExtendedClause})
    println("=== TRAZA DE RESOLUCIÓN ===")
    for (i, C) in enumerate(clauses)
        if isempty(C.parents)
            println("C$i: $C (inicial)")
        else
            parent_str = join(["C$(p)" for p in C.parents], ", ")
            println("C$i: $C ($(C.rule) de $parent_str)")
        end
    end
    println()
end

"""
    resolution_statistics(Cs::Vector{ExtendedClause})

Muestra estadísticas detalladas de un conjunto de cláusulas.

# Estadísticas incluidas:
- Total de cláusulas
- Cláusulas vacías
- Cláusulas unitarias  
- Tautologías detectadas
- Distribución por tamaño

# Utilidad
Permite analizar la complejidad y características del problema.
"""
function resolution_statistics(Cs::Vector{ExtendedClause})
    println("=== ESTADÍSTICAS DE RESOLUCIÓN ===")
    
    total_clauses = length(Cs)
    empty_clauses = count(C -> isempty(C.base.literals), Cs)
    unit_clauses = count(C -> length(C.base.literals) == 1, Cs)
    tautologies = count(C -> is_tautological(C.base), Cs)
    
    println("Total de cláusulas: $total_clauses")
    println("Cláusulas vacías: $empty_clauses")
    println("Cláusulas unitarias: $unit_clauses")
    println("Tautologías: $tautologies")
    
    # Distribución por tamaño
    size_dist = Dict{Int, Int}()
    for C in Cs
        size = length(C.base.literals)
        size_dist[size] = get(size_dist, size, 0) + 1
    end
    
    println("Distribución por tamaño:")
    for size in sort(collect(keys(size_dist)))
        println("  Tamaño $size: $(size_dist[size]) cláusulas")
    end
    println()
end

# ==================== ALGORITMO PRINCIPAL DE RESOLUCIÓN ====================

"""
    RES(clauses::Vector{ExtendedClause}; verbose::Bool = true) -> (Bool, Union{ExtendedClause, Nothing}, Int)

Implementación principal del algoritmo de resolución.

# Algoritmo:
1. **Inicialización**: Preparar conjunto inicial de cláusulas
2. **Bucle principal**: 
   - Para cada par de cláusulas, intentar resolución
   - Generar nuevas resolventes
   - Detectar cláusula vacía (insatisfactible)
   - Verificar punto fijo (satisfactible)
3. **Optimización**: Eliminar tautologías y duplicados

# Argumentos
- `clauses`: Vector de cláusulas extendidas
- `verbose`: Mostrar proceso detallado

# Retorna
Tupla (insatisfactible, cláusula_vacía, iteraciones) donde:
- `insatisfactible`: true si se deriva la cláusula vacía
- `cláusula_vacía`: la cláusula vacía derivada (si existe)
- `iteraciones`: número de iteraciones realizadas

# Criterios de terminación:
- **Insatisfactible**: Se deriva la cláusula vacía (☐)
- **Satisfactible**: No se generan nuevas cláusulas (punto fijo)
- **Timeout**: Se alcanza el límite de iteraciones

# Optimizaciones implementadas:
- Detección temprana de tautologías
- Eliminación de duplicados con lookup O(1)
- Control de subsunción
- Límite de iteraciones para evitar bucles infinitos
"""
# function RES(cls::Vector{ExtendedClause}; verbose::Bool = true)
function RES(cls::Vector{Clause}; verbose::Bool = true)
    clauses = to_resolution_clauses(cls)
    if verbose
        println("=== ALGORITMO DE RESOLUCIÓN ===")
        println("Cláusulas iniciales:")
        for (i, C) in enumerate(clauses)
            println("  C$i: $C")
        end
        println()
    end
    
    # Estructuras de datos para optimización
    current_clauses_dict = Dict{Set{Literal}, ExtendedClause}()
    all_clauses_dict = Dict{Set{Literal}, ExtendedClause}()
    
    # Inicializar con cláusulas iniciales
    for C in clauses
        if !is_tautological(C.base)
            current_clauses_dict[C.base.literals] = C
            all_clauses_dict[C.base.literals] = C
        end
    end
    current_clauses = collect(values(current_clauses_dict))
    
    iteration = 0
    max_iterations = 1000
    
    while iteration < max_iterations
        iteration += 1
        if verbose
            println("--- Iteración $iteration ---")
            println("  Cláusulas actuales: $(length(current_clauses_dict))")
        end
        
        # Contadores para estadísticas
        resolutions_attempted = 0
        resolutions_successful = 0
        tautologies_discarded = 0
        duplicates_avoided = 0
        
        new_clauses_dict = Dict{Set{Literal}, ExtendedClause}()
        clauses_vec = current_clauses
        
        # Intentar resolver cada par de cláusulas
        for i in 1:length(clauses_vec)
            for j in (i+1):length(clauses_vec)
                C1, C2 = clauses_vec[i], clauses_vec[j]
                
                # Encontrar pares complementarios
                comp_pairs = find_complementary_pairs(C1, C2)
                
                for (L1, L2) in comp_pairs
                    resolutions_attempted += 1
                    
                    if verbose
                        println("  Intentando resolver: $C1 ⊗ $C2 sobre variable $(L1.variable.name)")
                        println("    Literales: $L1 vs $L2")
                    end
                    
                    resolvent = resolve(C1, C2, L1, L2, i, j)
                    
                    if resolvent !== nothing
                        # Mostrar la resolvente generada
                        if verbose
                            println("    → Resolvente generada: $resolvent")
                        end
                        
                        # Verificar si es la cláusula vacía
                        if isempty(resolvent.base.literals)
                            if verbose
                                println("    ☐ ¡CLÁUSULA VACÍA DERIVADA!")
                                println("    Padres: $C1, $C2")
                                println("    Literales resueltos: $L1, $L2")
                                println("\n🔥 ¡INSATISFACTIBLE! Se derivó la cláusula vacía.")
                            end
                            return true, resolvent, iteration
                        end
                        
                        # Verificar si es tautología
                        if is_tautological(resolvent.base)
                            tautologies_discarded += 1
                            if verbose
                                println("    ❌ Descartada: Tautología → $resolvent")
                            end
                            continue
                        end
                        
                        # Verificar duplicados
                        is_duplicate = haskey(all_clauses_dict, resolvent.base.literals)
                        
                        if is_duplicate
                            duplicates_avoided += 1
                            if verbose
                                println("    ❌ Descartada: Duplicado → $resolvent")
                            end
                            continue
                        end
                        
                        # Agregar nueva cláusula
                        resolutions_successful += 1
                        new_clauses_dict[resolvent.base.literals] = resolvent
                        
                        if verbose
                            println("    ✅ Añadida: $resolvent")
                        end
                    else
                        if verbose
                            println("    ❌ Resolución fallida")
                        end
                    end
                end
            end
        end
        
        # Mostrar estadísticas de la iteración
        if verbose
            println("\n  📊 Estadísticas de Iteración $iteration:")
            println("    Resoluciones intentadas: $resolutions_attempted")
            println("    Resoluciones exitosas: $resolutions_successful")
            println("    Tautologías descartadas: $tautologies_discarded")
            println("    Duplicados evitados: $duplicates_avoided")
            println("    Nuevas cláusulas generadas: $(length(new_clauses_dict))")
        end
        
        # Verificar si se generaron nuevas cláusulas
        no_new_clauses = isempty(new_clauses_dict)
        
        if no_new_clauses
            if verbose
                println("  ❌ No se generaron nuevas cláusulas.")
                println("\n✅ SATISFACTIBLE - No se puede derivar la cláusula vacía.")
            end
            return false, nothing, iteration
        end
        
        # Agregar nuevas cláusulas a los conjuntos
        merge!(current_clauses_dict, new_clauses_dict)
        merge!(all_clauses_dict, new_clauses_dict)
        current_clauses = collect(values(current_clauses_dict))
        if verbose
            println("  📈 Total de cláusulas acumuladas: $(length(all_clauses_dict))")
        end
        
        if verbose
            println("  🔄 Continuando a la siguiente iteración...\n")
        end
    end
    
    if verbose
        println("⏰ Se alcanzó el límite máximo de iteraciones ($max_iterations).")
    end
    return false, nothing, iteration
end

"""
    RES_Regular(clauses::Vector{ExtendedClause}) -> (Bool, Union{ExtendedClause, Nothing}, Int)

Implementación del algoritmo de resolución regular.
"""
function RES_Regular(cls::Vector{Clause})
    S = to_resolution_clauses(cls)
    # Obtener las variables proposicionales del conjunto S
    vars = vars_of(cls)
    # Ordenar las variables
    sorted_vars = sort(vars, by = v -> v.name)

    # Inicializar S0
    S0 = S
    for p in sorted_vars
        # Calcular resolventes respecto a p
        new_clauses = ExtendedClause[]
        for i in 1:length(S0)
        for j in (i+1):length(S0)
            C1, C2 = S0[i], S0[j]
            resolvent = resolve(C1, C2, Literal(p,true), Literal(p,false), i, j)
            if !is_tautological(resolvent.base) && !any(c -> is_subsumed(resolvent, c), new_clauses)
                push!(new_clauses, resolvent)
            end
        end
        end

        # Filtrar cláusulas que contienen p o ¬p
        new_clauses = [C for C in new_clauses if !(p in C.base.literals || !p in C.base.literals)]
        
        # Comprobar si se ha obtenido la cláusula vacía
        if any(c -> isempty(c.base.literals), new_clauses)
        return false  # S no es satisfactible
        end

        # Actualizar S0 para la siguiente variable
        S0 = new_clauses
    end

    return true  # S es satisfactible
end

function vars_of(Cs::Vector{Clause})
    return [L.variable for C in Cs for L in C.literals]
end

# ==================== FUNCIONES DE INTERFAZ ====================

"""
    RES_SAT(f::FormulaPL; verbose::Bool = true) -> Bool

Verifica satisfactibilidad de una fórmula usando resolución.

# Algoritmo
1. Convierte la fórmula a forma clausal (CNF)
2. Aplica el algoritmo de resolución
3. La fórmula es satisfactible ↔ no se deriva la cláusula vacía

# Ejemplos
```julia
p, q = vars("p", "q")
formula = (p | q) & (!p | q) & (p | !q)
result = RES_SAT(formula, verbose=true)
```
"""
function RES_SAT(f::FormulaPL; verbose::Bool = true)
    try
        if verbose
            println("=== VERIFICACIÓN DE SATISFACTIBILIDAD ===")
            println("Fórmula: $f")
            println("=" ^ (50 + length(string(f))))
        end
        
        # Convertir a forma clausal
        Cs = to_CF(f)
        
        if verbose
            println("Forma clausal:")
            for (i, C) in enumerate(Cs)
                println("  $i: $C")
            end
            println()
        end
        
        # Convertir a ExtendedClause
        res_clauses = to_resolution_clauses(Cs)
        
        # Aplicar algoritmo de resolución
        is_unsat, empty_clause, iterations = RES(res_clauses, verbose=verbose)
        
        satisfiable = !is_unsat
        
        if verbose
            println("\n=== RESULTADO FINAL ===")
            println("Fórmula: $f")
            println("Satisfactible: $(satisfiable ? "✅ SÍ" : "❌ NO")")
            println("Iteraciones: $iterations")
        end
        
        return satisfiable
        
    catch e
        if verbose
            println("Error en RES_SAT: $e")
        end
        return false
    end
end

"""
    RES_TAUT(f::FormulaPL; verbose::Bool = true) -> Bool

Verifica si una fórmula es tautología usando resolución.

# Método
f es tautología ↔ ¬f es insatisfactible

# Ejemplos
```julia
p = vars("p")[1]
tautologia = p | !p
result = RES_TAUT(tautologia, verbose=true)
```
"""
function RES_TAUT(f::FormulaPL; verbose::Bool = true)
    if verbose
        println("=== VERIFICACIÓN DE TAUTOLOGÍA ===")
        println("Verificando si es tautología: $f")
        println("Verificando satisfactibilidad de ¬($f)")
        println("=" ^ (40 + length(string(f))))
    end
    
    # Una fórmula es tautología si su negación es insatisfactible
    neg_f = !(f)
    is_neg_sat = RES_SAT(neg_f, verbose=verbose)
    
    is_tautology = !is_neg_sat
    
    if verbose
        println("\n=== RESULTADO FINAL DE TAUTOLOGÍA ===")
        println("¬($f) es $(is_neg_sat ? "satisfactible" : "insatisfactible")")
        println("Por tanto, $f $(is_tautology ? "✅ ES" : "❌ NO ES") una tautología")
    end
    
    return is_tautology
end

"""
    RES_LC(Γ::Vector{FormulaPL}, φ::FormulaPL; verbose::Bool = true) -> Bool

Verifica consecuencia lógica usando resolución.

# Método
Γ ⊨ φ ↔ Γ ∪ {¬φ} es insatisfactible

# Ejemplos
```julia
p, q, r = vars("p", "q", "r")
premisas = [p > q, q > r]
conclusion = p > r
es_consecuencia = RES_LC(premisas, conclusion, verbose=true)
```
"""
function RES_LC(Γ::Vector{FormulaPL}, φ::FormulaPL; verbose::Bool = true)
    if verbose
        println("=== VERIFICACIÓN DE CONSECUENCIA LÓGICA ===")
        println("Premisas:")
        for (i, F) in enumerate(Γ)
            println("  F$i: $F")
        end
        println("Conclusión: $φ")
        println()
    end
    
    # Γ ⊨ φ si y solo si Γ ∪ {¬φ} es insatisfactible
    if isempty(Γ)
        if verbose
            println("No hay premisas. Verificando si la conclusión es tautología...")
        end
        return RES_TAUT(φ, verbose=verbose)
    end
    
    # Crear Γ ∧ ¬φ
    test_formula = ⋀(Γ) & !(φ)
    
    if verbose
        println("Verificando insatisfactibilidad de: Γ ∧ ¬φ")
        println("Donde Γ ∧ ¬φ = $test_formula")
        println()
    end
    
    # Usar resolución para verificar si es insatisfactible
    is_sat = RES_SAT(test_formula, verbose=verbose)
    is_consequence = !is_sat
    
    if verbose
        println("\n=== RESULTADO DE CONSECUENCIA LÓGICA ===")
        if is_consequence
            println("✅ $φ ES consecuencia lógica de las premisas")
        else
            println("❌ $φ NO ES consecuencia lógica de las premisas")
        end
    end
    
    return is_consequence
end

"""
    RES_LC(F::FormulaPL, φ::FormulaPL; verbose::Bool = true) -> Bool

Función auxiliar para verificar consecuencia lógica con una sola premisa.
"""
function RES_LC(F::FormulaPL, φ::FormulaPL; verbose::Bool = true)
    return RES_LC([F], φ, verbose=verbose)
end

"""
    RES_solve(f::FormulaPL; verbose::Bool = true) -> (Bool, Bool)

Análisis completo de una fórmula usando resolución.

# Análisis realizado:
1. Verificación de satisfactibilidad
2. Verificación de validez (tautología)  
3. Clasificación semántica

# Retorna
Tupla (satisfactible, tautologia) con los resultados.
"""
function RES_solve(f::FormulaPL; verbose::Bool = true)
    if verbose
        println("=== ANÁLISIS COMPLETO CON RESOLUCIÓN ===")
        println("Fórmula: $f")
        println()
    end
    
    # Verificar satisfactibilidad
    verbose && println("1. VERIFICACIÓN DE SATISFACTIBILIDAD:")
    satisfiable = RES_SAT(f, verbose=verbose)
    verbose && println()
    
    # Verificar si es tautología
    verbose && println("2. VERIFICACIÓN DE VALIDEZ (TAUTOLOGÍA):")
    is_tautology = RES_TAUT(f, verbose=verbose)
    verbose && println()
    
    # Resumen
    if verbose
        println("=== RESUMEN FINAL ===")
        println("Fórmula: $f")
        println("Satisfactible: $(satisfiable ? "✅ SÍ" : "❌ NO")")
        println("Tautología: $(is_tautology ? "✅ SÍ" : "❌ NO")")
        
        if satisfiable && !is_tautology
            println("Clasificación: CONTINGENTE")
        elseif !satisfiable
            println("Clasificación: CONTRADICCIÓN")
        elseif satisfiable && is_tautology
            println("Clasificación: TAUTOLOGÍA")
        end
    end
    
    return satisfiable, is_tautology
end

"""
    RES_Regular_SAT(f::FormulaPL) -> Bool

Verifica satisfactibilidad de una fórmula usando resolución regular.

# Algoritmo
1. Convierte la fórmula a forma clausal (CNF)
2. Aplica el algoritmo de resolución regular
3. La fórmula es satisfactible ↔ no se deriva la cláusula vacía

# Ventajas de resolución regular:
- Menor espacio de búsqueda que resolución estándar
- Mantiene completitud
- Más eficiente en muchos casos prácticos

# Ejemplos
```julia
p, q = vars("p", "q")
formula = (p | q) & (!p | q) & (p | !q)
result = RES_Regular_SAT(formula)
```
"""
function RES_Regular_SAT(f::FormulaPL)
    # Convertir a forma clausal
    Cs = to_CF(f)
    # Convertir a ExtendedClause
    res_clauses = to_resolution_clauses(Cs)
    # Aplicar algoritmo de resolución regular
    is_unsat, empty_clause, iterations = RES_Regular(res_clauses)
    satisfiable = !is_unsat
    return satisfiable
end

"""
    RES_Regular_TAUT(f::FormulaPL) -> Bool

Verifica si una fórmula es tautología usando resolución regular.

# Método
f es tautología ↔ ¬f es insatisfactible

# Ejemplos
```julia
p = vars("p")[1]
tautologia = p | !p
result = RES_Regular_TAUT(tautologia)
```
"""
function RES_Regular_TAUT(f::FormulaPL)
    # Una fórmula es tautología si su negación es insatisfactible
    neg_f = !(f)
    is_neg_sat = RES_Regular_SAT(neg_f)
    is_tautology = !is_neg_sat
    return is_tautology
end

"""
    RES_Regular_LC(Γ::Vector{FormulaPL}, φ::FormulaPL) -> Bool

Verifica consecuencia lógica usando resolución regular.

# Método
Γ ⊨ φ ↔ Γ ∪ {¬φ} es insatisfactible

# Ejemplos
```julia
p, q, r = vars("p", "q", "r")
premisas = [p > q, q > r]
conclusion = p > r
es_consecuencia = RES_Regular_LC(premisas, conclusion)
```
"""
function RES_Regular_LC(Γ::Vector{FormulaPL}, φ::FormulaPL)
    # Γ ⊨ φ si y solo si Γ ∪ {¬φ} es insatisfactible
    if isempty(Γ)
        return RES_Regular_TAUT(φ)
    end
    # Crear Γ ∧ ¬φ
    test_formula = ⋀(Γ) & !(φ)
    # Usar resolución regular para verificar si es insatisfactible
    is_sat = RES_Regular_SAT(test_formula)
    is_consequence = !is_sat
    return is_consequence
end

"""
    RES_Regular_LC(F::FormulaPL, φ::FormulaPL) -> Bool

Función auxiliar para verificar consecuencia lógica con una sola premisa usando resolución regular.
"""
function RES_Regular_LC(F::FormulaPL, φ::FormulaPL)
    return RES_Regular_LC([F], φ)
end

"""
    RES_Regular_solve(f::FormulaPL) -> (Bool, Bool)

Análisis completo de una fórmula usando resolución regular.

# Análisis realizado:
1. Verificación de satisfactibilidad
2. Verificación de validez (tautología)
3. Clasificación semántica

# Retorna
Tupla (satisfactible, tautologia) con los resultados.
"""
function RES_Regular_solve(f::FormulaPL)
    # Verificar satisfactibilidad
    satisfiable = RES_Regular_SAT(f)
    # Verificar si es tautología
    is_tautology = RES_Regular_TAUT(f)
    return satisfiable, is_tautology
end

end # module Resolution
