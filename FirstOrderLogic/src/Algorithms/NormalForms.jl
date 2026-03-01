module NormalForms

using ..Types
using ..State

# ════════════════════════════════════════════════════════════════════════════
# PARTE 5: FORMAS NORMALES - Prenex, Skolem, CNF y CLAUSAL
# ════════════════════════════════════════════════════════════════════════════

export free_vars, subformulas, formation_tree
export substitute_var, rename_vars, reset_var_rename_counter!
export remove_imp, move_!_in, move_Q_out
export to_Px, to_Sk, to_Sk_optimal
export reset_skolem_counter!, reset_TS_constant_counter!
export apply_substitution, has_∃, is_Sk_form, remove_∀_prefix
export to_cnf, to_clauses
export prenex_forms, prenex_forms_sorted
export extract_Q_with_branches, compute_Sk_aridity, get_same_branch_pairs
export all_perms, filter_valid_perms, is_prefix, extract_matrix
export Literal, Clause

# ──────────────────────────────────────────────────────────────────────────
# 5.1 Renombramiento de variables
# ──────────────────────────────────────────────────────────────────────────
# Los contadores globales ahora están en state.jl (STATE)

"""
    rename_vars(f::FOLFormula) -> FOLFormula

Renombra todas las variables cuantificadas en una fórmula para que sean únicas.
Esto es esencial antes de aplicar transformaciones como la forma prenex, ya que
evita conflictos cuando variables con el mismo nombre aparecen en diferentes alcances.

# Problema que resuelve
En lógica de primer orden, es posible tener múltiples cuantificadores que usan
la misma variable. Por ejemplo:
- `∀x.P(x) ∧ ∀x.Q(x)` - las dos 'x' son diferentes
- `∀x.P(x) ∨ ∃x.Q(x)` - las dos 'x' son diferentes

Cuando aplicamos transformaciones como la forma prenex, estas variables pueden
confundirse si no las renombramos primero.

# Funcionamiento
La función recorre recursivamente la fórmula y:
1. Para cada cuantificador (∀ o ∃), genera un nombre de variable único
2. Sustituye todas las ocurrencias de esa variable en el alcance del cuantificador
3. Mantiene un registro de las variables ya usadas para evitar colisiones

# Ejemplos
```julia
x, y = vars("x", "y")
P, Q, R = predicates("P", "Q", "R")

# Caso 1: Variables repetidas en diferentes cuantificadores
f1 = ∀(x, P(x)) & ∀(x, Q(x))
f1_renamed = rename_vars(f1)
# Resultado: ∀x1.P(x1) ∧ ∀x2.Q(x2)

# Caso 2: Cuantificadores anidados con la misma variable
f2 = ∀(x, P(x) > ∃(x, Q(x)))
f2_renamed = rename_vars(f2)
# Resultado: ∀x1.(P(x1) → ∃x2.Q(x2))

# Caso 3: Fórmula compleja
f3 = (∀(x, P(x)) | ∃(y, Q(y))) & ∀(x, R(x))
f3_renamed = rename_vars(f3)
# Resultado: (∀x1.P(x1) ∨ ∃y1.Q(y1)) ∧ ∀x2.R(x2)
```

# Notas
- Las variables libres no se renombran, solo las cuantificadas
- Los nombres generados tienen la forma "variable_numero" (e.g., "x_1", "x_2")
- Después de usar esta función, es seguro aplicar `to_Px`
"""
function rename_vars(f::FOLFormula)
    reset_var_rename_counter!()
    used_names = Set{String}()
    return rename_vars_internal(f, used_names)
end

"""
    rename_vars_internal(f::FOLFormula, used_names::Set{String}) -> FOLFormula

Función interna recursiva para renombrar variables cuantificadas.

# Argumentos
- `f`: Fórmula a procesar
- `used_names`: Conjunto de nombres de variables ya usados (para evitar colisiones)

# Funcionamiento
Procesa la fórmula recursivamente:
- Para cuantificadores: genera un nuevo nombre único y sustituye en el cuerpo
- Para operadores: procesa recursivamente cada subexpresión
- Para predicados: devuelve sin modificar (no contienen cuantificadores)
"""
function rename_vars_internal(f::FOLFormula, used_names::Set{String})
    if f isa Predicate_FOL
        return f
    elseif f isa NotFOL
        return NotFOL(rename_vars_internal(f.operand, used_names))
    elseif f isa AndFOL
        left = rename_vars_internal(f.left, used_names)
        right = rename_vars_internal(f.right, used_names)
        return AndFOL(left, right)
    elseif f isa OrFOL
        left = rename_vars_internal(f.left, used_names)
        right = rename_vars_internal(f.right, used_names)
        return OrFOL(left, right)
    elseif f isa ImpliesFOL
        left = rename_vars_internal(f.left, used_names)
        right = rename_vars_internal(f.right, used_names)
        return ImpliesFOL(left, right)
    elseif f isa IffFOL
        left = rename_vars_internal(f.left, used_names)
        right = rename_vars_internal(f.right, used_names)
        return IffFOL(left, right)
    elseif f isa Forall
        # Generar un nuevo nombre único para la variable
        new_name = generate_unique_var_name(f.var.name, used_names)
        push!(used_names, new_name)
        new_var = Var_FOL(new_name)
        
        # Sustituir en el cuerpo
        new_body = substitute_var(f.body, f.var, new_var)
        renamed_body = rename_vars_internal(new_body, used_names)
        
        return Forall(new_var, renamed_body)
    elseif f isa Exists
        # Generar un nuevo nombre único para la variable
        new_name = generate_unique_var_name(f.var.name, used_names)
        push!(used_names, new_name)
        new_var = Var_FOL(new_name)
        
        # Sustituir en el cuerpo
        new_body = substitute_var(f.body, f.var, new_var)
        renamed_body = rename_vars_internal(new_body, used_names)
        
        return Exists(new_var, renamed_body)
    else
        return f
    end
end

"""
    generate_unique_var_name(base_name::String, used_names::Set{String}) -> String

Genera un nombre de variable único basado en un nombre base.

# Argumentos
- `base_name`: Nombre base de la variable (e.g., "x", "y")
- `used_names`: Conjunto de nombres ya usados

# Retorna
Un nuevo nombre único que no está en `used_names`, con la forma "base_numero"
donde "numero" es un contador incremental.

# Ejemplos
```julia
used = Set{String}()
generate_unique_var_name("x", used)  # "x_1"
push!(used, "x_1")
generate_unique_var_name("x", used)  # "x_2"
```
"""
function generate_unique_var_name(base_name::String, used_names::Set{String})
    # Eliminar sufijos numéricos previos del nombre base si existen
    clean_base = replace(base_name, r"_\d+$" => "")
    
    # Generar nombre con contador del estado global
    new_name = "$(clean_base)_$(next_var_rename_counter!())"
    
    # Verificar que sea único (aunque con el contador global debería serlo)
    while new_name in used_names
        new_name = "$(clean_base)_$(next_var_rename_counter!())"
    end
    
    return new_name
end

# ──────────────────────────────────────────────────────────────────────────
# 5.2 Forma Prenex
# ──────────────────────────────────────────────────────────────────────────

