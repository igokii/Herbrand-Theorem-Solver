"""
Base de datos de ejemplos para cada función
"""

const EXAMPLES_DB = Dict(
    :syntax => [
        """# Variables y constantes
x, y = vars("x", "y")
a, b = constants("a", "b")""",
        
        """# Predicados
P = predicate("P")
φ = P([var("x")])  # P(x)""",
        
        """# Fórmula completa
x = var("x")
P = predicate("P")
Q = predicate("Q")
φ = ∀("x", P([x]) → Q([x]))  # ∀x (P(x) → Q(x))"""
    ],
    
    :to_cnf => [
        """# Ejemplo simple
φ = parse_formula("P ∨ Q")
to_cnf(φ)  # Ya en CNF""",
        
        """# Con implicación
φ = parse_formula("(P ∧ Q) → R")
to_cnf(φ)  # (!P ∨ !Q ∨ R)""",
        
        """# Con distribución
φ = parse_formula("P ∨ (Q ∧ R)")
to_cnf(φ)  # (P ∨ Q) ∧ (P ∨ R)""",
        
        """# Con cuantificadores
φ = parse_formula("∀x (P(x) → (Q(x) ∨ R(x)))")
to_cnf(φ)"""
    ],
    
    :to_Px => [
        """# Forma prenex
φ = parse_formula("(∀x P(x)) → (∃y Q(y))")
to_Px(φ)  # ∃y ∀x (P(x) → Q(y))""",
        
        """# Múltiples cuantificadores anidados
φ = parse_formula("∀x (P(x) → ∃y (Q(y) ∧ ∀z R(z)))")
to_Px(φ)"""
    ],
    
    :to_Sk => [
        """# Skolemización simple
φ = parse_formula("∃x P(x)")
to_Sk(φ)  # P(c₁) donde c₁ es constante de Skolem""",
        
        """# Con dependencia
φ = parse_formula("∀x ∃y P(x, y)")
to_Sk(φ)  # ∀x P(x, f₁(x)) donde f₁ es función de Skolem"""
    ],
    
    :tableaux => [
        """# Verificar validez
φ = parse_formula("∀x (P(x) → P(x))")
TS_VALID(φ)  # :VALID""",
        
        """# Verificar satisfacibilidad
φ = parse_formula("P ∧ !P")
TS_SAT(φ)  # :UNSAT""",
        
        """# Construir tableau
φ = parse_formula("∃x P(x)")
t = TS_solve(φ)
print_TS_FOL(t)""",
        
        """# Extraer modelo
φ = parse_formula("∃x (P(x) ∧ Q(x))")
t = TS_solve(φ)
m = one_model(t)
print_model(m)
ls = to_LS(m)
show_LS(ls)"""
    ],
    
    :resolution => [
        """# Verificar validez
φ = parse_formula("P → P")
RES_VALID(φ)  # true""",
        
        """# Consecuencia lógica
Γ = [parse_formula("∀x (P(x) → Q(x))"), parse_formula("P(a)")]
φ = parse_formula("Q(a)")
RES_LC(Γ, φ)  # true""",
        
        """# Verificar argumento
premises = [parse_formula("∀x (H(x) → M(x))"), parse_formula("H(Sócrates)")]
conclusion = parse_formula("M(Sócrates)")
verify_argument(premises, conclusion)""",
        
        """# Con tracking visual
φ = parse_formula("(P ∨ Q) ∧ (!P ∨ R) ∧ (!Q ∨ R) ∧ !R")
proof_of_insat_graph(φ)"""
    ],
    
    :UMG => [
        """# Unificación simple
t1 = func("f", [var("x"), const_("a")])
t2 = func("f", [const_("b"), var("y")])
σ = UMG(t1, t2)  # {x ↦ b, y ↦ a}""",
        
        """# No unificables (símbolos diferentes)
t1 = func("f", [var("x")])
t2 = func("g", [var("x")])
UMG(t1, t2)  # nothing""",
        
        """# Occurs check
t1 = var("x")
t2 = func("f", [var("x")])
UMG(t1, t2)  # nothing""",
        
        """# Aplicar sustitución
t = func("f", [var("x"), var("y")])
σ = Substitution(Dict("x" => const_("a"), "y" => const_("b")))
apply_substitution(t, σ)  # f(a, b)"""
    ],
    
    :herbrand => [
        """# Universo de Herbrand
φ = parse_formula("∃x P(f(x))")
u = H_Un(φ, 2)  # {c₀, f(c₀), f(f(c₀))}""",
        
        """# Extensión de Herbrand
φ = parse_formula("∀x P(x)")
ex = H_Ex(φ, 1)
show_H_ex(ex)""",
        
        """# L-estructura de Herbrand
φ = parse_formula("∃x (P(x) ∧ Q(f(x)))")
ls = herbrand_structure(φ, 2)
show_LS(ls)"""
    ],
    
    :models => [
        """# Crear L-estructura manualmente
ls = LStructure(
    [1, 2, 3],                    # Dominio
    Dict("a" => 1, "b" => 2),     # Constantes
    Dict("P" => x -> x > 1),      # Predicados
    Dict("f" => x -> x + 1)       # Funciones
)
validate(ls)""",
        
        """# Verificar modelo
φ = parse_formula("P(f(a))")
is_model_of(ls, φ)""",
        
        """# Desde tableau
φ = parse_formula("∃x P(x)")
t = TS_solve(φ)
m = one_model(t)
ls = to_LS(m)
show_LS(ls)"""
    ]
)

function show_examples(func::Symbol)
    if haskey(EXAMPLES_DB, func)
        println("╔════════════════════════════════════════════════════════════════╗")
        println("║           📋 Ejemplos: $func")
        println("╚════════════════════════════════════════════════════════════════╝\n")
        
        examples = EXAMPLES_DB[func]
        for (i, ex) in enumerate(examples)
            println("━━━ Ejemplo $i ━━━")
            println(ex)
            println()
        end
        
        println("💡 TIP: Copia y pega estos ejemplos en el REPL para probarlos")
        println("📚 Usa `help(:$func)` para más información")
    else
        println("⚠️  No hay ejemplos disponibles para: $func")
        println("\n📋 Funciones con ejemplos:")
        for key in sort(collect(keys(EXAMPLES_DB)))
            println("  - :$key")
        end
    end
end
