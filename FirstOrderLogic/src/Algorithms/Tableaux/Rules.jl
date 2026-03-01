# ════════════════════════════════════════════════════════════════════════════
# Reglas de Tableaux Semánticos (α, β, γ, δ)
# ════════════════════════════════════════════════════════════════════════════

"""
    apply_α_fol(Fs::Vector{FOLFormula}) -> (Bool, Vector{FOLFormula}, FOLFormula, String, Vector{FOLFormula})

Aplica UNA regla α (no ramificante) y retorna información sobre qué se aplicó.
Retorna: (aplicada, nuevas_formulas, formula_original, nombre_regla, formulas_derivadas)
"""
function apply_α_fol(Fs::Vector{FOLFormula})
    for (i, F) in enumerate(Fs)
        remaining = [Fs[j] for j in 1:length(Fs) if j != i]
        derived_formulas = FOLFormula[]
        rule_name = ""
        
        if F isa AndFOL
            # α: A ∧ B → A, B
            derived_formulas = FOLFormula[F.left, F.right]
            rule_name = "α (∧)"
            
        elseif F isa NotFOL && F.operand isa OrFOL
            # α: ¬(A ∨ B) → ¬A, ¬B
            derived_formulas = FOLFormula[NotFOL(F.operand.left), NotFOL(F.operand.right)]
            rule_name = "α (¬∨)"
            
        elseif F isa NotFOL && F.operand isa ImpliesFOL
            # α: ¬(A → B) → A, ¬B
            derived_formulas = FOLFormula[F.operand.left, NotFOL(F.operand.right)]
            rule_name = "α (¬→)"
            
        elseif F isa NotFOL && F.operand isa NotFOL
            # α: ¬¬A → A
            derived_formulas = FOLFormula[F.operand.operand]
            rule_name = "α (¬¬)"
            
        elseif F isa NotFOL && F.operand isa Forall
            # α: ¬∀x.A → ∃x.¬A
            derived_formulas = FOLFormula[Exists(F.operand.var, NotFOL(F.operand.body))]
            rule_name = "α (¬∀)"
            
        elseif F isa NotFOL && F.operand isa Exists
            # α: ¬∃x.A → ∀x.¬A
            derived_formulas = FOLFormula[Forall(F.operand.var, NotFOL(F.operand.body))]
            rule_name = "α (¬∃)"
        end
        
        if !isempty(derived_formulas)
            new_Fs = vcat(remaining, derived_formulas)
            return true, new_Fs, F, rule_name, derived_formulas
        end
    end
    
    return false, Fs, FOLFormula[], "", FOLFormula[]
end

"""
    apply_β_fol(Fs::Vector{FOLFormula}) -> (Bool, Vector{FOLFormula}, Vector{FOLFormula}, String)

Encuentra y aplica reglas β (ramificantes).
"""
function apply_β_fol(Fs::Vector{FOLFormula})
    for (i, F) in enumerate(Fs)
        remaining = [Fs[j] for j in 1:length(Fs) if j != i]
        
        if F isa OrFOL
            # β: A ∨ B → A | B
            left_branch = vcat(remaining, [F.left])
            right_branch = vcat(remaining, [F.right])
            return true, left_branch, right_branch, "∨: $F"
            
        elseif F isa NotFOL && F.operand isa AndFOL
            # β: ¬(A ∧ B) → ¬A | ¬B
            left_branch = vcat(remaining, [NotFOL(F.operand.left)])
            right_branch = vcat(remaining, [NotFOL(F.operand.right)])
            return true, left_branch, right_branch, "¬∧: $F"
            
        elseif F isa ImpliesFOL
            # β: A → B → ¬A | B
            left_branch = vcat(remaining, [NotFOL(F.left)])
            right_branch = vcat(remaining, [F.right])
            return true, left_branch, right_branch, "→: $F"
            
        elseif F isa IffFOL
            # β: A ↔ B → (A ∧ B) | (¬A ∧ ¬B)
            left_branch = vcat(remaining, [F.left, F.right])
            right_branch = vcat(remaining, [NotFOL(F.left), NotFOL(F.right)])
            return true, left_branch, right_branch, "↔: $F"
            
        elseif F isa NotFOL && F.operand isa IffFOL
            # β: ¬(A ↔ B) → (A ∧ ¬B) | (¬A ∧ B)
            bic = F.operand
            left_branch = vcat(remaining, [bic.left, NotFOL(bic.right)])
            right_branch = vcat(remaining, [NotFOL(bic.left), bic.right])
            return true, left_branch, right_branch, "¬↔: $F"
        end
    end
    
    return false, FOLFormula[], FOLFormula[], ""