"""
    remove_imp(f::FOLFormula)::FOLFormula

Elimina los **operadores de implicación y bicondicional** de una fórmula lógica.

Reemplaza cada implicación y bicondicional por sus equivalentes usando solo
negación (¬), disyunción (∨) y conjunción (∧). Este es un paso preparatorio
para convertir fórmulas a **Forma Normal Conjuntiva (CNF)**.

# Transformaciones Realizadas
- **(A → B)** se reemplaza por **(¬A ∨ B)**
  - Equivalencia: "si A entonces B" es lo mismo que "no A o B"
  
- **(A ↔ B)** se reemplaza por **((A → B) ∧ (B → A))** que se simplifica a **((¬A ∨ B) ∧ (¬B ∨ A))**
  - Equivalencia: "A si y solo si B" es "A implica B Y B implica A"

# Parámetros
- `f::FOLFormula`: La fórmula lógica a procesar

# Devoluciones
- `FOLFormula`: Fórmula equivalente sin implicaciones ni bicondicionales

# Ejemplos
```julia
# Ejemplo 1: Implicación simple
# (P(x) → Q(y))  →  (¬P(x) ∨ Q(y))
formula = (P(x) > Q(y))  >  (-P(x) | Q(y))
remove_imp(formula)
# Resultado: OrFOL(NotFOL(Predicate_FOL(:P, ...)), Predicate_FOL(:Q, ...))

# Ejemplo 2: Bicondicional
# (P(x) ↔ Q(y))  →  ((¬P(x) ∨ Q(y)) ∧ (¬Q(y) ∨ P(x)))
formula = (P(x) ~ Q(y))  >  ((-P(x) | Q(y)) & (-Q(y) | P(x)))
remove_imp(formula)

# Ejemplo 3: Fórmula compleja
# (P(x) → Q(y)) ∧ (R(z) ↔ S(w))
formula = (P(x) > Q(y)) & (R(z) ~ S(w))
remove_imp(formula)
# Procesa recursivamente ambos lados
```

# Detalles de Implementación
- Procesa **recursivamente** toda la estructura de la fórmula
- Preserva la estructura de **negaciones, disyunciones y conjunciones** ya presentes
- Mantiene **cuantificadores** (∀, ∃) intactos, solo procesa su cuerpo
- Los **predicados simples** se devuelven sin cambios

# Paso Preparatorio
Esta función es normalmente usada como **primer paso** en la conversión a CNF:
1. `remove_imp` → Elimina → e ↔
2. `move_!_in` → Mueve negaciones adentro (NNF)
3. `to_clauses` o `distribute_or` → Convierte a CNF

# Casos Base
- Predicados, constantes: se devuelven sin cambios
- Negaciones: se procesan recursivamente
- Conectivas binarias: se procesan ambos lados
- Cuantificadores: se procesa solo el cuerpo
"""
function remove_imp(f::FOLFormula)
    if f isa IffFOL         # (A ↔ B) ≡ (A → B) ∧ (B → A)
        return AndFOL(remove_imp(ImpliesFOL(f.left, f.right)),
                      remove_imp(ImpliesFOL(f.right, f.left)))
    elseif f isa ImpliesFOL # (A → B) ≡ (¬A ∨ B)
        return OrFOL(remove_imp(!(f.left)), remove_imp(f.right))
    elseif f isa AndFOL
        return AndFOL(remove_imp(f.left), remove_imp(f.right))
    elseif f isa OrFOL
        return OrFOL(remove_imp(f.left), remove_imp(f.right))
    elseif f isa NotFOL
        return !(remove_imp(f.operand))
    elseif f isa Forall
        return Forall(f.var, remove_imp(f.body))
    elseif f isa Exists
        return Exists(f.var, remove_imp(f.body))
    else
        return f
    end
end

"""
    move_!_in(f::FOLFormula)::FOLFormula

Mueve los operadores de **negación hacia adentro** de una fórmula lógica.

Convierte la fórmula a **Forma Normal de Negación** (NNF - Negation Normal Form)
aplicando las **Leyes de De Morgan** y propiedades de cuantificadores.

En NNF, todas las negaciones se aplican directamente a predicados, no a conectivas
o cuantificadores. Esto facilita la conversión posterior a **Forma Normal Conjuntiva (CNF)**.

# Transformaciones Realizadas
- **¬¬A** → **A** (eliminación de doble negación)
  
- **¬(A ∧ B)** → **(¬A ∨ ¬B)** (Ley de De Morgan)
  
- **¬(A ∨ B)** → **(¬A ∧ ¬B)** (Ley de De Morgan)
  
- **¬∀x.P(x)** → **∃x.¬P(x)** (negación de universal)
  - "No es verdad que todo x satisface P" es "existe x que no satisface P"
  
- **¬∃x.P(x)** → **∀x.¬P(x)** (negación de existencial)
  - "No existe x que satisface P" es "para todo x, no satisface P"

# Parámetros
- `f::FOLFormula`: La fórmula lógica a procesar

# Devoluciones
- `FOLFormula`: Fórmula equivalente en forma normal de negación

# Ejemplos
```julia
# Ejemplo 1: Doble negación
# ¬¬P(x)  →  P(x)
formula = --P(x)  >  P(x)
move_!_in(formula)  # Predicate_FOL(:P, ...)

# Ejemplo 2: De Morgan con conjunción
# ¬(P(x) ∧ Q(y))  →  (¬P(x) ∨ ¬Q(y))
formula = -(P(x) & Q(y))  >  (-P(x) | -Q(y))
move_!_in(formula)
# Resultado: OrFOL(NotFOL(Predicate_FOL(:P, ...)), NotFOL(Predicate_FOL(:Q, ...)))

# Ejemplo 3: De Morgan con disyunción
# ¬(P(x) ∨ Q(y))  →  (¬P(x) ∧ ¬Q(y))
formula = -(P(x) | Q(y))  >  (-P(x) & -Q(y))
move_!_in(formula)

# Ejemplo 4: Negación de universal
# ¬∀x.P(x)  →  ∃x.¬P(x)
formula = -∀(x,P(x))  >  ∃(x,-P(x))
move_!_in(formula)
# Resultado: Exists(Var_FOL(:x), NotFOL(Predicate_FOL(:P, ...)))

# Ejemplo 5: Negación de existencial
# ¬∃x.P(x)  →  ∀x.¬P(x)
formula = -∃(x,P(x))  >  ∀(x,-P(x))
move_!_in(formula)
```

# Detalles de Implementación
- Utiliza **pattern matching** en la negación para aplicar las transformaciones
- Los operadores de **De Morgan** convierten negaciones en sus duales:
  - ∧ ↔ ∨ (cuando precedidos de ¬)
  - ∀ ↔ ∃ (cuando precedidos de ¬)
- Procesa **recursivamente** toda la estructura
- Normalmente se aplica **después de `remove_imp`**

# Paso Preparatorio para CNF
Esta función es el **segundo paso** en la conversión a CNF:
1. `remove_imp` → Elimina → y ↔
2. `move_!_in` → Mueve negaciones adentro (NNF) ← **Estás aquí**
3. `to_clauses` o `distribute_or` → Convierte a CNF

# Propiedades Importantes
- **Preserva equivalencia lógica**: la fórmula resultante es lógicamente equivalente
- **Punto fijo**: aplicar `move_!_in` dos veces da el mismo resultado
- **Terminación garantizada**: el proceso reduce siempre la complejidad de negaciones
- **Necesaria para CNF**: CNF requiere que todas las negaciones estén junto a predicados

# Casos Base
- Predicados: se devuelven sin cambios
- Negación de predicado: se devuelve tal cual (no hay más simplificación)
- Conectivas sin negación: se procesan recursivamente los operandos
- Cuantificadores sin negación: se procesa solo el cuerpo
"""
function move_!_in(f::FOLFormula)
    if f isa NotFOL
        op = f.operand
        if op isa NotFOL
            return move_!_in(op.operand) # ¬¬A ≡ A
        elseif op isa AndFOL             # ¬(A ∧ B) ≡ (¬A ∨ ¬B)
            return OrFOL(move_!_in(!(op.left)), 
                        move_!_in(!(op.right)))
        elseif op isa OrFOL             # ¬(A ∨ B) ≡ (¬A ∧ ¬B)
            return AndFOL(move_!_in(!(op.left)), 
                         move_!_in(!(op.right)))
        elseif op isa Forall            # ¬∀x.P(x) ≡ ∃x.¬P(x)
            return Exists(op.var, move_!_in(!(op.body)))
        elseif op isa Exists            # ¬∃x.P(x) ≡ ∀x.¬P(x)
            return Forall(op.var, move_!_in(!(op.body)))
        else
            return !(move_!_in(op))
        end
    elseif f isa AndFOL
        return AndFOL(move_!_in(f.left), move_!_in(f.right))
    elseif f isa OrFOL
        return OrFOL(move_!_in(f.left), move_!_in(f.right))
    elseif f isa Forall
        return Forall(f.var, move_!_in(f.body))
    elseif f isa Exists
        return Exists(f.var, move_!_in(f.body))
    else
        return f
    end
