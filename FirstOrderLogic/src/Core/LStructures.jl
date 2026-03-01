module LStructures

using ..Types

export LStructure, eval_term, eval_formula, is_model_of, validate
export show_LS
export validate_constants, validate_predicates, validate_functions


# ════════════════════════════════════════════════════════════════════════════
# PARTE 3: L-ESTRUCTURAS
# ════════════════════════════════════════════════════════════════════════════

# ------------------------------------------------------------------------------
# 3.1 L-estructuras
# ------------------------------------------------------------------------------

# Funciones auxiliares de validación

"""
    validate_constants(universe::Set, constants::Dict{String, Any})

Verifica que todas las constantes tengan valores en el universo.

# Lanza
- `ArgumentError`: Si alguna constante no está en el universo

# Ejemplo
```julia
U = Set([1, 2, 3])
consts = Dict("a" => 1, "b" => 2)
validate_constants(U, consts)  # OK

consts_bad = Dict("c" => 5)
validate_constants(U, consts_bad)  # Error: Constante 'c' con valor 5 no pertenece al universo
```
"""
function validate_constants(universe::Set, constants::Dict{String, Any})
    for (const_name, value) in constants
        if value ∉ universe
            throw(ArgumentError(
                "Constante '$const_name' con valor $value no pertenece al universo.\n" *
                "Universo: {" * join(sort(collect(universe), by=string), ", ") * "}"
            ))
        end
    end
end

"""
    validate_predicates(universe::Set, predicates::Dict{String, Set{Tuple}})

Verifica que todas las tuplas en las interpretaciones de predicados estén en el universo.

# Lanza
- `ArgumentError`: Si algún elemento de una tupla no está en el universo

# Ejemplo
```julia
U = Set([1, 2, 3])
preds = Dict("P" => Set([(1,), (2,)]))
validate_predicates(U, preds)  # OK

preds_bad = Dict("Q" => Set([(1, 5)]))
validate_predicates(U, preds_bad)  # Error: Elemento 5 en predicado 'Q' no pertenece al universo
```
"""
function validate_predicates(universe::Set, predicates::Dict{String, Set{Tuple}})
    for (pred_name, tuples) in predicates
        for tup in tuples
            for (idx, elem) in enumerate(tup)
                if elem ∉ universe
                    throw(ArgumentError(
                        "Predicado '$pred_name': elemento $elem en posición $idx de tupla $tup no pertenece al universo.\n" *
                        "Universo: {" * join(sort(collect(universe), by=string), ", ") * "}"
                    ))
                end
            end
        end
    end
end

"""
    validate_functions(universe::Set, functions::Dict{String, Dict{Tuple, Any}})

Verifica que todas las funciones estén bien definidas: argumentos y resultados en el universo.

# Lanza
- `ArgumentError`: Si algún argumento o resultado no está en el universo

# Ejemplo
```julia
U = Set([1, 2, 3])
funcs = Dict("f" => Dict((1,) => 2, (2,) => 3))
validate_functions(U, funcs)  # OK

funcs_bad = Dict("g" => Dict((1,) => 5))
validate_functions(U, funcs_bad)  # Error: Función 'g': resultado 5 para argumentos (1,) no pertenece al universo
```
"""
function validate_functions(universe::Set, functions::Dict{String, Dict{Tuple, Any}})
    for (func_name, mapping) in functions
        for (args, result) in mapping
            # Validar argumentos
            for (idx, arg) in enumerate(args)
                if arg ∉ universe
                    throw(ArgumentError(
                        "Función '$func_name': argumento $arg en posición $idx de $args no pertenece al universo.\n" *
                        "Universo: {" * join(sort(collect(universe), by=string), ", ") * "}"
                    ))
                end
            end
            # Validar resultado
            if result ∉ universe
                throw(ArgumentError(
                    "Función '$func_name': resultado $result para argumentos $args no pertenece al universo.\n" *
                    "Universo: {" * join(sort(collect(universe), by=string), ", ") * "}"
                ))
            end
        end
    end
end

