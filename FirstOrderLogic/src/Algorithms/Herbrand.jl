module Herbrand

using ..Types
using ..LStructures
using ..Tableaux
using ..NormalForms: to_Px, to_Sk, remove_∀_prefix
using ..Unification: apply_substitution, Substitution

# ════════════════════════════════════════════════════════════════════════════
# PARTE 6: EXTENSIÓN DE HERBRAND - Generación del universo de Herbrand
# ════════════════════════════════════════════════════════════════════════════

export HerbrandExtension
export H_Un, H_Ex
export extract_constants, extract_functions, extract_predicates, extract_terms
export show_H_ex
export to_LS, herbrand_structure, print_LS


# ──────────────────────────────────────────────────────────────────────────
# 6.1 Estructura para Herbrand
# ──────────────────────────────────────────────────────────────────────────

"""
Estructura que representa una extensión finita del universo de Herbrand,
limitada a una profundidad específica para evitar infinitud.
"""
struct HerbrandExtension
    constants::Set{Const_FOL}          # Constantes del universo
    functions::Set{Func_FOL}           # Términos complejos (hasta max_depth)
    interpretations::Dict              # Mapeo: predicado → lista de instanciaciones
    ground_formulas::Vector{FOLFormula} # Fórmulas completamente instanciadas (ground)
    max_depth::Int                     # Profundidad máxima de términos
    depth_level::Int                   # Profundidad actualmente generada
end

# ──────────────────────────────────────────────────────────────────────────
# 6.2 Universo de Herbrand
# ──────────────────────────────────────────────────────────────────────────

"""
    H_Un(f::FOLFormula; max_depth::Int = 3) -> Vector{Term}

Genera el universo de Herbrand de una fórmula FOL hasta una profundidad limitada.

El universo de Herbrand contiene:
- Todas las constantes que aparecen en la fórmula (si existen)
- Una constante especial 'a' si no hay constantes
- Todos los términos formados aplicando funciones recursivamente hasta max_depth

# Parámetros
- `f::FOLFormula`: Fórmula FOL
- `max_depth::Int`: Profundidad máxima para generar términos (default: 3)

# Retorna
Vector de términos (el universo de Herbrand limitado)

# Ejemplo
```julia
x = var("x")
P, Q = predicates("P", "Q")
a, b = constants("a", "b")
f = function_("f")

# Fórmula: ∀x. P(x) ∨ Q(f(x))
formula = ∀(x, P(x) | Q(f(x)))

# Generar universo con profundidad 2
universe = H_Un(formula; max_depth=2)
# Resultado: [a, b, f(a), f(b), f(f(a)), f(f(b))]
```

# Notas
La profundidad controla cuán "anidadas" pueden estar las funciones.
Con max_depth=0: solo constantes
Con max_depth=1: constantes + f(constantes)
Con max_depth=2: constantes + f(constantes) + f(f(constantes))
"""
function H_Un(f::FOLFormula; max_depth::Int = 3)::Vector{Term}
    # Extraer constantes y funciones de la fórmula
    constants_found = extract_constants(f)
    functions_found = extract_functions(f)
    
    # Si no hay constantes, añadir la constante especial 'a'
    if isempty(constants_found)
        push!(constants_found, Const_FOL("a"))
    end
    
    # Generar el universo recursivamente
    universe = Set{Term}()
    
    # Añadir todas las constantes
    for c in constants_found
        push!(universe, c)
    end
    
    # Generar términos complejos hasta max_depth
    current_terms = collect(constants_found)
    
    for depth in 1:max_depth
        next_terms = Vector{Term}()
        
        for func in functions_found
            for arg in current_terms
                # Crear término: func(arg)
                new_term = Func_FOL(func.name, [arg])
                push!(universe, new_term)
                push!(next_terms, new_term)
            end
        end
        
        # Para profundidades mayores, también permitir aplicaciones múltiples
        if depth < max_depth && !isempty(next_terms)
            current_terms = vcat(current_terms, next_terms)
        end
    end
    
    return collect(universe)
end