end

"""
    prenex_forms(f::FOLFormula)::Vector{FOLFormula}

Genera todas las formas prenex válidas de una fórmula.

Proceso:
1. Preprocesar: eliminar implicaciones, mover negaciones (aplicar De Morgan a cuantificadores)
2. Renombrar variables para evitar conflictos
3. Extraer cuantificadores con información de ramas
4. Generar todas las permutaciones posibles
5. Filtrar las que preservan el orden en misma rama
6. Reconstruir fórmulas prenex con cada permutación válida
"""
function prenex_forms(f::FOLFormula)::Vector{FOLFormula}
    # Paso 1: Preprocesar la fórmula (eliminar implicaciones y mover negaciones)
    f_preprocessed = remove_imp(f)
    f_preprocessed = move_!_in(f_preprocessed)
    
    # Paso 2: Renombrar variables para evitar conflictos
    f_renamed = rename_vars(f_preprocessed)
    
    # Paso 3: Extraer cuantificadores con información de ramas
    quants = extract_Q_with_branches(f_renamed)
    
    # Si no hay cuantificadores, retornar la fórmula tal cual
    if isempty(quants)
        return [f_renamed]
    end
    
    # Paso 4: Extraer la matriz (fórmula sin cuantificadores)
    matrix = extract_matrix(f_renamed)
    
    # Paso 4: Identificar restricciones - cuantificadores en la misma rama deben preservar orden
    same_branch_pairs = get_same_branch_pairs(quants)
    
    # Paso 5: Generar todas las permutaciones posibles
    all_ps = all_perms(length(quants))
    
    # Paso 6: Filtrar permutaciones que respetan las restricciones de rama
    valid_perms = filter_valid_perms(all_ps, same_branch_pairs)
    
    # Paso 7: Reconstruir fórmula prenex para cada permutación válida
    forms = FOLFormula[]
    for perm in valid_perms
        # Reordenar cuantificadores según la permutación
        reordered_quants = quants[perm]
        
        # Construir forma prenex desde adentro hacia afuera
        form = matrix
        for i in length(reordered_quants):-1:1
            (sym, var, _, _) = reordered_quants[i]
            if sym == :forall
                form = Forall(var, form)
            else
                form = Exists(var, form)
            end
        end
        push!(forms, form)
    end
    
    return forms
end

"""
    extract_Q_with_branches(f::FOLFormula) -> Vector{Tuple{Symbol, Var_FOL, Vector{Char}, Int}}

Extrae todos los cuantificadores de una fórmula con información de su ubicación en el árbol.

Retorna una tupla para cada cuantificador: (símbolo, variable, path, depth)
- símbolo: :forall o :exists
- variable: la variable cuantificada
- path: camino en el árbol (L=izquierda, R=derecha en operadores binarios)
- depth: profundidad de anidación de cuantificadores (incrementa solo con cuantificadores)

Ejemplo: ∀x.(∃y.P ∧ ∀z.Q)
- ∀x: path=[], depth=0
- ∃y: path=[L], depth=1 (dentro de x, rama izquierda del ∧)
- ∀z: path=[R], depth=1 (dentro de x, rama derecha del ∧)
"""
function extract_Q_with_branches(f::FOLFormula)::Vector{Tuple{Symbol, Var_FOL, Vector{Char}, Int}}
    quants = Tuple{Symbol, Var_FOL, Vector{Char}, Int}[]
    
    function traverse(formula, path::Vector{Char}, quant_depth::Int)
        if formula isa Forall
            push!(quants, (:forall, formula.var, copy(path), quant_depth))
            traverse(formula.body, path, quant_depth + 1)
        elseif formula isa Exists
            push!(quants, (:exists, formula.var, copy(path), quant_depth))
            traverse(formula.body, path, quant_depth + 1)
        elseif formula isa AndFOL || formula isa OrFOL || formula isa ImpliesFOL || formula isa IffFOL
            # Bifurcación: agregar L o R al path, mantener la profundidad de cuantificadores
            traverse(formula.left, vcat(path, 'L'), quant_depth)
            traverse(formula.right, vcat(path, 'R'), quant_depth)
        elseif formula isa NotFOL
            traverse(formula.operand, path, quant_depth)
        end
    end
    
    traverse(f, Char[], 0)
    return quants
end

"""
    get_same_branch_pairs(quants::Vector{Tuple{Symbol, Var_FOL, Vector{Char}, Int}}) -> Set{Tuple{Int,Int}}

Identifica pares de cuantificadores que están en la misma rama del árbol.

Dos cuantificadores están en la misma rama si uno está directamente anidado dentro del otro
sin operadores binarios entre ellos. Esto significa que uno de los paths es prefijo del otro.

Ejemplo: ∀x.∃y.P → ∀z.Q
- ∀x (path=[]) y ∃y (path=[]) están en la misma rama (∃y dentro de ∀x)
- ∀z (path=[R]) NO está en la misma rama que x,y (está en rama derecha de →)
"""
function get_same_branch_pairs(quants::Vector{Tuple{Symbol, Var_FOL, Vector{Char}, Int}})::Set{Tuple{Int,Int}}
    pairs = Set{Tuple{Int,Int}}()
    
    for i in 1:length(quants)
        for j in (i+1):length(quants)
            _, _, path_i, _ = quants[i]
            _, _, path_j, _ = quants[j]
            
            # Están en la misma rama si uno de los paths es prefijo del otro
            if is_prefix(path_i, path_j) || is_prefix(path_j, path_i)
                push!(pairs, (i, j))
            end
        end
    end
    
    return pairs
end

"""
    is_prefix(p1::Vector{Char}, p2::Vector{Char}) -> Bool

Verifica si p1 es prefijo de p2.
"""
function is_prefix(p1::Vector{Char}, p2::Vector{Char})::Bool
    if length(p1) > length(p2)
        return false
    end
    return p1 == p2[1:length(p1)]
end

"""
    all_perms(n::Int) -> Vector{Vector{Int}}

Genera todas las permutaciones posibles de [1, 2, ..., n].
"""
function all_perms(n::Int)::Vector{Vector{Int}}
    if n == 0
        return [Int[]]
    end
    return permutations(collect(1:n))
end

"""
    filter_valid_perms(perms::Vector{Vector{Int}}, same_branch_pairs::Set{Tuple{Int,Int}}) -> Vector{Vector{Int}}

Filtra las permutaciones que preservan el orden relativo de cuantificadores en la misma rama.

Para cada par (i, j) en same_branch_pairs donde i < j (i aparece antes que j en la fórmula original),
la permutación es válida solo si i aparece antes que j en la permutación.
"""
function filter_valid_perms(perms::Vector{Vector{Int}}, 
                                   same_branch_pairs::Set{Tuple{Int,Int}})::Vector{Vector{Int}}
    valid = Vector{Int}[]
    
    for perm in perms
        RES_VALID = true
        
        # Verificar cada restricción de rama
        for (i, j) in same_branch_pairs
            # Encontrar posiciones en la permutación
            pos_i = findfirst(==(i), perm)
            pos_j = findfirst(==(j), perm)
            
            # Si i < j originalmente, debe mantenerse pos_i < pos_j
            if i < j && pos_i > pos_j
                RES_VALID = false
                break
            end
        end
        
        if RES_VALID
            push!(valid, perm)
        end
    end
    
    return valid
end

"""
Extrae la matriz (fórmula sin cuantificadores) de una fórmula.
"""
function extract_matrix(f::FOLFormula)::FOLFormula
    if f isa Forall
        return extract_matrix(f.body)
    elseif f isa Exists
        return extract_matrix(f.body)
    elseif f isa NotFOL
        return NotFOL(extract_matrix(f.operand))
    elseif f isa AndFOL || f isa OrFOL || f isa ImpliesFOL || f isa IffFOL
        left_matrix = extract_matrix(f.left)
        right_matrix = extract_matrix(f.right)
        if f isa AndFOL
            return AndFOL(left_matrix, right_matrix)
        elseif f isa OrFOL
            return OrFOL(left_matrix, right_matrix)
        elseif f isa ImpliesFOL
            return ImpliesFOL(left_matrix, right_matrix)
        else  # IffFOL
            return IffFOL(left_matrix, right_matrix)
        end
    else
        return f
    end
