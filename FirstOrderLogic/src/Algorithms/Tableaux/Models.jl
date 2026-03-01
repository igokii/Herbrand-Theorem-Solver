# ════════════════════════════════════════════════════════════════════════════
# Extracción y Verificación de Modelos desde Tableaux
# ════════════════════════════════════════════════════════════════════════════

"""
    one_model(node::TSNodeFOL) -> Union{FOLModel, Nothing}

Extrae un modelo de una rama abierta del tablero.

# Ver también
- `all_models`: Extrae todos los modelos posibles
- `print_model`: Imprime un modelo de forma legible
- `verify_model`: Verifica que un modelo satisface una fórmula
"""
function one_model(node::TSNodeFOL)::Union{FOLModel, Nothing}
    open_branch = find_open_branch(node)
    
    if isnothing(open_branch)
        return nothing
    end
    
    formulas = collect_branch_formulas(open_branch)
    
    true_atoms = Set{FOLFormula}()
    false_atoms = Set{FOLFormula}()
    universal_constraints = FOLFormula[]
    domain = Set{Term}()
    
    for f in formulas
        if is_literal_fol(f)
            if f isa NotFOL
                inner = f.operand
                if inner isa Predicate_FOL
                    push!(false_atoms, inner)
                    union!(domain, extract_ground_terms(inner))
                end
            elseif f isa Predicate_FOL
                push!(true_atoms, f)
                union!(domain, extract_ground_terms(f))
            end
        elseif f isa Forall
            push!(universal_constraints, f)
            union!(domain, extract_ground_terms(f))
        end
    end
    
    if isempty(domain)
        push!(domain, Const_FOL("c_witness"))
    end
    
    return FOLModel(domain, true_atoms, false_atoms, universal_constraints, open_branch.branch_id)
end

"""
    find_open_branch(node::TSNodeFOL) -> Union{TSNodeFOL, Nothing}

Encuentra la primera rama abierta en el tablero (búsqueda en profundidad).
"""
function find_open_branch(node::TSNodeFOL)::Union{TSNodeFOL, Nothing}
    if node.is_closed
        return nothing
    end
    
    if isempty(node.children)
        return node
    end
    
    for child in node.children
        result = find_open_branch(child)
        if !isnothing(result)
            return result
        end
    end
    
    return nothing
end

"""
    collect_branch_formulas(node::TSNodeFOL) -> Vector{FOLFormula}

Recolecta todas las fórmulas desde la raíz hasta un nodo dado.
"""
function collect_branch_formulas(node::TSNodeFOL)::Vector{FOLFormula}
    return node.formulas
end

"""
    all_models(node::TSNodeFOL; max_models::Int = 10) -> Vector{FOLModel}

Extrae todos los modelos posibles de todas las ramas abiertas.
"""
function all_models(node::TSNodeFOL; max_models::Int = 10)::Vector{FOLModel}
    models = FOLModel[]
    find_all_open_branches!(node, models, max_models)
    return models
end

"""
    find_all_open_branches!(node, models, max_models) -> Nothing

Función auxiliar para encontrar todas las ramas abiertas recursivamente.
"""
function find_all_open_branches!(node::TSNodeFOL, models::Vector{FOLModel}, max_models::Int)
    if length(models) >= max_models
        return
    end
    
    if node.is_closed
        return
    end
    
    if isempty(node.children)
        formulas = node.formulas
        
        true_atoms = Set{FOLFormula}()
        false_atoms = Set{FOLFormula}()
        universal_constraints = FOLFormula[]
        domain = Set{Term}()
        
        for f in formulas
            if is_literal_fol(f)
                if f isa NotFOL
                    inner = f.operand
                    if inner isa Predicate_FOL
                        push!(false_atoms, inner)
                        union!(domain, extract_ground_terms(inner))
                    end
                elseif f isa Predicate_FOL
                    push!(true_atoms, f)
                    union!(domain, extract_ground_terms(f))
                end
            elseif f isa Forall
                push!(universal_constraints, f)
            end
        end
        
        if isempty(domain)
            push!(domain, Const_FOL("c_witness"))
        end
        
        push!(models, FOLModel(domain, true_atoms, false_atoms, universal_constraints, node.branch_id))
        return
    end
    
    for child in node.children
        find_all_open_branches!(child, models, max_models)
    end
end

