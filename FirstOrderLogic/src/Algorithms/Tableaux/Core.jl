# ════════════════════════════════════════════════════════════════════════════
# Algoritmo Core de Construcción de Tableaux Semánticos FOL
# ════════════════════════════════════════════════════════════════════════════

"""
    TABLEROS SEMÁNTICOS PARA LÓGICA DE PRIMER ORDEN (FOL)

Sistema completo de tableros semánticos para verificar satisfactibilidad y validez
de fórmulas en lógica de primer orden. Extiende el método clásico de tableros
semánticos con reglas específicas para cuantificadores.

# Fundamentos Teóricos

Los tableros semánticos para FOL utilizan cuatro tipos de reglas:

## Reglas α (No ramificantes - aplicación exhaustiva)
- A ∧ B → A, B
- ¬(A ∨ B) → ¬A, ¬B
- ¬(A → B) → A, ¬B
- ¬¬A → A
- ¬∀x.A → ∃x.¬A
- ¬∃x.A → ∀x.¬A

## Reglas β (Ramificantes)
- A ∨ B → A | B
- ¬(A ∧ B) → ¬A | ¬B
- A → B → ¬A | B
- A ↔ B → (A ∧ B) | (¬A ∧ ¬B)
- ¬(A ↔ B) → (A ∧ ¬B) | (¬A ∧ B)

## Regla γ (Universal - aplicación múltiple)
- ∀x.A(x) → A(t) para cualquier término t
- Puede aplicarse múltiples veces con diferentes términos
- Los términos se extraen de las fórmulas en la rama

## Regla δ (Existencial - aplicación única)
- ∃x.A(x) → A(c) donde c es una constante fresca
- Solo se aplica una vez por fórmula existencial en cada rama
- Garantiza que c no aparece previamente en la rama

# Detección de Contradicciones

Una rama se cierra cuando contiene P(t) y ¬P(s) donde UMG(P(t), P(s)) existe.
Esto permite cerrar ramas con:
- P(a) y ¬P(a) (términos idénticos)
- P(x) y ¬P(a) (unificación de variable con constante)
- P(f(x)) y ¬P(f(a)) (términos complejos)

# Estrategia de Aplicación

El algoritmo aplica las reglas en este orden para optimizar el rendimiento:
1. Aplicar reglas α exhaustivamente (simplificación máxima)
2. Aplicar reglas δ (prioridad alta - constantes frescas)
3. Aplicar reglas β (ramificación cuando sea necesario)
4. Aplicar reglas γ (baja prioridad - puede causar no-terminación)

# Terminación

El procedimiento puede no terminar para fórmulas insatisfactibles que requieren
infinitas instanciaciones de cuantificadores universales. Se usa max_depth como
límite de profundidad del tablero.

# Ejemplo Básico

```julia
# Verificar que ∀x.P(x) → P(a) es válida
x, a = var("x"), Const_FOL("a")
P = predicate("P")
f = ∀(x, P(x)) > P(a)
TS_VALID(f)  # Retorna true
```

# Ver también
- `TS_SAT`: Verifica satisfactibilidad
- `TS_VALID`: Verifica validez (tautología)
- `TS_solve`: Análisis completo con clasificación
- `TS_FOL`: Construcción del tablero
- `print_TS_FOL`: Visualización del tablero
"""

