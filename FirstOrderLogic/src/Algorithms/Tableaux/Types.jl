# ════════════════════════════════════════════════════════════════════════════
# Tipos y Estructuras para Tableros Semánticos FOL
# ════════════════════════════════════════════════════════════════════════════

"""
    TSNodeFOL

Nodo del tablero semántico para lógica de primer orden.
Mantiene el estado de una rama del tablero incluyendo términos disponibles,
cuantificadores instanciados y constantes frescas generadas.

# Campos
- `formulas`: Fórmulas en este nodo
- `is_closed`: Si la rama está cerrada (contradicción encontrada)
- `children`: Nodos hijos (ramas)
- `closure_reason`: Descripción de por qué se cerró
- `depth`: Profundidad en el árbol
- `branch_id`: Identificador de la rama (ej: "1.2.1")
- `used_terms`: Términos disponibles para instanciación de ∀
- `instantiated_universals`: Registro de instanciaciones de cada ∀
- `used_existentials`: Existenciales ya expandidos
- `fresh_const_counter`: Contador para generar constantes frescas
"""
mutable struct TSNodeFOL
    formulas::Vector{FOLFormula}                        # Todas las fórmulas en este nodo
    derived_formulas::Vector{FOLFormula}                # Fórmulas derivadas EN este nodo (puede ser más de una en α)
    parent::Union{TSNodeFOL, Nothing}              # Referencia al nodo padre para reconstruir rama
    is_closed::Bool
    children::Vector{TSNodeFOL}
    closure_reason::String
    depth::Int
    branch_id::String
    used_terms::Set{Term}              # Términos disponibles para instanciación
    instantiated_universals::Dict{FOLFormula, Set{Term}}  # ∀ fórmulas ya instanciadas
    used_existentials::Set{FOLFormula}  # ∃ fórmulas ya expandidas
    fresh_const_counter::Ref{Int}       # Contador para constantes frescas
    formula_number::Int                 # Número de la fórmula derivada
    derivation_rule::String             # Regla aplicada (α, β, δ, γ)
    parent_formula_numbers::Vector{Int} # Números de fórmulas padre
    formula_map::Dict{String, Int}      # Mapa fórmula → número (solo en nodo raíz)
end

"""
    FormulaInfo

Información sobre una fórmula: número, regla de derivación, fórmulas padre.
"""
struct FormulaInfo
    number::Int                         # Número de la fórmula (1, 2, 3, ...)
    formula::FOLFormula                 # La fórmula misma
    is_initial::Bool                    # ¿Es una fórmula inicial (raíz)?
    rule::String                        # Regla aplicada (α, β, δ, γ)
    parent_numbers::Vector{Int}         # Números de las fórmulas de las que se derivó
    parent_terms::String                # Info adicional (términos usados, instanciación, etc.)
end

"""
    FormulaRegistry

Registro global de todas las fórmulas con números para trazabilidad.
"""
mutable struct FormulaRegistry
    formulas::Vector{FormulaInfo}       # Lista de todas las fórmulas numeradas
    formula_to_number::Dict{String, Int}  # Mapeo: hash fórmula → número (para evitar duplicados)
    current_number::Int                 # Número siguiente a asignar
end

function FormulaRegistry()
    return FormulaRegistry(
        FormulaInfo[],
        Dict{String, Int}(),
        1
    )
end

"""
    add_formula!(registry::FormulaRegistry, f::FOLFormula, is_initial::Bool, 
                 rule::String, parent_numbers::Vector{Int}, parent_terms::String)

Añade una fórmula al registro con información de derivación.
"""
function add_formula!(
    registry::FormulaRegistry, 
    f::FOLFormula, 
    is_initial::Bool, 
    rule::String = "",
    parent_numbers::Vector{Int} = Int[],
    parent_terms::String = ""
)::Int
    # Hash simple de la fórmula para evitar duplicados
    formula_str = string(f)
    
    # Si ya existe, retornar su número
    if haskey(registry.formula_to_number, formula_str)
        return registry.formula_to_number[formula_str]
    end
    
    # Crear nueva entrada
    number = registry.current_number
    info = FormulaInfo(number, f, is_initial, rule, parent_numbers, parent_terms)
    push!(registry.formulas, info)
    registry.formula_to_number[formula_str] = number
    registry.current_number += 1
    
    return number
end

function TSNodeFOL(
    Fs::Vector{FOLFormula}, 
    depth::Int = 0, 
    branch_id::String = "1",
    used_terms::Set{Term} = Set{Term}(),
    instantiated::Dict{FOLFormula, Set{Term}} = Dict{FOLFormula, Set{Term}}(),
    used_exist::Set{FOLFormula} = Set{FOLFormula}(),
    counter::Ref{Int} = Ref(1),
    derived_formulas::Vector{FOLFormula} = FOLFormula[],
    parent::Union{TSNodeFOL, Nothing} = nothing,
    formula_number::Int = 0,
    derivation_rule::String = "",
    parent_formula_numbers::Vector{Int} = Int[],
    formula_map::Dict{String, Int} = Dict{String, Int}()
)
    return TSNodeFOL(
        Fs, derived_formulas, parent, false, TSNodeFOL[], "", depth, branch_id,
        used_terms, instantiated, used_exist, counter, formula_number, derivation_rule, 
        parent_formula_numbers, formula_map
    )
end

"""
    print_formula_registry(registry::FormulaRegistry, io::IO = stdout)

Imprime el registro de todas las fórmulas con sus números, reglas de derivación y fórmulas padre.
"""
function print_formula_registry(registry::FormulaRegistry, io::IO = stdout)
    println(io, "=" ^ 80)
    println(io, "REGISTRO DE FÓRMULAS")
    println(io, "=" ^ 80)
    println(io)
    
    for info in registry.formulas
        f_num = string(info.number)
        
        # Mostrar número y fórmula
        if info.is_initial
            println(io, "$f_num: $(info.formula)")
            println(io, "    Inicial (premisa)")
        else
            println(io, "$f_num: $(info.formula)")
            println(io, "    Regla: $(info.rule)")
            
            if !isempty(info.parent_numbers)
                parent_str = join(info.parent_numbers, ", ")
                println(io, "    Derivada de: fórmula(s) $parent_str")
            end
            
            if !isempty(info.parent_terms)
                println(io, "    $(info.parent_terms)")
            end
        end
        println(io)
    end
    
    println(io, "=" ^ 80)
    println(io, "Total de fórmulas: $(length(registry.formulas))")
    println(io, "=" ^ 80)
end