"""
    extract_constants(f::FOLFormula) -> Set{Const_FOL}

Extrae todas las constantes que aparecen en una fórmula FOL.
"""
function extract_constants(f::FOLFormula)::Set{Const_FOL}
    constants = Set{Const_FOL}()
    
    function traverse(formula::FOLFormula)
        if formula isa Predicate_FOL
            for arg in formula.args
                traverse_term(arg)
            end
        elseif formula isa NotFOL
            traverse(formula.operand)
        elseif formula isa AndFOL || formula isa OrFOL || 
               formula isa ImpliesFOL || formula isa IffFOL
            traverse(formula.left)
            traverse(formula.right)
        elseif formula isa Forall || formula isa Exists
            traverse(formula.body)
        end
    end
    
    function traverse_term(term::Term)
        if term isa Const_FOL
            push!(constants, term)
        elseif term isa Func_FOL
            for arg in term.args
                traverse_term(arg)
            end
        end
    end
    
    traverse(f)
    return constants
end

"""
    extract_functions(f::FOLFormula) -> Set{Func_FOL}

Extrae todas las funciones (con aridad) que aparecen en una fórmula FOL.
Devuelve prototipos de funciones con un solo argumento para simplificar.
"""
function extract_functions(f::FOLFormula)::Set{Func_FOL}
    functions = Set{Func_FOL}()
    
    function traverse(formula::FOLFormula)
        if formula isa Predicate_FOL
            for arg in formula.args
                traverse_term(arg)
            end
        elseif formula isa NotFOL
            traverse(formula.operand)
        elseif formula isa AndFOL || formula isa OrFOL || 
               formula isa ImpliesFOL || formula isa IffFOL
            traverse(formula.left)
            traverse(formula.right)
        elseif formula isa Forall || formula isa Exists
            traverse(formula.body)
        end
    end
    
    function traverse_term(term::Term)
        if term isa Func_FOL
            # Guardar función (usaremos solo su nombre para generalizaciones)
            push!(functions, Func_FOL(term.name, [Var_FOL("_")]))  # Placeholder
            
            # Continuar con argumentos
            for arg in term.args
                traverse_term(arg)
            end
        end
    end
    
    traverse(f)
    return functions
end

# ──────────────────────────────────────────────────────────────────────────
# 6.3 Extensión de Herbrand
# ──────────────────────────────────────────────────────────────────────────

"""
    H_Ex(f::FOLFormula; max_depth::Int = 3) -> HerbrandExtension

Genera todas las posibles instanciaciones de predicados sobre el universo de Herbrand.

# Parámetros
- `f::FOLFormula`: Fórmula FOL en forma prenex
- `max_depth::Int`: Profundidad máxima del universo de Herbrand

# Retorna
Estructura `HerbrandExtension` con el universo y todas las instanciaciones

# Ejemplo
```julia
x, y = vars("x", "y")
P, Q = predicates("P", "Q")
a, b = constants("a", "b")

# Fórmula: ∀x. ∀y. P(x, y) ∨ Q(x)
formula = ∀(x, ∀(y, P(x, y) | Q(x)))

# Generar interpretaciones Herbrand
herbrand = H_Ex(formula; max_depth=2)

println("Universo: ", herbrand.constants)
println("Predicados generados: ", herbrand.interpretations)
```
"""
function H_Ex(f::FOLFormula; max_depth::Int = 3)::HerbrandExtension
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Aplicar Prenex → Skolem → Eliminar universales ANTES de ground
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    # PASO 1: Convertir a forma Prenex
    f_prenex = to_Px(f)
    
    # PASO 2: Aplicar Skolemización para eliminar existenciales
    f_skolem = to_Sk(f_prenex)
    
    # PASO 3: Eliminar cuantificadores universales (obtener fórmula abierta)
    f_abierta = remove_∀_prefix(f_skolem)
    
    # Ahora trabajar con la fórmula abierta
    formula_para_herbrand = f_abierta
    
    # Generar universo de Herbrand
    universe = H_Un(formula_para_herbrand; max_depth = max_depth)
    constants = Set{Const_FOL}([t for t in universe if t isa Const_FOL])
    functions = Set{Func_FOL}([t for t in universe if t isa Func_FOL])
    
    # Extraer predicados de la fórmula ABIERTA (después de Skolem)
    predicates_found = extract_predicates(formula_para_herbrand)
    
    # Generar todas las instanciaciones
    interpretations = Dict()
    
    for pred in predicates_found
        pred_name = pred.name
        pred_arity = length(pred.args)
        
        # Generar todas las posibles combinaciones de argumentos del universo
        if pred_arity > 0
            # Cartesian product: universe^arity
            arg_combinations = CartesianIndices(ntuple(_ -> 1:length(universe), pred_arity))
            instances = Vector{Predicate_FOL}()
            
            for combo in arg_combinations
                args = [universe[combo[i]] for i in 1:pred_arity]
                push!(instances, Predicate_FOL(pred_name, args))
            end
            
            interpretations[pred_name] = instances
        else
            # Predicado sin argumentos
            interpretations[pred_name] = [Predicate_FOL(pred_name, Term[])]
        end
    end
    
    # Generar fórmulas ground DESDE LA FÓRMULA ABIERTA (sin cuantificadores)
    all_ground = Vector{FOLFormula}()
    if isa(formula_para_herbrand, FOLFormula)
        ground = generate_ground_formulas(formula_para_herbrand, universe)
        append!(all_ground, ground)
    end
    
    return HerbrandExtension(constants, functions, interpretations, all_ground, max_depth, max_depth)
