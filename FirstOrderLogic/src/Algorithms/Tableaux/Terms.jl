# ════════════════════════════════════════════════════════════════════════════
# Manejo de Términos para Tableros Semánticos FOL
# ════════════════════════════════════════════════════════════════════════════

"""
    is_literal_fol(f::FOLFormula) -> Bool

Verifica si una fórmula es un literal (predicado o negación de predicado).
"""
function is_literal_fol(f::FOLFormula)
    return f isa Predicate_FOL || (f isa NotFOL && f.operand isa Predicate_FOL)
end

"""
    extract_terms(f::FOLFormula) -> Set{Term}

Extrae todos los términos que aparecen en una fórmula.
"""
function extract_terms(f::FOLFormula)
    terms = Set{Term}()
    
    function extract_from_term(t::Term)
        if t isa Var_FOL || t isa Const_FOL
            push!(terms, t)
        elseif t isa Func_FOL
            push!(terms, t)
            for arg in t.args
                extract_from_term(arg)
            end
        end
    end
    
    function walk(g::FOLFormula)
        if g isa Predicate_FOL
            for arg in g.args
                extract_from_term(arg)
            end
        elseif g isa NotFOL
            walk(g.operand)
        elseif g isa AndFOL || g isa OrFOL || g isa ImpliesFOL || g isa IffFOL
            walk(g.left)
            walk(g.right)
        elseif g isa Forall || g isa Exists
            walk(g.body)
        end
    end
    
    walk(f)
    return terms
end

"""
    is_ground_term(term::Term) -> Bool

Verifica si un término es cerrado (ground term), es decir, no contiene variables libres.
Un término cerrado contiene solo constantes y funciones con argumentos cerrados.
"""
function is_ground_term(term::Term)::Bool
    if term isa Var_FOL
        return false  # Variable → no es cerrado
    elseif term isa Const_FOL
        return true   # Constante → es cerrado
    elseif term isa Func_FOL
        # Función es cerrada si todos sus argumentos son cerrados
        return all(is_ground_term(arg) for arg in term.args)
    else
        return true   # Otros casos (si existen)
    end
end

"""
    get_ground_terms(terms::Set{Term}) -> Set{Term}

Filtra solo los términos cerrados (ground terms) de un conjunto.
"""
function get_ground_terms(terms::Set{Term})::Set{Term}
    return Set{Term}(filter(is_ground_term, terms))
end

"""
    extract_ground_terms(f::FOLFormula) -> Set{Term}

Extrae solo los términos cerrados (ground terms) que aparecen en una fórmula.
Un término cerrado no contiene variables, solo constantes y funciones.
"""
function extract_ground_terms(f::FOLFormula)::Set{Term}
    all_terms = extract_terms(f)
    return get_ground_terms(all_terms)
end

"""
    has_contradiction_fol(Fs::Vector{FOLFormula}) -> (Bool, String)

Detecta contradicciones usando unificación: P(t) y ¬P(s) donde UMG(P(t), P(s)) existe.
"""
function has_contradiction_fol(Fs::Vector{FOLFormula})
    # Separar literales positivos y negativos
    positives = Predicate_FOL[]
    negatives = Predicate_FOL[]
    
    for F in Fs
        if F isa Predicate_FOL
            push!(positives, F)
        elseif F isa NotFOL && F.operand isa Predicate_FOL
            push!(negatives, F.operand)
        end
    end
    
    # Buscar contradicción mediante unificación
    for pos in positives
        for neg in negatives
            if pos.name == neg.name && length(pos.args) == length(neg.args)
                # Intentar unificar los predicados completos
                θ = UMG(pos, neg)
                
                if θ !== nothing
                    pos_str = string(apply_substitution(pos, θ))
                    return true, "$pos_str y ¬$pos_str"
                end
            end
        end
    end
    
    return false, ""
end