"""]
    LStructure

L-Estructura: Modelo semántico formal para un lenguaje L de primer orden.

Una L-estructura 𝓜 = (D, 𝓘) consiste en:
- **Universo/Dominio D**: Conjunto no vacío de objetos
- **Función de interpretación 𝓘**:
  - Para cada símbolo de constante c: 𝓘(c) ∈ D
  - Para cada símbolo de función f de aridad n: 𝓘(f): Dⁿ → D
  - Para cada símbolo de predicado P de aridad n: 𝓘(P) ⊆ Dⁿ

# Restricciones
El constructor valida que:
1. El universo sea **no vacío**
2. Todas las constantes estén en el universo
3. Todos los elementos en tuplas de predicados estén en el universo
4. Todos los argumentos y resultados de funciones estén en el universo

Si alguna restricción se viola, se lanza `ArgumentError` con mensaje descriptivo.

# Campos
- `universe::Set{Any}`: Conjunto no vacío de objetos del dominio
- `predicate_interp::Dict{String, Set{Tuple}}`: Interpretación de predicados
  - Clave: nombre del predicado
  - Valor: conjunto de tuplas que satisfacen el predicado
- `function_interp::Dict{String, Dict{Tuple, Any}}`: Interpretación de funciones
  - Clave: nombre de la función
  - Valor: diccionario que mapea tuplas de argumentos a resultados
- `constant_interp::Dict{String, Any}`: Interpretación de constantes
  - Clave: nombre de la constante
  - Valor: elemento del universo

# Ejemplos
```julia
# Crear estructura con universo {1, 2, 3}
universe = Set([1, 2, 3])

# P(1), P(2) son verdaderos; Q(1,2) es verdadero
predicates = Dict(
    "P" => Set([(1,), (2,)]),
    "Q" => Set([(1, 2)])
)

# f(1) = 2, f(2) = 3
functions = Dict(
    "f" => Dict((1,) => 2, (2,) => 3)
)

# a se interpreta como 1
constants = Dict("a" => 1)

M = LStructure(universe, predicates, functions, constants)

# Verificar fórmulas
x = var("x")
P = predicate("P")
a = Const_FOL("a")

is_model_of(M, P(a))  # true, porque a↦1 y P(1) es verdadero

# Constructor con keywords (más legible)
M2 = LStructure(
    universe = Set([1, 2]),
    predicates = Dict("P" => Set([(1,)])),
    constants = Dict("a" => 1)
)

# Validación automática - esto lanzará error descriptivo
try
    M_bad = LStructure(
        Set([1, 2]),
        Dict("P" => Set([(5,)])),  # 5 no está en universo
        Dict{String, Dict{Tuple, Any}}(),
        Dict{String, Any}()
    )
catch e
    println(e)  # ArgumentError: Predicado 'P': elemento 5 en posición 1...
end
```

# Ver también
- `eval_formula`: Evalúa una fórmula en la estructura
- `is_model_of`: Verifica si la estructura es modelo de fórmulas
- `herbrand_structure`: Constructor simplificado para estructuras de Herbrand
- `validate`: Valida una estructura ya creada
"""
struct LStructure
    universe::Set{Any}
    predicate_interp::Dict{String, Set{Tuple}}
    function_interp::Dict{String, Dict{Tuple, Any}}
    constant_interp::Dict{String, Any}
    
    # Constructor interno con validaciones - acepta varios tipos
    function LStructure(
        universe,
        predicate_interp = Dict{String, Set{Tuple}}(),
        function_interp = Dict{String, Dict{Tuple, Any}}(),
        constant_interp = Dict{String, Any}()
    )
        # Convertir universe a Set{Any}
        universe_any = if isa(universe, Set{Any})
            universe
        else
            Set{Any}(universe)
        end
        
        # Convertir predicate_interp a Dict{String, Set{Tuple}}
        pred_any = if isa(predicate_interp, Dict{String, Set{Tuple}})
            predicate_interp
        else
            Dict{String, Set{Tuple}}(predicate_interp)
        end
        
        # Convertir function_interp a Dict{String, Dict{Tuple, Any}}
        func_any = Dict{String, Dict{Tuple, Any}}()
        for (k, v) in function_interp
            func_any[k] = Dict{Tuple, Any}()
            for (kk, vv) in v
                func_any[k][kk] = vv
            end
        end
        
        # Convertir constant_interp a Dict{String, Any}
        const_any = Dict{String, Any}(constant_interp)
        
        # Validaciones con mensajes de error descriptivos
        
        # 1. Universo no vacío
        if isempty(universe_any)
            throw(ArgumentError(
                "El universo debe ser no vacío.\n" *
                "Proporciona un Set con al menos un elemento, por ejemplo: Set([1, 2, 3])"
            ))
        end
        
        # 2. Validar constantes
        validate_constants(universe_any, const_any)
        
        # 3. Validar predicados
        validate_predicates(universe_any, pred_any)
        
        # 4. Validar funciones
        validate_functions(universe_any, func_any)
        
        return new(universe_any, pred_any, func_any, const_any)
    end