end

# Función auxiliar para generar permutaciones
function permutations(v::Vector)::Vector{Vector}
    if length(v) <= 1
        return [v]
    end
    result = Vector{Vector}()
    for i in 1:length(v)
        rest = vcat(v[1:i-1], v[i+1:end])
        for perm in permutations(rest)
            push!(result, vcat([v[i]], perm))
        end
    end
    return result
end

"""
    compute_Sk_aridity(quants::Vector{Tuple{Symbol, Var_FOL, Vector{Char}}}) -> Int

Calcula la aridad acumulada de Skolem para una secuencia de cuantificadores.

Para cada cuantificador existencial, cuenta cuántos universales lo preceden en la secuencia.
La suma de todas estas aridades es la complejidad total de Skolemización.

# Ejemplo
```julia
# ∀x.∀y.∃z.∃w
# z: 2 universales antes → aridad 2
# w: 2 universales antes → aridad 2
# Total: 4

# ∃x.∃y.∀z.∀w
# x, y: 0 universales antes → aridad 0, 0
# Total: 0
```
"""
function compute_Sk_aridity(quants::Vector{Tuple{Symbol, Var_FOL, Vector{Char}, Int}})::Int
    total_aridity = 0
    universal_count = 0
    
    for (sym, var, path, depth) in quants
        if sym == :forall
            universal_count += 1
        else  # :exists
            # Cada existencial tiene aridad = número de universales que la preceden
            total_aridity += universal_count
        end
    end
    
    return total_aridity
end

"""
    prenex_forms_sorted(f::FOLFormula) -> Vector{Tuple{FOLFormula, Int}}

Genera todas las formas prenex válidas y las ordena por aridad de Skolem.

Retorna una lista de tuplas (fórmula, aridad_skolem) ordenadas por aridad ascendente.
La primera fórmula tiene la menor aridad (la más simple para Skolemizar).

# Ejemplo
```julia
x, y, z = vars("x", "y", "z")
P, Q = predicates("P", "Q")

# Fórmula con cuantificadores en ramas distintas
f = ∀(x, P(x)) & ∃(y, Q(y))
forms = prenex_forms_sorted(f)

# Retorna dos formas:
# 1. ∀x.∃y.(P(x) ∧ Q(y)) - aridad: 1
# 2. ∃y.∀x.(P(x) ∧ Q(y)) - aridad: 0  ← MEJOR
```
"""
function prenex_forms_sorted(f::FOLFormula)::Vector{Tuple{FOLFormula, Int}}
    # Obtener todas las formas prenex
    all_forms = prenex_forms(f)
    
    # Calcular aridad para cada forma
    forms_with_aridity = Tuple{FOLFormula, Int}[]
    
    for form in all_forms
        # Extraer los cuantificadores de la forma prenex
        quants = extract_Q_with_branches(form)
        
        # Calcular aridad
        aridity = compute_Sk_aridity(quants)
        
        push!(forms_with_aridity, (form, aridity))
    end
    
    # Ordenar por aridad ascendente
    sort!(forms_with_aridity, by = x -> x[2])
    
    return forms_with_aridity
end

"""
    to_Px(f::FOLFormula) -> FOLFormula

Convierte una fórmula FOL a su forma normal prenex.

# Forma Prenex
Una fórmula está en forma prenex si todos sus cuantificadores están al principio,
seguidos de una fórmula sin cuantificadores (la matriz). La forma general es:
    Q₁x₁.Q₂x₂...Qₙxₙ.M
donde cada Qᵢ es ∀ o ∃, y M es una fórmula sin cuantificadores.

# Proceso de conversión
1. **Eliminación de implicaciones**: Transforma → y ↔ usando equivalencias
   - IMPORTANTE: Esto debe hacerse ANTES de renombrar porque ↔ duplica variables
   - (A ↔ B) se expande a (A → B) ∧ (B → A), duplicando todas las subfórmulas
2. **Renombramiento**: Renombra variables cuantificadas para evitar conflictos
   - Después de expandir ↔, puede haber variables duplicadas que deben diferenciarse
3. **Forma Normal Negativa**: Mueve negaciones hacia adentro
4. **Extracción de cuantificadores**: Mueve cuantificadores al frente

En esta implementación, convierte una fórmula a forma prenex, seleccionando la variante con menor aridad de Skolem.

Esto garantiza que cuando se aplique Skolemización, las funciones de Skolem
tendrán la mínima complejidad posible.


# Ejemplos
```julia
x, y = vars("x", "y")
P, Q, R = predicates("P", "Q", "R")

# Ejemplo 1: Variables repetidas
f1 = ∀(x, P(x)) & ∀(x, Q(x))
prenex1 = to_Px(f1)
# Resultado: ∀x_1.∀x_2.(P(x_1) ∧ Q(x_2))

# Ejemplo 2: Con implicación
f2 = ∀(x, P(x)) > ∃(y, Q(y))
prenex2 = to_Px(f2)
# Resultado: ∃x_1.∃y_1.(¬P(x_1) ∨ Q(y_1))

# Ejemplo 3: Con equivalencia (caso crítico)
f3 = iff(∀(x, P(x)), ∃(x, Q(x)))
prenex3 = to_Px(f3)
# La equivalencia se expande primero, luego se renombran las variables duplicadas
```

# Nota importante sobre equivalencias (↔)
La equivalencia (A ↔ B) se expande a (A → B) ∧ (B → A), lo que duplica todas las
subfórmulas. Si A o B contienen cuantificadores con variables, estas aparecerán
duplicadas. Por eso es crucial eliminar equivalencias ANTES de renombrar variables.

# Orden correcto de operaciones
1. remove_imp(f)  - Expande ↔ e →, puede crear duplicados
2. rename_vars(f) - Diferencia las variables que se duplicaron
3. move_!_in(f)   - Mueve negaciones hacia adentro
4. move_Q_out(f)  - Extrae cuantificadores al frente
"""
function to_Px(f::FOLFormula)::FOLFormula
    forms_sorted = prenex_forms_sorted(f)
    
    if isempty(forms_sorted)
        # Si no hay formas (caso sin cuantificadores), retornar preprocesada
        f_prep = remove_imp(f)
        f_prep = rename_vars(f_prep)
        f_prep = move_!_in(f_prep)
        f_prep = miniscope(f_prep)
        return drop_vacuous_quantifiers(f_prep)
    end
    
    # Retornar la forma con menor aridad
    return forms_sorted[1][1]
end