end

"""
    apply_δ_fol(Fs::Vector{FOLFormula}, used_exist::Set{FOLFormula}, counter::Ref{Int}) 
        -> (Bool, Vector{FOLFormula}, FOLFormula, Term)

Aplica regla δ (existencial): ∃x.A → A[x/c] con c fresca.
Solo se aplica una vez por fórmula existencial en cada rama.
"""
function apply_δ_fol(
    Fs::Vector{FOLFormula}, 
    used_exist::Set{FOLFormula},
    counter::Ref{Int}
)
    for (i, F) in enumerate(Fs)
        if F isa Exists && !(F in used_exist)
            # Crear constante fresca
            fresh_const = Const_FOL("c$(counter[])")
            counter[] += 1
            
            # Sustituir variable por constante fresca
            instantiated = substitute_var(F.body, F.var, fresh_const)
            
            # Mantener el existencial en la rama (puede usarse en otras instanciaciones)
            new_Fs = copy(Fs)
            push!(new_Fs, instantiated)
            
            return true, new_Fs, F, fresh_const
        end
    end
    
    return false, Fs, Forall(Var_FOL("dummy"), Predicate_FOL("dummy", Term[])), Const_FOL("dummy")
end

"""
    apply_γ_fol(Fs::Vector{FOLFormula}, used_terms::Set{Term}, instantiated::Dict, counter::Ref{Int}) 
        -> (Bool, Vector{FOLFormula}, FOLFormula, Term)

Aplica regla γ (universal): ∀x.A puede instanciarse con cualquier TÉRMINO CERRADO.
Puede aplicarse múltiples veces con diferentes términos (solo con términos ground).

IMPORTANTE: Si NO hay términos cerrados disponibles pero HAY universales,
se genera una constante fresca NUEVA para poder instanciar el universal.
Esto es necesario para fórmulas como ∀x.P(x), ∀y.¬P(y) que son insatisfacibles.
"""
function apply_γ_fol(
    Fs::Vector{FOLFormula},
    used_terms::Set{Term},
    instantiated::Dict{FOLFormula, Set{Term}},
    counter::Ref{Int},
    branch_id::String
)
    for (i, F) in enumerate(Fs)
        if F isa Forall
            # Obtener términos ya usados para esta fórmula
            already_used = get(instantiated, F, Set{Term}())
            
            # Filtrar solo términos cerrados (ground terms)
            ground_terms = get_ground_terms(used_terms)
            
            # Caso 1: Hay términos cerrados disponibles
            # Buscar un término cerrado que no se haya usado aún
            for term in ground_terms
                if !(term in already_used)
                    # Instanciar con este término
                    inst = substitute_var(F.body, F.var, term)
                    
                    # Mantener el universal en la rama (puede usarse con otros términos)
                    new_Fs = copy(Fs)
                    push!(new_Fs, inst)
                    
                    return true, new_Fs, F, term
                end
            end
            
            # Caso 2: NO hay términos cerrados pero HAY un universal
            # Generar una constante fresca NUEVA para poder instanciar
            if isempty(ground_terms)
                fresh_const = Const_FOL("c$(counter[])")
                counter[] += 1
                
                # Instanciar el universal con esta constante fresca
                inst = substitute_var(F.body, F.var, fresh_const)
                
                # Mantener el universal y agregar la instancia
                new_Fs = copy(Fs)
                push!(new_Fs, inst)
                
                # Agregar la nueva constante a los términos disponibles
                new_used_terms = copy(used_terms)
                push!(new_used_terms, fresh_const)
                
                # Retornar usando la nueva constante fresca como término utilizado
                return true, new_Fs, F, fresh_const
            end
        end
    end
    
    return false, Fs, Forall(Var_FOL("dummy"), Predicate_FOL("dummy", Term[])), Const_FOL("dummy")
end