end

"""
    extract_predicates(f::FOLFormula) -> Set{Predicate_FOL}

Extrae todos los predicados (con aridad) que aparecen en una fórmula FOL.
"""
function extract_predicates(f::FOLFormula)::Set{Predicate_FOL}
    predicates = Set{Predicate_FOL}()
    
    function traverse(formula::FOLFormula)
        if formula isa Predicate_FOL
            # Guardar solo el predicado con su aridad, sin instancias específicas
            push!(predicates, Predicate_FOL(formula.name, fill(Var_FOL("_"), length(formula.args))))
        elseif formula isa NotFOL
            traverse(formula.operand)
        elseif formula isa AndFOL || formula isa OrFOL || 
               formula isa ImpliesFOL || formula isa IffFOL
            traverse(formula.left)
            traverse(formula.right)
        elseif formula isa Forall || formula isa Exists
            traverse(formula.body)
        end
    end
    
    traverse(f)
    return predicates
end

# ──────────────────────────────────────────────────────────────────────────
# 6.4 Instanciación de fórmulas (ground formulas)
# ──────────────────────────────────────────────────────────────────────────

"""
    extract_free_variables(formula::FOLFormula)::Set{Var_FOL}

Extrae todas las variables LIBRES (no ligadas por cuantificadores) de una fórmula.

Variables ligadas son aquellas dentro del alcance de ∀ o ∃.
Variables libres son las que no están ligadas.

# Ejemplo
```julia
x = var("x")
y = var("y")

# En ∀x.P(x,y), solo y es libre (x es ligada)
formula = ∀(x, P(x, y))
free_vars = extract_free_variables(formula)
# free_vars = {y}
```
"""
function extract_free_variables(formula::FOLFormula, bound_vars::Set{Var_FOL} = Set{Var_FOL}())::Set{Var_FOL}
    free = Set{Var_FOL}()
    
    if formula isa Predicate_FOL
        # Extraer variables de los argumentos que no están ligadas
        for arg in formula.args
            if arg isa Var_FOL && arg ∉ bound_vars
                push!(free, arg)
            elseif arg isa Func_FOL
                # Extraer variables de argumentos de función
                for func_arg in arg.args
                    if func_arg isa Var_FOL && func_arg ∉ bound_vars
                        push!(free, func_arg)
                    end
                end
            end
        end
    
    elseif formula isa NotFOL
        union!(free, extract_free_variables(formula.operand, bound_vars))
    
    elseif formula isa AndFOL
        union!(free, extract_free_variables(formula.left, bound_vars))
        union!(free, extract_free_variables(formula.right, bound_vars))
    
    elseif formula isa OrFOL
        union!(free, extract_free_variables(formula.left, bound_vars))
        union!(free, extract_free_variables(formula.right, bound_vars))
    
    elseif formula isa ImpliesFOL
        union!(free, extract_free_variables(formula.left, bound_vars))
        union!(free, extract_free_variables(formula.right, bound_vars))
    
    elseif formula isa IffFOL
        union!(free, extract_free_variables(formula.left, bound_vars))
        union!(free, extract_free_variables(formula.right, bound_vars))
    
    elseif formula isa Forall
        # Agregar variable a bound_vars
        new_bound = copy(bound_vars)
        push!(new_bound, formula.var)
        union!(free, extract_free_variables(formula.body, new_bound))
    
    elseif formula isa Exists
        # Agregar variable a bound_vars
        new_bound = copy(bound_vars)
        push!(new_bound, formula.var)
        union!(free, extract_free_variables(formula.body, new_bound))
    end
    
    return free