"""
    miniscope(f::FOLFormula) -> FOLFormula

Aplica el principio de miniscope: mueve cuantificadores lo más adentro posible.

El miniscope reduce el alcance de los cuantificadores, empujándolos hacia las
subfórmulas donde realmente se usan sus variables. Esto puede simplificar la fórmula
y es útil en optimización de consultas.

# Transformaciones
- `∀x.(P ∧ Q)` → `(∀x.P) ∧ (∀x.Q)` si x libre en ambas
- `∀x.(P ∧ Q)` → `P ∧ (∀x.Q)` si x no libre en P
- `∃x.(P ∨ Q)` → `(∃x.P) ∨ (∃x.Q)` si x libre en ambas
- `∃x.(P ∨ Q)` → `P ∨ (∃x.Q)` si x no libre en P

# Ejemplo
```julia
x, y = vars("x", "y")
P, Q = predicates("P", "Q")
a = const_FOL("a")

# ∀x.(P(x) ∧ Q(a)) → ∀x.P(x) ∧ Q(a)
f = ∀(x, P(x) & Q(a))
miniscope(f)  # Q(a) no depende de x, se extrae
```
"""
function miniscope(f::FOLFormula)
    if f isa Forall
        body = miniscope(f.body)
        if body isa AndFOL
            # ∀x.(P ∧ Q) → (∀x.P) ∧ (∀x.Q) o P ∧ (∀x.Q) si x no en P
            x_in_left = f.var in free_vars(body.left)
            x_in_right = f.var in free_vars(body.right)
            
            if x_in_left && x_in_right
                return AndFOL(Forall(f.var, body.left), Forall(f.var, body.right))
            elseif x_in_left
                return AndFOL(Forall(f.var, body.left), body.right)
            elseif x_in_right
                return AndFOL(body.left, Forall(f.var, body.right))
            else
                return body  # x no aparece, eliminar cuantificador
            end
        elseif body isa OrFOL
            # ∀x.(P ∨ Q): si x solo en una rama, mover cuantificador a esa rama
            x_in_left = f.var in free_vars(body.left)
            x_in_right = f.var in free_vars(body.right)
            
            if !x_in_left
                return OrFOL(body.left, Forall(f.var, body.right))
            elseif !x_in_right
                return OrFOL(Forall(f.var, body.left), body.right)
            else
                return Forall(f.var, body)
            end
        else
            return Forall(f.var, body)
        end
    elseif f isa Exists
        body = miniscope(f.body)
        if body isa OrFOL
            # ∃x.(P ∨ Q) → (∃x.P) ∨ (∃x.Q) o P ∨ (∃x.Q) si x no en P
            x_in_left = f.var in free_vars(body.left)
            x_in_right = f.var in free_vars(body.right)
            
            if x_in_left && x_in_right
                return OrFOL(Exists(f.var, body.left), Exists(f.var, body.right))
            elseif x_in_left
                return OrFOL(Exists(f.var, body.left), body.right)
            elseif x_in_right
                return OrFOL(body.left, Exists(f.var, body.right))
            else
                return body  # x no aparece, eliminar cuantificador
            end
        elseif body isa AndFOL
            # ∃x.(P ∧ Q): si x solo en una rama, mover cuantificador a esa rama
            x_in_left = f.var in free_vars(body.left)
            x_in_right = f.var in free_vars(body.right)
            
            if !x_in_left
                return AndFOL(body.left, Exists(f.var, body.right))
            elseif !x_in_right
                return AndFOL(Exists(f.var, body.left), body.right)
            else
                return Exists(f.var, body)
            end
        else
            return Exists(f.var, body)
        end
    elseif f isa AndFOL
        return AndFOL(miniscope(f.left), miniscope(f.right))
    elseif f isa OrFOL
        return OrFOL(miniscope(f.left), miniscope(f.right))
    elseif f isa NotFOL
        return NotFOL(miniscope(f.operand))
    else
        return f
    end
end

"""
    drop_vacuous_quantifiers(f::FOLFormula) -> FOLFormula

Elimina cuantificadores vacuos (cuyas variables no aparecen libres en el cuerpo).

Un cuantificador `∀x.P` o `∃x.P` es vacuo si x no aparece libre en P.
Estos cuantificadores no tienen efecto semántico y pueden eliminarse.

# Ejemplo
```julia
x, y = vars("x", "y")
P = predicate("P")
a = const_FOL("a")

# ∀x.P(a) → P(a)  (x no aparece)
f = ∀(x, P(a))
drop_vacuous_quantifiers(f)  # P(a)

# ∀x.∃y.P(a) → P(a)  (ni x ni y aparecen)
f2 = ∀(x, ∃(y, P(a)))
drop_vacuous_quantifiers(f2)  # P(a)
```
"""
function drop_vacuous_quantifiers(f::FOLFormula)
    if f isa Forall
        body = drop_vacuous_quantifiers(f.body)
        if f.var in free_vars(body)
            return Forall(f.var, body)
        else
            return body  # Cuantificador vacuo, eliminar
        end
    elseif f isa Exists
        body = drop_vacuous_quantifiers(f.body)
        if f.var in free_vars(body)
            return Exists(f.var, body)
        else
            return body  # Cuantificador vacuo, eliminar
        end
    elseif f isa AndFOL
        return AndFOL(drop_vacuous_quantifiers(f.left), drop_vacuous_quantifiers(f.right))
    elseif f isa OrFOL
        return OrFOL(drop_vacuous_quantifiers(f.left), drop_vacuous_quantifiers(f.right))
    elseif f isa NotFOL
        return NotFOL(drop_vacuous_quantifiers(f.operand))
    elseif f isa ImpliesFOL
        return ImpliesFOL(drop_vacuous_quantifiers(f.left), drop_vacuous_quantifiers(f.right))
    elseif f isa IffFOL
        return IffFOL(drop_vacuous_quantifiers(f.left), drop_vacuous_quantifiers(f.right))
    else
        return f
    end
end

# ──────────────────────────────────────────────────────────────────────────
# 5.3 Forma de Skolem
# ──────────────────────────────────────────────────────────────────────────

# Los contadores globales (SKOLEM_COUNTER, TS_CONSTANT_COUNTER)
# ahora están en state.jl como parte de STATE

# Contador local para números de fórmulas dentro de cada nodo del tableau
# Este contador NO es global, se pasa entre nodos padre-hijo
# Se define como referencia local dentro de TS_FOL