end

"""
    LStructure(; universe::Set, predicates=Dict(), functions=Dict(), constants=Dict())

Constructor con argumentos nombrados (keywords) para mayor claridad.

# Argumentos nombrados
- `universe::Set`: Universo/dominio de la estructura (requerido)
- `predicates::Dict = Dict()`: Interpretación de predicados
- `functions::Dict = Dict()`: Interpretación de funciones
- `constants::Dict = Dict()`: Interpretación de constantes

# Ejemplo
```julia
# Más legible que versión posicional
M = LStructure(
    universe = Set([1, 2, 3]),
    predicates = Dict(
        "P" => Set([(1,), (2,)]),
        "Q" => Set([(1, 2)])
    ),
    functions = Dict(
        "f" => Dict((1,) => 2, (2,) => 3)
    ),
    constants = Dict("a" => 1)
)

# Solo universo y predicados (resto vacíos)
M2 = LStructure(
    universe = Set(["a", "b"]),
    predicates = Dict("P" => Set([("a",)]))
)
```
"""
function LStructure(;
    universe::Set,
    predicates::Dict = Dict{String, Set{Tuple}}(),
    functions::Dict = Dict{String, Dict{Tuple, Any}}(),
    constants::Dict = Dict{String, Any}()
)
    return LStructure(universe, predicates, functions, constants)
end