end

"""
    generate_ground_formulas(formula::FOLFormula, universe::Vector{Term})::Vector{FOLFormula}

Genera todas las fórmulas ground (completamente instanciadas) de una fórmula.

Una fórmula ground es una donde todas las variables libres han sido reemplazadas 
por términos del universo de Herbrand.
"""
function generate_ground_formulas(formula::FOLFormula, universe::Vector{Term})::Vector{FOLFormula}
    ground = Vector{FOLFormula}()
    
    # Extraer todas las variables libres
    variables = extract_free_variables(formula)
    
    if isempty(variables)
        # Si no hay variables, la fórmula ya es ground
        push!(ground, formula)
        return ground
    end
    
    var_list = collect(variables)
    n_vars = length(var_list)
    
    # Generar todas las combinaciones (Cartesian product)
    if n_vars > 0
        # CartesianIndices: para cada variable, elegir un término del universo
        indices = CartesianIndices(ntuple(_ -> 1:length(universe), n_vars))
        
        for idx_combo in indices
            # Crear substitución: variable -> término
            substitution = Dict{Var_FOL, Term}()
            for i in 1:n_vars
                substitution[var_list[i]] = universe[idx_combo[i]]
            end
            
            # Aplicar substitución a la fórmula (convertir a nuevo sistema)
            ground_formula = apply_substitution(formula, Substitution(substitution))
            push!(ground, ground_formula)
        end
    end
    
    return ground
end

# ──────────────────────────────────────────────────────────────────────────
# 6.5 Representación
# ──────────────────────────────────────────────────────────────────────────

"""
    show_H_ex(herbrand::HerbrandExtension; max_show::Int = 100)

Muestra de forma legible la extensión de Herbrand generada.
"""
function show_H_ex(herbrand::HerbrandExtension; max_show::Int = 100)
    println("\n" * "="^80)
    println("EXTENSIÓN DE HERBRAND (Profundidad máxima: $(herbrand.max_depth))")
    println("="^80)
    
    println("\n📚 UNIVERSO DE HERBRAND:")
    print("   { ")
    
    universe_list = collect(herbrand.constants) ∪ collect(herbrand.functions)
    if length(universe_list) > max_show
        print(join(string.(universe_list[1:max_show]), ", "))
        println(", ... [", length(universe_list) - max_show, " más] }")
    else
        println(join(string.(universe_list), ", "), " }")
    end
    
    println("\n📊 INSTANCIACIONES DE PREDICADOS:")
    for (pred_name, instances) in pairs(herbrand.interpretations)
        println("\n   $pred_name:")
        if length(instances) > max_show
            for i in 1:min(max_show, length(instances))
                println("      • $(instances[i])")
            end
            println("      ... [$(length(instances) - max_show) más instancias]")
        else
            for instance in instances
                println("      • $instance")
            end
        end
    end
    
    println("\n🔍 FÓRMULAS GROUND (Instanciadas completamente):")
    if length(herbrand.ground_formulas) > 0
        if length(herbrand.ground_formulas) > max_show
            for i in 1:min(max_show, length(herbrand.ground_formulas))
                println("   $(i). $(herbrand.ground_formulas[i])")
            end
            println("   ... [$(length(herbrand.ground_formulas) - max_show) más fórmulas]")
        else
            for (i, formula) in enumerate(herbrand.ground_formulas)
                println("   $(i). $formula")
            end
        end
    else
        println("   (No hay fórmulas con variables)")
    end
    
    println("\n" * "="^80)