"""
    TS_FOL(
        input_Fs::Vector{FOLFormula};
        depth::Int = 0,
        branch_id::String = "1",
        used_terms::Set{Term} = Set{Term}(),
        instantiated::Dict{FOLFormula, Set{Term}} = Dict{FOLFormula, Set{Term}}(),
        used_exist::Set{FOLFormula} = Set{FOLFormula}(),
        counter::Ref{Int} = TS_CONSTANT_COUNTER,
        formula_counter::Ref{Int} = Ref(0),
        max_depth::Int = 50
    ) -> TSNodeFOL

Construye un tablero semántico para lógica de primer orden.

# Estrategia de aplicación de reglas:
1. Aplicar reglas α exhaustivamente (no ramificantes)
2. Aplicar reglas δ (existenciales) - prioridad alta, solo una vez por fórmula
3. Aplicar reglas β (ramificantes)
4. Aplicar reglas γ (universales) - baja prioridad, múltiples instanciaciones

# Nota sobre terminación:
El procedimiento puede no terminar para fórmulas con cuantificadores universales
que requieren infinitas instanciaciones. Se usa max_depth como límite.
"""
function TS_FOL(
    input_Fs::Vector{T};
    depth::Int = 0,
    branch_id::String = "1",
    used_terms::Set{Term} = Set{Term}(),
    instantiated::Dict{FOLFormula, Set{Term}} = Dict{FOLFormula, Set{Term}}(),
    used_exist::Set{FOLFormula} = Set{FOLFormula}(),
    counter::Ref{Int} = Ref(STATE.TS_constant_counter),  # Referencia al estado global
    formula_counter::Ref{Int} = Ref(0),
    max_depth::Int = 50,
    parent::Union{TSNodeFOL, Nothing} = nothing,
    derived_formulas::Vector{FOLFormula} = FOLFormula[],
    derivation_rule::String = "",
    parent_formula_numbers::Vector{Int} = Int[],
    formula_map::Dict{String, Int} = Dict{String, Int}()  # ← NUEVO: para deduplicación
) where T
    # Verificar límite de profundidad
    if depth > max_depth
        node = TSNodeFOL(FOLFormula[f for f in input_Fs], depth, branch_id, 
                             used_terms, instantiated, used_exist, counter)
        node.closure_reason = "Límite de profundidad alcanzado"
        if parent === nothing
            node.formula_map = formula_map
        end
        return node
    end
    
    # Reiniciar contador de constantes si es la raíz de un nuevo tableau
    if parent === nothing && depth === 0
        reset_TS_constant_counter!()
    end
    
    Fs = FOLFormula[f for f in input_Fs]
    
    # Extraer términos iniciales
    current_terms = copy(used_terms)
    for f in Fs
        union!(current_terms, extract_terms(f))
    end
    
    # Si no hay términos, agregar una constante inicial
    if isempty(current_terms)
        push!(current_terms, Const_FOL("a"))
    end
    
    # Crear nodo
    node = TSNodeFOL(Fs, depth, branch_id, current_terms, 
                         copy(instantiated), copy(used_exist), counter, 
                         derived_formulas, parent)
    
    # Asignar información de derivación ANTES de aplicar reglas
    # (importante para que se preserve incluso si el nodo aplica más reglas)
    if !isempty(derivation_rule)
        node.derivation_rule = derivation_rule
        node.parent_formula_numbers = parent_formula_numbers
    end
    
    # Asignar números a las fórmulas derivadas de este nodo
    if !isempty(node.derived_formulas)
        for df in node.derived_formulas
            formula_key = string(df)
            if !haskey(formula_map, formula_key)
                formula_counter[] += 1
                formula_map[formula_key] = formula_counter[]
            end
        end
        # El número del nodo es el de la primera fórmula derivada
        first_key = string(node.derived_formulas[1])
        node.formula_number = formula_map[first_key]
    end
    
    # En el nodo raíz, persistir formula_map y asignar números a las fórmulas INICIALES
    # ANTES de aplicar reglas (para que aparezcan en el grafo)
    if node.parent === nothing
        node.formula_map = formula_map
        for F in Fs  # Usar Fs (fórmulas originales), no node.formulas
            formula_key = string(F)
            if !haskey(formula_map, formula_key)
                formula_counter[] += 1
                formula_map[formula_key] = formula_counter[]
            end
        end
    end
    
    # PASO 1: Aplicar UNA regla α si es posible (crear nodo hijo)
    current_Fs = copy(Fs)
    
    applied_alpha, new_Fs_alpha, alpha_formula, alpha_rule, alpha_derived = apply_α_fol(current_Fs)
    
    if applied_alpha
        # Encontrar el número de la fórmula que se descompone
        alpha_formula_key = string(alpha_formula)
        parent_num = get(formula_map, alpha_formula_key, 0)
        
        # Crear nodo hijo con la regla α aplicada
        # Pasamos TODAS las fórmulas derivadas
        child = TS_FOL(
            new_Fs_alpha;
            depth = depth + 1,
            branch_id = branch_id,
            used_terms = node.used_terms,
            instantiated = node.instantiated_universals,
            used_exist = node.used_existentials,
            counter = counter,
            formula_counter = formula_counter,
            max_depth = max_depth,
            parent = node,
            derived_formulas = alpha_derived,
            derivation_rule = alpha_rule,
            parent_formula_numbers = [parent_num],
            formula_map = formula_map
        )
        
        node.children = [child]
        node.is_closed = child.is_closed
        if node.is_closed
            node.closure_reason = "Rama hija cerrada"
        end
        if node.parent === nothing
            node.formula_map = formula_map
        end
        return node
    end
    
    # No se aplicó α, actualizar node con fórmulas actuales
    node.formulas = current_Fs
    
    # Actualizar términos disponibles
    for f in current_Fs
        union!(current_terms, extract_terms(f))
    end
    node.used_terms = current_terms
    
    # Verificar contradicción después de todo
    has_contr, reason = has_contradiction_fol(current_Fs)
    if has_contr
        node.is_closed = true
        node.closure_reason = reason
        # formula_map ya está persistido en el nodo
        return node
    end
    
    # PASO 2: Aplicar reglas δ (existenciales) - prioridad alta
    applied_delta, new_Fs_delta, exist_formula, fresh_term = apply_δ_fol(
        current_Fs, node.used_existentials, counter
    )
    
    if applied_delta
        # Marcar existencial como usado
        push!(node.used_existentials, exist_formula)
        push!(node.used_terms, fresh_term)
        
        # Calcular la fórmula derivada: instantiación del cuerpo del existencial
        derived = substitute_var(exist_formula.body, exist_formula.var, fresh_term)
        
        # Encontrar el número de la fórmula existencial que se expande
        exist_formula_key = string(exist_formula)
        parent_num = get(formula_map, exist_formula_key, 0)
        
        # Continuar con recursión
        child = TS_FOL(
            new_Fs_delta;
            depth = depth + 1,
            branch_id = branch_id,
            used_terms = node.used_terms,
            instantiated = node.instantiated_universals,
            used_exist = node.used_existentials,
            counter = counter,
            formula_counter = formula_counter,
            max_depth = max_depth,
            parent = node,
            derived_formulas = FOLFormula[derived],
            derivation_rule = "δ [$fresh_term]",
            parent_formula_numbers = [parent_num],
            formula_map = formula_map
        )
        
        node.children = [child]
        node.is_closed = child.is_closed
        if node.is_closed
            node.closure_reason = "Rama hija cerrada"
        end
        if node.parent === nothing
            node.formula_map = formula_map
        end
        return node
    end
    
    # PASO 3: Aplicar reglas β (ramificantes)
    found_beta, left_branch, right_branch, beta_reason = apply_β_fol(current_Fs)
    
    if found_beta
        # Las fórmulas derivadas son las últimas en cada rama (las nuevas)
        left_derived = left_branch[end]
        right_derived = right_branch[end]
        
        # Encontrar el número de la fórmula que se ramifica
        # beta_reason tiene formato "op: formula", extraer la parte después de ": "
        beta_formula_str = if contains(beta_reason, ": ")
            string(split(beta_reason, ": ")[end])
        else
            beta_reason
        end
        
        parent_num = get(formula_map, beta_formula_str, 0)
        
        # Crear copias independientes para cada rama
        left_instantiated = Dict{FOLFormula, Set{Term}}()
        for (k, v) in node.instantiated_universals
            left_instantiated[k] = copy(v)
        end
        
        left_child = TS_FOL(
            left_branch;
            depth = depth + 1,
            branch_id = branch_id * ".1",
            used_terms = copy(node.used_terms),
            instantiated = left_instantiated,
            used_exist = copy(node.used_existentials),
            counter = counter,
            formula_counter = formula_counter,
            max_depth = max_depth,
            parent = node,
            derived_formulas = FOLFormula[left_derived],
            derivation_rule = "β",
            parent_formula_numbers = [parent_num],
            formula_map = formula_map
        )
        
        right_instantiated = Dict{FOLFormula, Set{Term}}()
        for (k, v) in node.instantiated_universals
            right_instantiated[k] = copy(v)
        end
        
        right_child = TS_FOL(
            right_branch;
            depth = depth + 1,
            branch_id = branch_id * ".2",
            used_terms = copy(node.used_terms),
            instantiated = right_instantiated,
            used_exist = copy(node.used_existentials),
            counter = counter,
            formula_counter = formula_counter,
            max_depth = max_depth,
            parent = node,
            derived_formulas = FOLFormula[right_derived],
            derivation_rule = "β",
            parent_formula_numbers = [parent_num],
            formula_map = formula_map
        )
        
        node.children = [left_child, right_child]
        node.is_closed = left_child.is_closed && right_child.is_closed
        if node.is_closed
            node.closure_reason = "Ambas ramas cerradas"
        end
        if node.parent === nothing
            node.formula_map = formula_map
        end
        return node
    end
    
    # PASO 4: Aplicar reglas γ (universales) - baja prioridad
    applied_gamma, new_Fs_gamma, univ_formula, term_used = apply_γ_fol(
        current_Fs, node.used_terms, node.instantiated_universals, counter, branch_id
    )
    
    if applied_gamma
        # Registrar instanciación
        if !(univ_formula in keys(node.instantiated_universals))
            node.instantiated_universals[univ_formula] = Set{Term}()
        end
        push!(node.instantiated_universals[univ_formula], term_used)
        
        # Si la constante es nueva (generada por falta de términos cerrados), agregarla a used_terms
        if !in(term_used, node.used_terms)
            push!(node.used_terms, term_used)
        end
        
        # Calcular la fórmula derivada: instanciación del universal
        derived = substitute_var(univ_formula.body, univ_formula.var, term_used)
        
        # Encontrar el número de la fórmula universal que se instancia
        univ_formula_key = string(univ_formula)
        parent_num = get(formula_map, univ_formula_key, 0)
        
        # Continuar con recursión
        child = TS_FOL(
            new_Fs_gamma;
            depth = depth + 1,
            branch_id = branch_id,
            used_terms = node.used_terms,
            instantiated = node.instantiated_universals,
            used_exist = node.used_existentials,
            counter = counter,
            formula_counter = formula_counter,
            max_depth = max_depth,
            parent = node,
            derived_formulas = FOLFormula[derived],
            derivation_rule = "γ [$term_used]",
            parent_formula_numbers = [parent_num],
            formula_map = formula_map
        )
        
        node.children = [child]
        node.is_closed = child.is_closed
        if node.is_closed
            node.closure_reason = "Rama hija cerrada"
        end
        if node.parent === nothing
            node.formula_map = formula_map
        end
        return node
    end
    
    # Caso base: solo literales, rama abierta
    # Asignar el mapa al nodo raíz antes de retornar
    if node.parent === nothing
        node.formula_map = formula_map
    end
    return node