"""
    skolemize(f::FOLFormula; universal_vars::Vector{String} = String[])::FOLFormula

Convierte una fórmula lógica a **forma de Skolem** eliminando cuantificadores existenciales.

La **Skolemización** es una técnica de transformación que reemplaza cada variable existencial
con una **función de Skolem**, permitiendo eliminar los cuantificadores existenciales (∃).
El resultado es lógicamente equisatisfacible (satisfacible si y solo si el original es satisfacible),
aunque no lógicamente equivalente.

# Concepto: Funciones de Skolem

En lugar de decir "existe un x que satisface P(x)", creamos una **función testigo** `sk(...)` 
que produce un valor específico para cada combinación de variables universales externas.

Ejemplo:
- **Original**: ∀x. ∃y. P(x, y)
  - "Para cada x, existe un y tal que P(x, y)"
  
- **Skolemizado**: ∀x. P(x, sk₁(x))
  - "Para cada x, P se cumple para x y sk₁(x), donde sk₁ es una función que produce el y apropiado"

# Parámetros
- `f::FOLFormula`: La fórmula lógica a skolemizar
- `universal_vars::Vector{String}`: Variables universales activas en el contexto actual
  (Se mantiene automáticamente durante la recursión)

# Devoluciones
- `FOLFormula`: Fórmula sin cuantificadores existenciales, con funciones de Skolem

# Ejemplos

## Ejemplo 1: Constante de Skolem (sin variables universales previas)
```julia
# ∃x. P(x)  →  P(sk1)
formula = ∃(x, P(x))
skolemize(formula)
# Resultado: P(sk1)
```

## Ejemplo 2: Función de Skolem con variable universal
```julia
# ∀x. ∃y. P(x, y)  →  ∀x. P(x, sk2(x))
formula = ∀(x, ∃(y, P(x, y)))
skolemize(formula)
# Resultado: ∀x. P(x, sk2(x))
# La función de Skolem sk2 depende de x (la variable universal anterior)
```

## Ejemplo 3: Múltiples cuantificadores anidados
```julia
# ∀x. ∀y. ∃z. P(x, y, z)  →  ∀x. ∀y. P(x, y, sk₃(x, y))
formula = ∀(x, ∀(y, ∃(z, P(x, y, z))))
skolemize(formula)
# Resultado: ∀x. ∀y. P(x, y, sk4(x, y))
# sk4 depende de AMBAS variables universales previas
```

## Ejemplo 4: Existencial sin variables universales previas
```julia
# ∃x. ∃y. Q(x, y)  →  Q(sk₅, sk₆)
formula = ∃(x, ∃(y, Q(x, y)))
skolemize(formula)
# Resultado: Q(sk5, sk6)
# Cada existencial sin contexto universal se reemplaza por una constante de Skolem
```

## Ejemplo 5: Mezcla de conectivas
```julia
# (∀x. P(x)) ∨ (∃y. Q(y))  →  (∀x. P(x)) ∨ Q(sk7)
formula = (∀(x, P(x)) | (∃(y, Q(y))))
skolemize(formula)
```

# Detalles de Implementación

## Manejo de Cuantificadores
- **∀x**: Añade x a `universal_vars` para los skolems subsecuentes
- **∃y**: Reemplaza y con una función de Skolem que depende de todas las variables en `universal_vars`

## Funciones de Skolem
- **Constante**: Si no hay variables universales previas: `sk()`
- **Función**: Si hay variables universales: `sk(x, y, z, ...)` donde x,y,z son las variables universales

## Contador Global
- Usa un contador global `next_skolem_counter!()` para generar nombres únicos: sk₁, sk₂, sk₃, ...

## Sustitución
- Cada variable existencial se reemplaza usando `substitute_var` con la función de Skolem correspondiente
- Se procesa recursivamente el cuerpo después de la sustitución

## Recursión
- Procesa recursivamente conectivas (∧, ∨, ¬) y cuantificadores
- Mantiene `universal_vars` durante toda la recursión

# Propiedades Importantes

## Equisatisfacibilidad
- La fórmula resultante es **equisatisfacible** con la original
- Si la original tiene un modelo, la skolemizada también lo tiene
- Si la original es insatisfacible, la skolemizada también lo es
- Pero no necesariamente son **lógicamente equivalentes**

## Eliminación de Existenciales
- Todos los cuantificadores existenciales (∃) son eliminados
- Los cuantificadores universales (∀) se mantienen intactos

## Aplicaciones Principales
1. **Prueba de Teoremas Automatizada**: La resolución trabaja mejor sin ∃
2. **Forma de Clausula**: Paso previo antes de convertir a CNF
3. **Satisfacibilidad**: Para verificar satisfacibilidad de fórmulas FOL

# Paso en Transformación a CNF
En el pipeline de simplificación:
1. `remove_imp` → Elimina → y ↔
2. `move_!_in` → Mueve negaciones adentro (NNF)
3. `skolemize` → Elimina ∃ con funciones de Skolem ← **Estás aquí**
4. `to_clauses` → Convierte a forma clausal

# Casos Base
- Predicados simples: se devuelven sin cambios
- Negación: se procesa el operando
- Conectivas: se procesan ambos operandos
- ∀: se añade a contexto y se procesa cuerpo
- ∃: se reemplaza con función de Skolem y se procesa cuerpo
"""
function skolemize(f::FOLFormula; universal_vars::Vector{String} = String[])
    if f isa Forall
        # Añadir variable universal al contexto
        new_vars = [universal_vars; f.var.name]
        return Forall(f.var, skolemize(f.body; universal_vars = new_vars))
    elseif f isa Exists
        # Reemplazar variable existencial con función de Skolem
        # La función de Skolem depende de TODAS las variables universales anteriores
        sk_name = "sk" * string(next_skolem_counter!())
        
        sk_term = if isempty(universal_vars)
            Const_FOL(sk_name)  # Constante de Skolem (sin variables universales previas)
        else
            Func_FOL(sk_name, [Var_FOL(v) for v in universal_vars])  # Función de Skolem con deps
        end
        
        substituted_body = substitute_var(f.body, f.var, sk_term)
        # IMPORTANTE: mantener universal_vars en la recursión para skolems subsecuentes
        return skolemize(substituted_body; universal_vars = universal_vars)
    elseif f isa AndFOL
        return AndFOL(skolemize(f.left; universal_vars = universal_vars), 
                     skolemize(f.right; universal_vars = universal_vars))
    elseif f isa OrFOL
        return OrFOL(skolemize(f.left; universal_vars = universal_vars), 
                    skolemize(f.right; universal_vars = universal_vars))
    elseif f isa NotFOL
        return NotFOL(skolemize(f.operand; universal_vars = universal_vars))
    else
        return f
    end
end

# Función mejorada de sustitución
"""
    substitute_var(f::FOLFormula, var::Var_FOL, replacement::Term)::FOLFormula

Reemplaza todas las ocurrencias **libres** de una variable por un término.

Solo sustituye variables que NO están ligadas por cuantificadores. Las variables ligadas
(dentro de ∀x o ∃x) se mantienen intactas.

# Parámetros
- `f::FOLFormula`: Fórmula donde hacer la sustitución
- `var::Var_FOL`: Variable a buscar y reemplazar
- `replacement::Term`: Término que reemplaza la variable (puede ser constante, variable u función)

# Devoluciones
- `FOLFormula`: Fórmula con variables libres reemplazadas

# Ejemplos
```julia
# P(x, y) → P(a, y)
formula = P(x, y)
substitute_var(formula, x, a)

# ∀x. P(x, y) → ∀x. P(x, a)
# x ligada por ∀ NO se reemplaza, pero y sí
formula = ∀(x, P(x, y))
substitute_var(formula, y, a)

# ∃x. P(x, y) → ∃x. P(x, sk(x))
# Reemplazar y por una función de Skolem
formula = ∃(x, P(x, y))
substitute_var(formula, y, sk(x))
```

# Detalles
- **Recursiva**: Procesa toda la estructura de la fórmula
- **Respeta alcance**: No sustituye variables ligadas por ∀ o ∃
- Usa `substitute_term` internamente para procesar términos
"""
function substitute_var(f::FOLFormula, var::Var_FOL, replacement::Term)
    if f isa Predicate_FOL
        new_args = [substitute_term(arg, var, replacement) for arg in f.args]
        return Predicate_FOL(f.name, new_args)
    elseif f isa NotFOL
        return NotFOL(substitute_var(f.operand, var, replacement))
    elseif f isa AndFOL
        return AndFOL(substitute_var(f.left, var, replacement), 
                     substitute_var(f.right, var, replacement))
    elseif f isa OrFOL
        return OrFOL(substitute_var(f.left, var, replacement), 
                    substitute_var(f.right, var, replacement))
    elseif f isa ImpliesFOL
        return ImpliesFOL(substitute_var(f.left, var, replacement), 
                         substitute_var(f.right, var, replacement))
    elseif f isa IffFOL
        return IffFOL(substitute_var(f.left, var, replacement), 
                     substitute_var(f.right, var, replacement))
    elseif f isa Forall
        if f.var == var
            return f  # Variable ligada, no sustituir
        else
            return Forall(f.var, substitute_var(f.body, var, replacement))
        end
    elseif f isa Exists
        if f.var == var
            return f  # Variable ligada, no sustituir
        else
            return Exists(f.var, substitute_var(f.body, var, replacement))
        end
    else
        return f
    end
end

function substitute_term(term::Term, var::Var_FOL, replacement::Term)
    if term isa Var_FOL && term == var
        return replacement
    elseif term isa Func_FOL
        new_args = [substitute_term(arg, var, replacement) for arg in term.args]
        return Func_FOL(term.name, new_args)
    else
        return term
    end
end

"""
    to_Sk_optimal(f::FOLFormula) -> FOLFormula

Convierte una fórmula a forma de Skolem (forma prenex con cuantificadores existenciales eliminados),
seleccionando previamente la forma prenex que minimiza la complejidad de Skolemización.

Algoritmo:
1. Generar todas las formas prenex válidas
2. Calcular la aridad de Skolem para cada una
3. Seleccionar la forma con menor aridad
4. Aplicar Skolemización a esa forma

Esto garantiza que:
- Las funciones de Skolem tendrán la mínima aridad posible
- La forma resultante es semánticamente equivalente (insatisfacibilidad preservada)

# Ejemplo
```julia
x, y, z = vars("x", "y", "z")
P, Q = predicates("P", "Q")

# Fórmula con cuantificadores intercambiables
f = ∃(x, ∀(y, P(x,y))) & ∃(z, Q(z))

# Forma prenex óptima: ∃z.∃x.∀y.(P(x,y) ∧ Q(z))   [aridad = 0]
# Forma de Skolem: ∀y.(P(sk1, y) ∧ Q(sk2))        [sk1, sk2 son constantes]

# Sin optimización hubiera sido:
# Forma prenex: ∀y.∃x.∃z.(P(x,y) ∧ Q(z))          [aridad = 1]
# Forma de Skolem: ∀y.(P(sk1(y), y) ∧ Q(sk2(y)))  [sk1, sk2 son funciones unarias]
```
"""
function to_Sk_optimal(f::FOLFormula)::FOLFormula
    # Paso 1: Obtener la forma prenex óptima
    optimal_prenex = to_Px(f)
    
    # Paso 2: Aplicar Skolemización a esa forma
    skolem_form = skolemize(optimal_prenex)
    
    return skolem_form