"""
    show_LStructure(structure::LStructure; io::IO = stdout)

Muestra una LStructure de forma legible y estructurada.

# Argumentos
- `structure::LStructure`: La estructura a mostrar
- `io::IO = stdout`: Canal de salida (por defecto la consola)

# Formato de Salida
Presenta la estructura en bloques organizados:
- **Universo**: Lista de elementos del dominio
- **Predicados**: Cada predicado con sus tuplas verdaderas
- **Funciones**: Cada función con sus mapeos (args → resultado)
- **Constantes**: Cada constante con su interpretación

# Ejemplo
```julia
U = Set(["a", "b", "c"])
P_interp = Dict("P" => Set([("a",), ("b",)]))
R_interp = Dict("R" => Set([("a", "b"), ("b", "c")]))
f_interp = Dict("f" => Dict(("a",) => "b", ("b",) => "c"))
c_interp = Dict("a" => "a", "b" => "b")

ls = LStructure(U, P_interp, f_interp, c_interp)
show_LStructure(ls)

# Salida:
# ═══════════════════════════════════════
# L-ESTRUCTURA
# ═══════════════════════════════════════
# 
# UNIVERSO (3 elementos):
#   {a, b, c}
# 
# PREDICADOS (2):
#   P/1: {(a), (b)}
#   R/2: {(a, b), (b, c)}
# 
# FUNCIONES (1):
#   f/1:
#     (a) ↦ b
#     (b) ↦ c
# 
# CONSTANTES (2):
#   a ↦ a
#   b ↦ b
```

# Ver también
- `LStructure`: Constructor de estructuras
- `print_LS`: Alternativa de impresión más compacta
"""
function show_LS(structure::LStructure; io::IO = stdout)
    println(io, "═" ^ 60)
    println(io, "L-ESTRUCTURA")
    println(io, "═" ^ 60)
    println(io)
    
    # 1. Universo
    println(io, "UNIVERSO ($(length(structure.universe)) elementos):")
    if isempty(structure.universe)
        println(io, "  ∅")
    else
        elements = sort(collect(structure.universe), by=string)
        println(io, "  {", join(elements, ", "), "}")
    end
    println(io)
    
    # 2. Predicados
    if isempty(structure.predicate_interp)
        println(io, "PREDICADOS: ninguno")
    else
        println(io, "PREDICADOS ($(length(structure.predicate_interp))):")
        sorted_preds = sort(collect(structure.predicate_interp), by=first)
        for (pred_name, tuples) in sorted_preds
            if isempty(tuples)
                arity = 0
            else
                arity = length(first(tuples))
            end
            
            print(io, "  $pred_name/$arity: ")
            if isempty(tuples)
                println(io, "∅")
            else
                sorted_tuples = sort(collect(tuples), by=t -> join(t, ","))
                tuple_strs = ["(" * join(t, ", ") * ")" for t in sorted_tuples]
                println(io, "{", join(tuple_strs, ", "), "}")
            end
        end
    end
    println(io)
    
    # 3. Funciones
    if isempty(structure.function_interp)
        println(io, "FUNCIONES: ninguna")
    else
        println(io, "FUNCIONES ($(length(structure.function_interp))):")
        sorted_funcs = sort(collect(structure.function_interp), by=first)
        for (func_name, mapping) in sorted_funcs
            if isempty(mapping)
                arity = 0
            else
                arity = length(first(keys(mapping)))
            end
            
            println(io, "  $func_name/$arity:")
            if isempty(mapping)
                println(io, "    ∅")
            else
                sorted_mappings = sort(collect(mapping), by=p -> join(p[1], ","))
                for (args, result) in sorted_mappings
                    args_str = "(" * join(args, ", ") * ")"
                    println(io, "    $args_str ↦ $result")
                end
            end
        end
    end
    println(io)
    
    # 4. Constantes
    if isempty(structure.constant_interp)
        println(io, "CONSTANTES: ninguna")
    else
        println(io, "CONSTANTES ($(length(structure.constant_interp))):")
        sorted_consts = sort(collect(structure.constant_interp), by=first)
        for (const_name, value) in sorted_consts
            println(io, "  $const_name ↦ $value")
        end
    end
    
    println(io, "═" ^ 60)
end



"""
    eval_term(term::Term, structure::LStructure, assignment::Dict{String, Any}) -> Any

Evalúa un término en una L-estructura bajo una asignación de variables.

# Argumentos
- `term::Term`: Término a evaluar (variable, constante o función)
- `structure::LStructure`: Estructura en la que evaluar
- `assignment::Dict{String, Any}`: Asignación de variables a elementos del universo

# Retorna
Elemento del universo que representa el valor del término

# Comportamiento
- **Variable**: Busca en la asignación
- **Constante**: Busca en `constant_interp`, o usa interpretación de Herbrand (c ↦ c)
- **Función**: Evalúa argumentos recursivamente y aplica la interpretación

# Ejemplo
```julia
M = herbrand_structure(["a", "b"], Dict("P" => [["a"]]))
x = var("x")
a = Const_FOL("a")

# Evaluar constante
eval_term(a, M, Dict())  # "a"

# Evaluar variable
eval_term(x, M, Dict("x" => "b"))  # "b"
```
"""
function eval_term(
    term::Term, 
    structure::LStructure, 
    assignment::Dict{String, Any}
)::Any
    if term isa Var_FOL
        # Variable: buscar en asignación
        @assert haskey(assignment, term.name) "Variable $(term.name) no tiene asignación"
        return assignment[term.name]
        
    elseif term isa Const_FOL
        # Constante: buscar interpretación o usar Herbrand
        if haskey(structure.constant_interp, term.name)
            return structure.constant_interp[term.name]
        else
            # Interpretación de Herbrand: constante se interpreta como sí misma
            const_value = term.name
            @assert const_value ∈ structure.universe "Constante $(term.name) no está en el universo"
            return const_value
        end
        
    elseif term isa Func_FOL
        # Función: evaluar argumentos y aplicar interpretación
        arg_values = [eval_term(arg, structure, assignment) for arg in term.args]
        arg_tuple = tuple(arg_values...)
        
        @assert haskey(structure.function_interp, term.name) "Función $(term.name) sin interpretación"
        @assert haskey(structure.function_interp[term.name], arg_tuple) "Función $(term.name) no definida para $arg_tuple"
            
        return structure.function_interp[term.name][arg_tuple]
    end
    
    error("Tipo de término desconocido: $(typeof(term))")