end

"""
    TS_SAT(f::FOLFormula; max_depth::Int = 50) -> Bool

Verifica satisfactibilidad de una fórmula FOL usando tableros semánticos.

Una fórmula es satisfactible si existe al menos una interpretación que la hace
verdadera. El método construye un tablero y verifica si hay al menos una rama
abierta (sin contradicciones).

# Argumentos
- `f::FOLFormula`: Fórmula a verificar
- `max_depth::Int = 50`: Profundidad máxima del tablero (previene no-terminación)

# Retorna
- `true` si la fórmula es satisfactible (rama abierta encontrada)
- `false` si la fórmula es insatisfactible (todas las ramas se cierran)

# Ejemplos

```julia
# Variables y predicados
x, y = vars("x", "y")
P, Q = predicates("P", "Q")
a = Const_FOL("a")

# Ejemplo 1: Fórmula satisfactible simple
TS_SAT(P(a))  # true - puede ser verdadera

# Ejemplo 2: Contradicción
TS_SAT(P(a) & !P(a))  # false - imposible

# Ejemplo 3: Cuantificadores
TS_SAT(∀(x, P(x)))  # true - puede ser verdadera si todo tiene P

# Ejemplo 4: Existenciales
TS_SAT(∃(x, P(x) & Q(x)))  # true - puede existir algo con P y Q

# Ejemplo 5: Fórmula compleja
TS_SAT(∀(x, P(x) > Q(x)) & P(a) & !Q(a))  # false - contradicción
```

# Notas
- El tablero se imprime durante la ejecución mostrando todas las ramas
- Para fórmulas con ∀, puede requerir múltiples instanciaciones
- Si se alcanza max_depth, el resultado puede ser incompleto
- Rama abierta = modelo posible; Todas cerradas = contradicción

# Ver también
- `TS_VALID`: Para verificar validez/tautología
- `TS_solve`: Para análisis completo (SAT + VALID)
- `TS_FOL`: Construcción del tablero subyacente
"""
function TS_SAT(f::FOLFormula; max_depth::Int = 50)
    println("="^70)
    println("VERIFICACIÓN DE SATISFACTIBILIDAD (Tableros Semánticos FOL)")
    println("="^70)
    println("Fórmula: $f")
    println()
    
    tableau = TS_FOL([f]; max_depth = max_depth)
    print_TS_FOL(tableau)
    
    satisfiable = !tableau.is_closed
    println("\n" * "="^70)
    println("RESULTADO: $(satisfiable ? "SATISFACTIBLE ✓" : "INSATISFACTIBLE ⊗")")
    println("="^70)
    
    return satisfiable