end


"""
    to_Sk(f::FOLFormula) -> FOLFormula

Convierte una fórmula a forma de Skolem.

Este es el wrapper que orquesta el proceso completo:
1. Resetea el contador de variables Skolem
2. Convierte a forma prenex
3. Aplica skolemización

# Ejemplo
```julia
x, y = vars("x", "y")
P, Q = predicates("P", "Q")

# ∃y.∀x.P(x,y) → ∀x.∃y'.P(x,f_y(x))
formula = ∃(y, ∀(x, P(x, y)))
skolem_form = to_Sk(formula)
```

# Retorna
Una fórmula en forma de Skolem (sin cuantificadores existenciales)
"""
function to_Sk(f::FOLFormula)
    reset_skolem_counter!()
    prenex = to_Px(f)
    return skolemize(prenex)
end

# ──────────────────────────────────────────────────────────────────────────
# 5.4 Forma Normal Conjuntiva (CNF)
# ──────────────────────────────────────────────────────────────────────────

"""
    to_cnf(f::FOLFormula) -> FOLFormula

Convierte una fórmula a Forma Normal Conjuntiva (CNF).

Una fórmula en CNF es una conjunción de disyunciones de literales:
    (L₁₁ ∨ L₁₂ ∨ ...) ∧ (L₂₁ ∨ L₂₂ ∨ ...) ∧ ...

donde cada Lᵢⱼ es un literal (predicado o predicado negado).

# Proceso
1. Elimina implicaciones y bicondicionales (`remove_imp`)
2. Mueve negaciones hacia adentro - NNF (`move_!_in`)
3. Distribuye disyunciones sobre conjunciones (`dist_or_and`)

# Ejemplos
```julia
P, Q, R = predicates("P", "Q", "R")

# Implicación
# P → Q ≡ ¬P ∨ Q (ya en CNF)
f1 = P() > Q()
to_cnf(f1)

# Distributiva
# P ∨ (Q ∧ R) → (P ∨ Q) ∧ (P ∨ R)
f2 = P() | (Q() & R())
to_cnf(f2)

# Compleja
# (P → Q) ∧ R → (¬P ∨ Q) ∧ R
f3 = (P() > Q()) & R()
to_cnf(f3)
```

# Nota
Para fórmulas con cuantificadores, primero aplicar `to_Sk` para skolemizar.
"""
function to_cnf(f::FOLFormula)
    # Primero eliminar implicaciones y mover negaciones
    f = remove_imp(f)
    f = move_!_in(f)
    # Luego distribuir OR sobre AND
    return dist_or_and(f)
end

"""
    dist_or_and(f::FOLFormula) -> FOLFormula

Distribuye disyunciones sobre conjunciones para obtener Forma Normal Conjuntiva (CNF).

Aplica la ley distributiva de forma recursiva:
- `(A ∧ B) ∨ C` → `(A ∨ C) ∧ (B ∨ C)`
- `A ∨ (B ∧ C)` → `(A ∨ B) ∧ (A ∨ C)`

Repite el proceso hasta que todas las disyunciones estén dentro de las conjunciones.

# Precondición
La fórmula debe estar en NNF (Forma Normal de Negación), es decir:
- Sin implicaciones ni bicondicionales
- Todas las negaciones aplicadas solo a predicados

# Ejemplo
```julia
P, Q, R = predicates("P", "Q", "R")

# (P ∨ Q) ∧ R → ya en CNF
f1 = (P() | Q()) & R()
dist_or_and(f1)  # Sin cambios

# P ∨ (Q ∧ R) → (P ∨ Q) ∧ (P ∨ R)
f2 = P() | (Q() & R())
dist_or_and(f2)  # Distribuye

# (P ∧ Q) ∨ (R ∧ S) → (P ∨ R) ∧ (P ∨ S) ∧ (Q ∨ R) ∧ (Q ∨ S)
f3 = (P() & Q()) | (R() & S())
dist_or_and(f3)  # Distribuye ambos lados
```
"""
function dist_or_and(f::FOLFormula)
    if f isa OrFOL
        left = dist_or_and(f.left)
        right = dist_or_and(f.right)
        
        if left isa AndFOL
            # (A ∧ B) ∨ C ≡ (A ∨ C) ∧ (B ∨ C)
            return AndFOL(dist_or_and(OrFOL(left.left, right)),
                         dist_or_and(OrFOL(left.right, right)))
        elseif right isa AndFOL
            # A ∨ (B ∧ C) ≡ (A ∨ B) ∧ (A ∨ C)
            return AndFOL(dist_or_and(OrFOL(left, right.left)),
                         dist_or_and(OrFOL(left, right.right)))
        else
            return OrFOL(left, right)
        end
    elseif f isa AndFOL
        return AndFOL(dist_or_and(f.left), dist_or_and(f.right))
    elseif f isa NotFOL
        return NotFOL(dist_or_and(f.operand))
    else
        return f
    end
end

# ──────────────────────────────────────────────────────────────────────────
# 5.5 Forma Clausal
# ──────────────────────────────────────────────────────────────────────────

# Representación de una cláusula como conjunto de literales
struct Literal
    predicate::Predicate_FOL
    negated::Bool
end

struct Clause
    literals::Set{Literal}
end

# Funciones de igualdad para literales
function Base.:(==)(l1::Literal, l2::Literal)
    l1.predicate == l2.predicate && l1.negated == l2.negated
end

function Base.hash(l::Literal, h::UInt)
    hash((l.predicate, l.negated), h)
end

# Funciones de igualdad para cláusulas
function Base.:(==)(c1::Clause, c2::Clause)
    c1.literals == c2.literals
end

function Base.hash(c::Clause, h::UInt)
    hash(c.literals, h)
end

# Mostrar literales y cláusulas
function Base.show(io::IO, l::Literal)
    if l.negated
        print(io, "¬$(l.predicate)")
    else
        print(io, "$(l.predicate)")
    end
end

function Base.show(io::IO, c::Clause)
    if isempty(c.literals)
        print(io, "□") # Cláusula vacía
    else
        print(io, "{", join(c.literals, ", "), "}")
    end
end

"""
    clauses_of!(f::FOLFormula, clauses::Set{Clause})

Extrae cláusulas de una fórmula en CNF y las añade a un conjunto.

Recorre una fórmula en forma normal conjuntiva (CNF) y extrae cada
conjunto de literales como una cláusula separada.

# Precondición
La fórmula debe estar en CNF (conjunción de disyunciones de literales).

# Parámetros
- `f`: Fórmula en CNF
- `clauses`: Conjunto donde se añadirán las cláusulas (modificado in-place)

# Ejemplo
```julia
P, Q, R = predicates("P", "Q", "R")

# (P ∨ ¬Q) ∧ (R ∨ Q)
f = (P() | !Q()) & (R() | Q())
clauses = Set{Clause}()
clauses_of!(f, clauses)
# clauses = {{P, ¬Q}, {R, Q}}
```
"""
function clauses_of!(f::FOLFormula, clauses::Set{Clause})
    if f isa AndFOL
        clauses_of!(f.left, clauses)
        clauses_of!(f.right, clauses)
    else
        # Es una disyunción o literal, extraer cláusula
        literals = Set{Literal}()
        literals_of!(f, literals)
        push!(clauses, Clause(literals))
    end
end