end

# ──────────────────────────────────────────────────────────────────────────
# 6.6 Versiones para conjuntos y vectores de fórmulas
# ──────────────────────────────────────────────────────────────────────────

"""
    H_Un(formulas::Set{FOLFormula}; max_depth::Int = 3) -> Vector{Term}

Genera el universo de Herbrand a partir de un CONJUNTO de fórmulas.
Esta es la versión más apropiada para argumentación formal.

En argumentación, tenemos una base de conocimiento (KB) representada como un
conjunto de fórmulas. Esta función genera el universo de Herbrand considerando
TODAS las constantes y funciones que aparecen en ANY fórmula del conjunto.

# Parámetros
- `formulas::Set{FOLFormula}`: Conjunto de fórmulas (la base de conocimiento)
- `max_depth::Int`: Profundidad máxima para generar términos (default: 3)

# Retorna
Vector de términos (el universo de Herbrand limitado combinado)

# Ejemplo - Argumentación
```julia
x = var("x")
P, Q = predicates("P", "Q")
a, b = constants("a", "b")
f = function_("f")

# Base de conocimiento
premises = Set([
    ∀(x, P(x) → Q(x)),  # Si P entonces Q
    P(a),               # a tiene propiedad P
    P(b)                # b tiene propiedad P
])

# Generar universo que considere TODAS las premisas
universe = H_Un(premises; max_depth=2)
# Universo combina: {a, b, f(a), f(b), ...}

# Luego verificar si la conclusión es consecuencia lógica
```

# Notas
- Se recomienda usar `Set` en lugar de `Vector` para argumentación
- Los duplicados se eliminan automáticamente
- El orden no importa (semánticamente correcto)
- Más eficiente en memoria que usar múltiples conjuntos
"""
function H_Un(formulas::Set{T}; max_depth::Int = 3)::Vector{Term} where T <: FOLFormula
    # Combinar constantes y funciones de TODAS las fórmulas
    all_constants = Set{Const_FOL}()
    all_functions = Set{Func_FOL}()
    
    for formula in formulas
        union!(all_constants, extract_constants(formula))
        union!(all_functions, extract_functions(formula))
    end
    
    # Si no hay constantes, añadir la constante especial 'a'
    if isempty(all_constants)
        push!(all_constants, Const_FOL("a"))
    end
    
    # Generar el universo recursivamente (mismo algoritmo que para una fórmula)
    universe = Set{Term}()
    
    # Añadir todas las constantes
    for c in all_constants
        push!(universe, c)
    end
    
    # Generar términos complejos hasta max_depth
    current_terms = collect(all_constants)
    
    for depth in 1:max_depth
        next_terms = Vector{Term}()
        
        for func in all_functions
            for arg in current_terms
                new_term = Func_FOL(func.name, [arg])
                push!(universe, new_term)
                push!(next_terms, new_term)
            end
        end
        
        if depth < max_depth && !isempty(next_terms)
            current_terms = vcat(current_terms, next_terms)
        end
    end
    
    return collect(universe)
end

"""
    H_Un(formulas::Vector{FOLFormula}; max_depth::Int = 3) -> Vector{Term}

Versión sobrecargada que acepta un VECTOR de fórmulas.
Convierte el vector a conjunto y delega a la versión para Sets.

# Uso
```julia
premises = [∀(x, P(x) → Q(x)), P(a), P(b)]
universe = H_Un(premises; max_depth=2)
```

# Notas
- Los duplicados en el vector se eliminan automáticamente
- Se recomienda usar Sets directamente si es posible
"""
function H_Un(formulas::Vector{T}; max_depth::Int = 3)::Vector{Term} where T <: FOLFormula
    return H_Un(Set(formulas); max_depth = max_depth)
end