end

"""
    eval_formula(formula::FOLFormula, structure::LStructure, assignment::Dict{String, Any}=Dict()) -> Bool

Evalúa si una fórmula es verdadera en una L-estructura según la semántica de Tarski.

# Argumentos
- `formula::FOLFormula`: Fórmula a evaluar
- `structure::LStructure`: Estructura en la que evaluar
- `assignment::Dict{String, Any}`: Asignación de variables libres (por defecto vacío)

# Retorna
`true` si 𝓜, s ⊨ φ (la estructura satisface la fórmula bajo la asignación), `false` en caso contrario

# Semántica
- **Predicado P(t₁,...,tₙ)**: Verdadero si (⟦t₁⟧,...,⟦tₙ⟧) ∈ 𝓘(P)
- **¬φ**: Verdadero si φ es falso
- **φ ∧ ψ**: Verdadero si ambos son verdaderos
- **φ ∨ ψ**: Verdadero si al menos uno es verdadero
- **φ → ψ**: Verdadero si φ es falso o ψ es verdadero
- **φ ↔ ψ**: Verdadero si ambos tienen el mismo valor de verdad
- **∀x.φ**: Verdadero si φ es verdadero para todo objeto del universo
- **∃x.φ**: Verdadero si φ es verdadero para algún objeto del universo

# Ejemplo
```julia
M = herbrand_structure(["a", "b"], Dict("P" => [["a"]], "Q" => [["a"], ["b"]]))

x = var("x")
P, Q = predicates("P", "Q")
a = Const_FOL("a")

eval_formula(P(a), M)           # true
eval_formula(∀(x, Q(x)), M)     # true
eval_formula(∀(x, P(x)), M)     # false (P(b) no es verdadero)
eval_formula(∃(x, P(x)), M)     # true
```

# Ver también
- `eval_term`: Evalúa términos
- `is_model_of`: Verifica si es modelo de un conjunto de fórmulas
"""
function eval_formula(
    formula::FOLFormula,
    structure::LStructure,
    assignment::Dict{String, Any} = Dict{String, Any}()
)::Bool
    
    if formula isa Predicate_FOL
        # Evaluar términos del predicado
        arg_values = [eval_term(arg, structure, assignment) for arg in formula.args]
        arg_tuple = tuple(arg_values...)
        
        # Verificar si la tupla está en la interpretación del predicado
        if haskey(structure.predicate_interp, formula.name)
            return arg_tuple ∈ structure.predicate_interp[formula.name]
        else
            # Sin interpretación explícita → falso (mundo cerrado)
            return false
        end
        
    elseif formula isa NotFOL
        return !eval_formula(formula.operand, structure, assignment)
        
    elseif formula isa AndFOL
        return eval_formula(formula.left, structure, assignment) && 
               eval_formula(formula.right, structure, assignment)
               
    elseif formula isa OrFOL
        return eval_formula(formula.left, structure, assignment) || 
               eval_formula(formula.right, structure, assignment)
               
    elseif formula isa ImpliesFOL
        return !eval_formula(formula.left, structure, assignment) || 
               eval_formula(formula.right, structure, assignment)
               
    elseif formula isa IffFOL
        left_val = eval_formula(formula.left, structure, assignment)
        right_val = eval_formula(formula.right, structure, assignment)
        return left_val == right_val
        
    elseif formula isa Forall
        # ∀x.φ es verdadero si φ es verdadero para TODOS los elementos del universo
        for obj in structure.universe
            new_assignment = copy(assignment)
            new_assignment[formula.var.name] = obj
            if !eval_formula(formula.body, structure, new_assignment)
                return false
            end
        end
        return true
        
    elseif formula isa Exists
        # ∃x.φ es verdadero si φ es verdadero para ALGÚN elemento del universo
        for obj in structure.universe
            new_assignment = copy(assignment)
            new_assignment[formula.var.name] = obj
            if eval_formula(formula.body, structure, new_assignment)
                return true
            end
        end
        return false
    end
    
    return false