"""
    literals_of!(f::FOLFormula, literals::Set{Literal})

Extrae literales de una disyunción y los añade a un conjunto.

Recorre una disyunción de literales y extrae cada predicado (negado o no)
como un literal separado.

# Parámetros
- `f`: Disyunción de literales (puede ser un solo literal)
- `literals`: Conjunto donde se añadirán los literales (modificado in-place)

# Ejemplo
```julia
P, Q, R = predicates("P", "Q", "R")

# P ∨ ¬Q ∨ R
f = P() | !Q() | R()
literals = Set{Literal}()
literals_of!(f, literals)
# literals = {Literal(P, false), Literal(Q, true), Literal(R, false)}
```
"""
function literals_of!(f::FOLFormula, literals::Set{Literal})
    if f isa OrFOL
        literals_of!(f.left, literals)
        literals_of!(f.right, literals)
    elseif f isa NotFOL && f.operand isa Predicate_FOL
        push!(literals, Literal(f.operand, true))
    elseif f isa Predicate_FOL
        push!(literals, Literal(f, false))
    else
        error("Forma no válida para extracción de literales: $f")
    end
end

"""
    has_∃(f::FOLFormula) -> Bool

Verifica si una fórmula contiene cuantificadores existenciales (∃).

Recorre recursivamente la fórmula buscando cualquier ocurrencia de `Exists`.
Los cuantificadores universales (∀) no afectan el resultado.

# Uso
Útil para verificar si una fórmula necesita skolemización antes de
convertirla a forma clausal.

# Ejemplos
```julia
x, y = vars("x", "y")
P, Q = predicates("P", "Q")

# ∃x.P(x) → true
has_∃(∃(x, P(x)))  # true

# ∀x.P(x) → false
has_∃(∀(x, P(x)))  # false

# ∀x.∃y.P(x,y) → true
has_∃(∀(x, ∃(y, P(x,y))))  # true

# P(x) → false
has_∃(P(x))  # false
```
"""
function has_∃(f::FOLFormula)
    if f isa Exists
        return true
    elseif f isa Forall
        # Recursivamente verificar el cuerpo, pero no contar el Forall como problemático
        return has_∃(f.body)
    elseif f isa NotFOL
        return has_∃(f.operand)
    elseif f isa AndFOL || f isa OrFOL || f isa ImpliesFOL || f isa IffFOL
        return has_∃(f.left) || has_∃(f.right)
    else
        return false
    end
end

"""
    is_Sk_form(f::FOLFormula) -> Bool

Verifica si una fórmula está en forma de Skolem apropiada.

Una fórmula está en forma de Skolem si:
1. No contiene cuantificadores existenciales (∃)
2. Todos los cuantificadores universales (∀) están al principio (forma prenex)

# Ejemplos
```julia
x, y = vars("x", "y")
P, Q = predicates("P", "Q")
a = const_FOL("a")
f = func("f")

# ∀x.∀y.P(x, f(y)) → true
is_Sk_form(∀(x, ∀(y, P(x, f(y)))))  # true

# ∀x.∃y.P(x, y) → false (tiene ∃)
is_Sk_form(∀(x, ∃(y, P(x, y))))  # false

# P(x) ∧ ∀y.Q(y) → false (∀ no al principio)
is_Sk_form(P(x) & ∀(y, Q(y)))  # false

# ∀x.(P(x) ∧ ∀y.Q(y)) → false (∀ anidado fuera de prenex)
is_Sk_form(∀(x, P(x) & ∀(y, Q(y))))  # false
```
"""
function is_Sk_form(f::FOLFormula)
    # Una fórmula está en forma de Skolem si:
    # 1. No tiene cuantificadores existenciales
    # 2. Todos los cuantificadores universales están al principio (forma prenex)
    return !has_∃(f) && is_prenex_∀(f)
end

"""
    is_prenex_∀(f::FOLFormula) -> Bool

Verifica si todos los cuantificadores universales están en forma prenex.

Una fórmula tiene sus universales en prenex si todos los ∀ están anidados
al principio, sin cuantificadores después de la matriz.

# Ejemplos
```julia
# ∀x.∀y.P(x,y) → true
is_prenex_∀(∀(x, ∀(y, P(x,y))))  # true

# ∀x.(P(x) ∧ ∀y.Q(y)) → false
is_prenex_∀(∀(x, P(x) & ∀(y, Q(y))))  # false
```
"""
function is_prenex_∀(f::FOLFormula)
    if f isa Forall
        return is_prenex_∀(f.body)
    else
        # Una vez que no hay más universales, no debería haber más cuantificadores
        return !has_∀∃(f)
    end
end

"""
    has_∀∃(f::FOLFormula) -> Bool

Verifica si una fórmula contiene algún cuantificador (∀ o ∃).

Busca recursivamente cualquier cuantificador en la fórmula.

# Ejemplos
```julia
# ∀x.P(x) → true
has_∀∃(∀(x, P(x)))  # true

# P(x) ∧ Q(y) → false
has_∀∃(P(x) & Q(y))  # false
```
"""
function has_∀∃(f::FOLFormula)
    if f isa Forall || f isa Exists
        return true
    elseif f isa NotFOL
        return has_∀∃(f.operand)
    elseif f isa AndFOL || f isa OrFOL || f isa ImpliesFOL || f isa IffFOL
        return has_∀∃(f.left) || has_∀∃(f.right)
    else
        return false
    end
end

"""
    to_clauses(f::FOLFormula) -> Set{Clause}

Convierte una fórmula FOL a forma clausal (conjunto de cláusulas).

Una cláusula es un conjunto de literales interpretado como su disyunción.
Un conjunto de cláusulas se interpreta como su conjunción.

# Proceso
1. Verifica que no haya cuantificadores existenciales (usa `to_Sk` si los hay)
2. Elimina el prefijo de cuantificadores universales (son implícitos)
3. Convierte la matriz a CNF
4. Extrae cada disyunción como una cláusula

# Precondición
La fórmula debe estar skolemizada (sin ∃). Los ∀ al principio se eliminan
automáticamente ya que son implícitos en la forma clausal.

# Ejemplos
```julia
x, y = vars("x", "y")
P, Q, R = predicates("P", "Q", "R")

# Fórmula skolemizada
f = ∀(x, ∀(y, (P(x) | Q(y)) & (!P(x) | R(y))))
clauses = to_clauses(f)
# Resultado: {{P(x), Q(y)}, {¬P(x), R(y)}}

# Fórmula sin cuantificadores
f2 = (P(x) | Q(y)) & R(x)
clauses2 = to_clauses(f2)
# Resultado: {{P(x), Q(y)}, {R(x)}}
```

# Error
Lanza error si la fórmula contiene ∃. Usar `to_Sk(f)` primero.
"""
function to_clauses(f::FOLFormula)
    # Verificar si la fórmula tiene cuantificadores existenciales (no debería después de skolemización)
    if has_∃(f)
        error("La fórmula contiene cuantificadores existenciales. Use to_Sk() primero.")
    end
    
    # Si tiene universales al principio, eliminarlos (son implícitos en las cláusulas)
    matrix = remove_∀_prefix(f)
    cnf = to_cnf(matrix)
    clauses = Set{Clause}()
    clauses_of!(cnf, clauses)
    return clauses
end

"""
    remove_∀_prefix(f::FOLFormula) -> FOLFormula

Elimina todos los cuantificadores universales del principio de una fórmula.

En forma clausal, los cuantificadores universales al principio son implícitos,
por lo que pueden eliminarse. Cada variable libre en las cláusulas se interpreta
como universalmente cuantificada.

# Ejemplos
```julia
# ∀x.∀y.P(x,y) → P(x,y)
remove_∀_prefix(∀(x, ∀(y, P(x,y))))  # P(x,y)

# ∀x.(P(x) ∧ Q(x)) → P(x) ∧ Q(x)
remove_∀_prefix(∀(x, P(x) & Q(x)))  # P(x) & Q(x)

# P(x) → P(x) (sin cambios)
remove_∀_prefix(P(x))  # P(x)
```
"""
function remove_∀_prefix(f::FOLFormula)
    if f isa Forall
        return remove_∀_prefix(f.body)
    else
        return f
    end
end

end