"""
    H_Ex(formulas::Set{FOLFormula}; max_depth::Int = 3) -> HerbrandExtension

Genera interpretaciones de Herbrand para un CONJUNTO de fórmulas (base de conocimiento).

Esta es la versión correcta para argumentación formal, donde se tiene:
- Un conjunto de premisas (base de conocimiento)
- Una conclusión que se quiere verificar
- Necesidad de generar modelo único sobre el universo combinado

# Parámetros
- `formulas::Set{FOLFormula}`: Conjunto de fórmulas
- `max_depth::Int`: Profundidad máxima del universo (default: 3)

# Retorna
`HerbrandExtension` con el universo combinado e interpretaciones

# Ejemplo - Verificación de Argumentos
```julia
KB = Set([
    ∀(x, Empleado(x) → MortajoDesde(x, empresa)),
    Empleado("Juan"),
    Empleado("María")
])

conclusion = MortajoDesde("Juan", "empresa")

# Generar interpretaciones de la KB
herbrand = H_Ex(KB; max_depth=2)

# Verificar si conclusión es satisfecha en TODAS las interpretaciones
# (si es válido el argumento)
```
"""
function H_Ex(formulas::Set{T}; max_depth::Int = 3)::HerbrandExtension where T <: FOLFormula
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Aplicar Prenex → Skolem → Eliminar universales ANTES de ground
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    # PASO 1-3: Procesar cada fórmula: Prenex → Skolem → Eliminar ∀
    formulas_abiertas = Set{FOLFormula}()
    
    for f in formulas
        # PASO 1: Prenex
        f_prenex = to_Px(f)
        # PASO 2: Skolem
        f_skolem = to_Sk(f_prenex)
        # PASO 3: Eliminar universales
        f_abierta = remove_∀_prefix(f_skolem)
        push!(formulas_abiertas, f_abierta)
    end
    
    # Generar universo combinado (desde fórmulas abiertas)
    universe = H_Un(formulas_abiertas; max_depth = max_depth)
    constants = Set{Const_FOL}([t for t in universe if t isa Const_FOL])
    functions = Set{Func_FOL}([t for t in universe if t isa Func_FOL])
    
    # Extraer predicados de TODAS las fórmulas ABIERTAS
    all_predicates = Set{Predicate_FOL}()
    for formula in formulas_abiertas
        union!(all_predicates, extract_predicates(formula))
    end
    
    # Generar todas las instanciaciones
    interpretations = Dict()
    
    for pred in all_predicates
        pred_name = pred.name
        pred_arity = length(pred.args)
        
        if pred_arity > 0
            arg_combinations = CartesianIndices(ntuple(_ -> 1:length(universe), pred_arity))
            instances = Vector{Predicate_FOL}()
            
            for combo in arg_combinations
                args = [universe[combo[i]] for i in 1:pred_arity]
                push!(instances, Predicate_FOL(pred_name, args))
            end
            
            interpretations[pred_name] = instances
        else
            interpretations[pred_name] = [Predicate_FOL(pred_name, Term[])]
        end
    end
    
    # Generar fórmulas ground DESDE LAS FÓRMULAS ABIERTAS (sin cuantificadores)
    all_ground = Vector{FOLFormula}()
    for formula in formulas_abiertas
        ground = generate_ground_formulas(formula, universe)
        append!(all_ground, ground)
    end
    
    return HerbrandExtension(constants, functions, interpretations, all_ground, max_depth, max_depth)
end

"""
    H_Ex(formulas::Vector{FOLFormula}; max_depth::Int = 3) -> HerbrandExtension

Versión sobrecargada que acepta un VECTOR de fórmulas.
Convierte el vector a conjunto y delega.

# Uso
```julia
premises = [∀(x, P(x) → Q(x)), P(a)]
herbrand = H_Ex(premises; max_depth=2)
```
"""
function H_Ex(formulas::Vector{T}; max_depth::Int = 3)::HerbrandExtension where T <: FOLFormula
    return H_Ex(Set(formulas); max_depth = max_depth)
end

# ------------------------------------------------------------------------------
# 6.7 L-estructuras y Extensiones de Herbrand
# ------------------------------------------------------------------------------