"""
    print_model(model::FOLModel; io::IO = stdout)

Imprime un modelo de forma legible.
"""
function print_model(model::FOLModel; io::IO = stdout)
    println(io, "="^70)
    println(io, "MODELO (Rama: $(model.branch_id))")
    println(io, "="^70)
    
    println(io, "Dominio: {$(join(sort([string(t) for t in model.domain]), ", "))}")
    println(io)
    
    if !isempty(model.true_atoms)
        println(io, "Átomos verdaderos:")
        for atom in sort(collect(model.true_atoms), by=string)
            println(io, "  ✓ $atom")
        end
        println(io)
    end
    
    if !isempty(model.false_atoms)
        println(io, "Átomos falsos:")
        for atom in sort(collect(model.false_atoms), by=string)
            println(io, "  ⊗ $atom")
        end
        println(io)
    end
    
    if !isempty(model.universal_constraints)
        println(io, "Restricciones universales:")
        for constraint in model.universal_constraints
            println(io, "  • $constraint")
        end
        println(io)
    end
    
    println(io, "="^70)
end

"""
    verify_model(model::FOLModel, formula::FOLFormula) -> Bool

Verifica (de forma básica) si un modelo satisface una fórmula.
"""
function verify_model(model::FOLModel, formula::FOLFormula)::Bool
    if formula isa Predicate_FOL
        return formula in model.true_atoms
    elseif formula isa NotFOL
        inner = formula.operand
        if inner isa Predicate_FOL
            return inner in model.false_atoms
        end
    elseif formula isa AndFOL
        return verify_model(model, formula.left) && verify_model(model, formula.right)
    elseif formula isa OrFOL
        return verify_model(model, formula.left) || verify_model(model, formula.right)
    end
    
    return true
end

"""
    TS_get_model(f::FOLFormula; max_depth::Int = 50) -> Union{FOLModel, Nothing}

Construye el tablero para una fórmula y extrae un modelo si es satisfactible.
"""
function TS_get_model(f::FOLFormula; max_depth::Int = 50)::Union{FOLModel, Nothing}
    tableau = TS_FOL([f]; max_depth = max_depth)
    return one_model(tableau)
end

"""
    TS_get_all_models(f::FOLFormula; max_depth::Int = 50, max_models::Int = 10) -> Vector{FOLModel}

Construye el tablero para una fórmula y extrae todos los modelos posibles.
"""
function TS_get_all_models(f::FOLFormula; max_depth::Int = 50, max_models::Int = 10)::Vector{FOLModel}
    tableau = TS_FOL([f]; max_depth = max_depth)
    return all_models(tableau; max_models = max_models)
end

"""
    to_LS(model::FOLModel) -> LStructure

Convierte un FOLModel (extraído de un tablero) a una LStructure.
"""
function to_LS(model::FOLModel)::LStructure
    universe = Set{Any}()
    constant_interp = Dict{String, Any}()
    
    for term in model.domain
        if isa(term, Const_FOL)
            name = term.name
            push!(universe, name)
            constant_interp[name] = name
        elseif isa(term, Var_FOL)
            name = term.name
            push!(universe, name)
        elseif isa(term, Func_FOL)
            str_repr = string(term)
            push!(universe, str_repr)
        end
    end
    
    predicate_interp = Dict{String, Set{Tuple}}()
    
    for atom in model.true_atoms
        if isa(atom, Predicate_FOL)
            pred_name = atom.name
            
            if !haskey(predicate_interp, pred_name)
                predicate_interp[pred_name] = Set{Tuple}()
            end
            
            args_tuple = Tuple(
                if isa(arg, Const_FOL)
                    arg.name
                elseif isa(arg, Var_FOL)
                    arg.name
                elseif isa(arg, Func_FOL)
                    string(arg)
                else
                    string(arg)
                end
                for arg in atom.args
            )
            
            push!(predicate_interp[pred_name], args_tuple)
        end
    end
    
    function_interp = Dict{String, Dict{Tuple, Any}}()
    
    for term in model.domain
        if isa(term, Func_FOL)
            func_name = term.name
            
            if !haskey(function_interp, func_name)
                function_interp[func_name] = Dict{Tuple, Any}()
            end
            
            args_tuple = Tuple(
                if isa(arg, Const_FOL)
                    arg.name
                elseif isa(arg, Var_FOL)
                    arg.name
                else
                    string(arg)
                end
                for arg in term.args
            )
            
            result = string(term)
            push!(universe, result)
            function_interp[func_name][args_tuple] = result
        end
    end
    
    if isempty(universe)
        push!(universe, "∅")
    end
    
    return LStructure(universe, predicate_interp, function_interp, constant_interp)
end