end

"""
    TS_VALID(f::FOLFormula; max_depth::Int = 50) -> Bool

Verifica validez (tautología) de una fórmula FOL usando tableros semánticos.

Una fórmula es válida (tautología) si es verdadera en todas las interpretaciones
posibles. Esto se verifica construyendo un tablero para ¬f: si todas las ramas
se cierran, entonces f es válida.

# Ver también
- `TS_SAT`: Para verificar satisfactibilidad
- `TS_solve`: Para análisis completo con clasificación
"""
function TS_VALID(f::FOLFormula; max_depth::Int = 50)
    println("="^70)
    println("VERIFICACIÓN DE VALIDEZ (Tableros Semánticos FOL)")
    println("="^70)
    println("Fórmula: $f")
    println("Construyendo tablero para: ¬($f)")
    println()
    
    negated = NotFOL(f)
    tableau = TS_FOL([negated]; max_depth = max_depth)
    print_TS_FOL(tableau)
    
    valid = tableau.is_closed
    println("\n" * "="^70)
    println("RESULTADO: $(valid ? "VÁLIDA (TAUTOLOGÍA) ✓" : "NO VÁLIDA ⊗")")
    println("="^70)
    
    return valid
end

"""
    TS_solve(f::FOLFormula; max_depth::Int = 50) -> (Bool, Bool)

Realiza un análisis completo de una fórmula FOL verificando tanto satisfactibilidad
como validez, y clasifica la fórmula según su naturaleza lógica.

# Ver también
- `TS_SAT`: Solo verificación de satisfactibilidad
- `TS_VALID`: Solo verificación de validez
- `TS_FOL`: Construcción del tablero subyacente
"""
function TS_solve(f::FOLFormula; max_depth::Int = 50)
    println("="^70)
    println("ANÁLISIS COMPLETO CON TABLEROS SEMÁNTICOS (FOL)")
    println("="^70)
    println("Fórmula: $f")
    println()
    
    # Satisfactibilidad
    println("1. SATISFACTIBILIDAD:")
    println("-"^70)
    sat = TS_SAT(f; max_depth = max_depth)
    println()
    
    # Validez
    println("2. VALIDEZ:")
    println("-"^70)
    valid = TS_VALID(f; max_depth = max_depth)
    println()
    
    # Resumen
    println("="^70)
    println("RESUMEN")
    println("="^70)
    println("Fórmula: $f")
    println("Satisfactible: $(sat ? "SÍ ✓" : "NO ⊗")")
    println("Válida (Tautología): $(valid ? "SÍ ✓" : "NO ⊗")")
    
    if sat && !valid
        println("Clasificación: CONTINGENTE")
    elseif !sat
        println("Clasificación: CONTRADICCIÓN")
    elseif valid
        println("Clasificación: TAUTOLOGÍA")
    end
    println("="^70)
    
    return sat, valid
end