end

"""
    is_model_of(structure::LStructure, formulas) -> Bool

Verifica si una L-estructura es modelo de una fórmula o conjunto de fórmulas.

Una estructura 𝓜 es modelo de Γ (escrito 𝓜 ⊨ Γ) si y solo si
𝓜 ⊨ φ para toda φ ∈ Γ.

# Argumentos
- `structure::LStructure`: Estructura a verificar
- `formulas`: Fórmula individual o vector de fórmulas

# Retorna
`true` si la estructura satisface todas las fórmulas, `false` en caso contrario

# Ejemplo
```julia
M = herbrand_structure(["a", "b"], Dict("P" => [["a"], ["b"]]))

x = var("x")
P = predicate("P")
a = Const_FOL("a")

# Verificar fórmula individual
is_model_of(M, P(a))           # true
is_model_of(M, ∀(x, P(x)))     # true

# Verificar conjunto de fórmulas
is_model_of(M, [P(a), ∀(x, P(x))])  # true
```

# Ver también
- `eval_formula`: Evaluación de fórmulas individuales
- `to_LS`: Convertir desde FOLModel
"""
function is_model_of(
    structure::LStructure,
    formulas::Vector{FOLFormula}
)::Bool
    for formula in formulas
        if !eval_formula(formula, structure, Dict{String, Any}())
            return false
        end
    end
    return true
end

# Versión para vector genérico (acepta Vector{Exists}, Vector{Forall}, etc.)
function is_model_of(
    structure::LStructure,
    formulas::Vector
)::Bool
    for formula in formulas
        if !eval_formula(formula, structure, Dict{String, Any}())
            return false
        end
    end
    return true
end

# Versión para una sola fórmula
function is_model_of(structure::LStructure, formula::FOLFormula)::Bool
    return eval_formula(formula, structure, Dict{String, Any}())
end

"""
    validate(structure::LStructure) -> Bool

Valida que una L-estructura cumpla todas las restricciones semánticas.

Útil para verificar estructuras creadas mediante otros medios (por ejemplo,
conversión desde otros formatos) o para debugging.

# Restricciones verificadas
1. Universo no vacío
2. Todas las constantes en el universo
3. Todos los elementos de tuplas de predicados en el universo
4. Todos los argumentos y resultados de funciones en el universo

# Retorna
`true` si todas las validaciones pasan

# Lanza
`ArgumentError` con mensaje descriptivo si alguna validación falla

# Ejemplo
```julia
# Estructura válida
M = LStructure(
    universe = Set([1, 2]),
    predicates = Dict("P" => Set([(1,)]))
)
validate(M)  # true

# Para debugging: verificar estructura sospechosa
# (normalmente el constructor ya valida)
try
    validate(some_structure)
    println("Estructura válida")
catch e
    println("Estructura inválida: ", e)
end
```

# Ver también
- `LStructure`: Constructor que valida automáticamente
"""
function validate(structure::LStructure)::Bool
    # 1. Universo no vacío
    if isempty(structure.universe)
        throw(ArgumentError(
            "El universo debe ser no vacío.\n" *
            "Proporciona un Set con al menos un elemento."
        ))
    end
    
    # 2. Validar constantes
    validate_constants(structure.universe, structure.constant_interp)
    
    # 3. Validar predicados
    validate_predicates(structure.universe, structure.predicate_interp)
    
    # 4. Validar funciones
    validate_functions(structure.universe, structure.function_interp)
    
    return true
end

end