"""
    to_LS(model::FOLModel) -> LStructure

Convierte un FOLModel (extraído de un tablero) en una LStructure formal.

# Interpretación
- **Universo**: Elementos del dominio del FOLModel (como strings)
- **Predicados verdaderos**: Según `true_atoms`
- **Predicados falsos**: Ignorados (mundo cerrado: lo no especificado es falso)
- **Constantes**: Interpretación de Herbrand (c ↦ "c")
- **Funciones**: Extraídas de términos funcionales en átomos

# Argumentos
- `model::FOLModel`: Modelo extraído del tablero

# Retorna
LStructure equivalente con representación de strings

# Ejemplo
```julia
P, Q = predicates("P", "Q")
a, b = consts("a", "b")

f = P(a) & Q(b)
fol_model = TS_get_model(f)
l_struct = to_LS(fol_model)

# Verificar que mantiene las mismas propiedades
is_model_of(l_struct, f)  # true
```

# Ver también
- `FOLModel`: Estructura de modelos del tablero
- `herbrand_structure`: Constructor directo de estructuras
"""
function to_LS(model::FOLModel)::LStructure
    # Universo: usar representación de strings de los términos
    universe = Set{String}()
    for term in model.domain
        push!(universe, string(term))
    end
    
    # Si el dominio está vacío (caso edge), crear testigo
    if isempty(universe)
        push!(universe, "c_witness")
    end
    
    # Construir interpretación de predicados
    predicate_interp = Dict{String, Set{Tuple}}()
    
    for atom in model.true_atoms
        if atom isa Predicate_FOL
            pred_name = atom.name
            # Convertir términos a strings
            arg_tuple = tuple([string(t) for t in atom.args]...)
            
            if !haskey(predicate_interp, pred_name)
                predicate_interp[pred_name] = Set{Tuple}()
            end
            push!(predicate_interp[pred_name], arg_tuple)
        end
    end
    
    # Constantes: mapeo identidad (interpretación de Herbrand)
    constant_interp = Dict{String, String}()
    for term in model.domain
        if term isa Const_FOL
            constant_interp[term.name] = term.name
        end
    end
    
    # Funciones: inicialmente vacío (puede extenderse si hay términos funcionales)
    function_interp = Dict{String, Dict{Tuple, String}}()
    
    # Extraer funciones de los átomos verdaderos
    for atom in model.true_atoms
        if atom isa Predicate_FOL
            for term in atom.args
                if term isa Func_FOL
                    extract_function_interpretation!(function_interp, term, universe)
                end
            end
        end
    end
    
    return LStructure(universe, predicate_interp, function_interp, constant_interp)
end

# Función auxiliar para extraer interpretación de funciones de términos funcionales
function extract_function_interpretation!(
    function_interp::Dict{String, Dict{Tuple, String}},
    term::Func_FOL,
    universe::Set{String}
)
    # Evaluar argumentos (solo constantes por ahora)
    args_str = String[]
    for arg in term.args
        if arg isa Const_FOL
            push!(args_str, arg.name)
        elseif arg isa Func_FOL
            # Recursivo: primero extraer subfunciones
            extract_function_interpretation!(function_interp, arg, universe)
            push!(args_str, string(arg))  # Usar representación completa
        else
            push!(args_str, string(arg))
        end
    end
    
    # Agregar la función al universo y a la interpretación
    func_result = string(term)
    push!(universe, func_result)
    
    if !haskey(function_interp, term.name)
        function_interp[term.name] = Dict{Tuple, String}()
    end
    
    function_interp[term.name][tuple(args_str...)] = func_result
end

"""
    herbrand_structure(constants::Vector{String}, true_predicates::Dict{String, Vector{Vector{String}}}) -> LStructure

Crea una L-estructura simple con interpretación de Herbrand.

Útil para definir estructuras finitas rápidamente donde:
- El universo son los nombres de las constantes
- Las constantes se interpretan como sí mismas (c ↦ c)
- Solo se especifican los predicados verdaderos

# Argumentos
- `constants::Vector{String}`: Lista de nombres de constantes (formarán el universo)
- `true_predicates::Dict{String, Vector{Vector{String}}}`: Predicados verdaderos
  - Clave: nombre del predicado
  - Valor: lista de listas de argumentos que satisfacen el predicado

# Ejemplo
```julia
# Universo {"a", "b", "c"}
# P(a), P(b) verdaderos
# Q(a,b), Q(b,c) verdaderos
M = herbrand_structure(
    ["a", "b", "c"],
    Dict(
        "P" => [["a"], ["b"]],
        "Q" => [["a", "b"], ["b", "c"]]
    )
)

x, y = vars("x", "y")
P, Q = predicates("P", "Q")
a, b, c = consts("a", "b", "c")

is_model_of(M, P(a))              # true
is_model_of(M, P(c))              # false
is_model_of(M, Q(a, b))           # true
is_model_of(M, ∃(x, P(x)))        # true
is_model_of(M, ∀(x, P(x)))        # false
```

# Ver también
- `LStructure`: Constructor completo
- `to_LS`: Conversión desde FOLModel
"""
function herbrand_structure(
    constants::Vector{String},
    true_predicates::Dict{String, Vector{Vector{String}}} = Dict{String, Vector{Vector{String}}}()
)::LStructure
    universe = Set{String}(constants)
    
    # Convertir predicados al formato de LStructure
    predicate_interp = Dict{String, Set{Tuple}}()
    for (pred, tuples_list) in true_predicates
        predicate_interp[pred] = Set(tuple(t...) for t in tuples_list)
    end
    
    # Interpretación de Herbrand para constantes
    constant_interp = Dict{String, String}(c => c for c in constants)
    
    return LStructure(universe, predicate_interp, Dict{String, Dict{Tuple, String}}(), constant_interp)
end

"""
    print_LS(structure::LStructure; io::IO=stdout)

Imprime una L-estructura de forma legible y estructurada.

# Argumentos
- `structure::LStructure`: Estructura a imprimir
- `io::IO`: Stream de salida (por defecto stdout)

# Ejemplo
```julia
M = herbrand_structure(
    ["a", "b"],
    Dict("P" => [["a"]], "Q" => [["a", "b"]])
)
print_LS(M)
```

Salida:
```
═══ L-ESTRUCTURA ═══

Universo: {"a", "b"}

▸ Interpretación de Constantes:
  a ↦ a
  b ↦ b

▸ Interpretación de Predicados:
  P:
    ✓ P(a)
  Q:
    ✓ Q(a, b)

▸ Interpretación de Funciones:
  (ninguna)
═══════════════════
```
"""
function print_LS(structure::LStructure; io::IO=stdout)
    println(io, "═══ L-ESTRUCTURA ═══")
    println(io, "\nUniverso: ", structure.universe)
    
    println(io, "\n▸ Interpretación de Constantes:")
    if isempty(structure.constant_interp)
        println(io, "  (ninguna)")
    else
        for (name, value) in sort(collect(structure.constant_interp))
            println(io, "  $name ↦ $value")
        end
    end
    
    println(io, "\n▸ Interpretación de Predicados:")
    if isempty(structure.predicate_interp)
        println(io, "  (ninguno)")
    else
        for (name, tuples) in sort(collect(structure.predicate_interp); by=first)
            println(io, "  $name:")
            # Convertir tuplas a strings para ordenarlas
            sorted_tuples = sort(collect(tuples); by=x -> string(x))
            for tup in sorted_tuples
                args_str = join(tup, ", ")
                println(io, "    ✓ $(name)($args_str)")
            end
        end
    end
    
    println(io, "\n▸ Interpretación de Funciones:")
    if isempty(structure.function_interp)
        println(io, "  (ninguna)")
    else
        for (name, mapping) in sort(collect(structure.function_interp); by=first)
            println(io, "  $name:")
            # Convertir a strings para ordenar
            sorted_mappings = sort(collect(mapping); by=x -> string(x[1]))
            for (args, result) in sorted_mappings
                args_str = join(args, ", ")
                println(io, "    $(name)($args_str) = $result")
            end
        end
    end
    
    println(io, "═══════════════════")
end

end