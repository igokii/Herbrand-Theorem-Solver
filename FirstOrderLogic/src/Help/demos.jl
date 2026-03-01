"""
Demostraciones ejecutables con ejemplos
"""

"""
    demo(topic::Symbol)

Ejecuta una demostración con ejemplos del tema especificado.

# Demos disponibles
- `:cnf` - Ejemplos de CNF
- `:tableaux` - Ejemplos de tableaux
- `:resolution` - Ejemplos de resolución
- `:herbrand` - Ejemplos de Herbrand

# Uso
```julia
demo(:cnf)         # Demo de CNF
demo(:tableaux)    # Demo de tableaux
```
"""
function demo(topic::Symbol)
    if topic == :cnf
        demo_cnf()
    elseif topic == :tableaux
        demo_tableaux()
    elseif topic == :resolution
        demo_resolution()
    elseif topic == :herbrand
        demo_herbrand()
    else
        println("⚠️  Demo no disponible: $topic")
        println("\n🎮 Demos disponibles:")
        println("  :cnf, :tableaux, :resolution, :herbrand")
    end
end

function demo_cnf()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║           🎮 Demo: Forma Normal Conjuntiva (CNF)              ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    P = predicate("P")
    Q = predicate("Q")
    R = predicate("R")
    
    examples = [
        (P([]) ∨ Q([]), "Fórmula simple (ya en CNF)"),
        ((P([]) ∧ Q([])) → R([]), "Implicación simple"),
        (P([]) ∨ (Q([]) ∧ R([])), "Requiere distribución"),
        (!(P([]) ∧ Q([])) ∨ R([]), "Con negación")
    ]
    
    for (i, (φ, desc)) in enumerate(examples)
        println("━━━ Ejemplo $i: $desc ━━━")
        println("📝 Original: ", φ)
        result = to_CNF(φ)
        println("➜  CNF:      ", result)
        println()
    end
    
    println("💡 TIP: Usa tutorial(:cnf) para aprender paso a paso")
end

function demo_tableaux()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║              🎮 Demo: Tableaux Semánticos                      ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    P = predicate("P")
    Q = predicate("Q")
    x = var("x")
    
    println("━━━ Ejemplo 1: Contradicción ━━━")
    φ1 = P([]) ∧ !P([])
    println("📝 Fórmula: ", φ1)
    result1 = TS_SAT(φ1)
    println("➜  Resultado: ", result1)
    println()
    
    println("━━━ Ejemplo 2: Tautología ━━━")
    φ2 = P([]) ∨ !P([])
    println("📝 Fórmula: ", φ2)
    result2 = TS_VALID(φ2)
    println("➜  Resultado: ", result2)
    println()
    
    println("━━━ Ejemplo 3: Satisfacible (con modelo) ━━━")
    φ3 = ∃("x", P([x]))
    println("📝 Fórmula: ", φ3)
    t3 = TS_solve(φ3)
    println("➜  Resultado: ", TS_SAT(φ3))
    m3 = one_model(t3)
    if !isnothing(m3)
        println("➜  Modelo: ")
        print_model(m3)
    end
    println()
    
    println("💡 TIP: Usa tutorial(:tableaux) para aprender el método")
end

function demo_resolution()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║            🎮 Demo: Método de Resolución                       ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    P = predicate("P")
    Q = predicate("Q")
    H = predicate("H")
    M = predicate("M")
    a = const_("a")
    x = var("x")
    
    println("━━━ Ejemplo 1: Fórmula válida ━━━")
    φ1 = P([]) → P([])
    println("📝 Fórmula: ", φ1)
    result1 = RES_VALID(φ1)
    println("➜  Válida: ", result1)
    println()
    
    println("━━━ Ejemplo 2: Argumento clásico (Modus Ponens) ━━━")
    println("📝 Premisa 1: P → Q")
    println("   Premisa 2: P")
    println("   Conclusión: Q")
    
    premises = [P([]) → Q([]), P([])]
    conclusion = Q([])
    
    result2 = verify_argument(premises, conclusion)
    println("➜  Válido: ", result2[:valid])
    println()
    
    println("━━━ Ejemplo 3: Argumento con cuantificadores ━━━")
    println("📝 Premisa 1: ∀x (H(x) → M(x))")
    println("   Premisa 2: H(a)")
    println("   Conclusión: M(a)")
    
    premises3 = [∀("x", H([x]) → M([x])), H([a])]
    conclusion3 = M([a])
    
    result3 = verify_argument(premises3, conclusion3)
    println("➜  Válido: ", result3[:valid])
    println()
    
    println("💡 TIP: Usa tutorial(:resolution) para aprender el método")
end

function demo_herbrand()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║              🎮 Demo: Universo de Herbrand                     ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    P = predicate("P")
    Q = predicate("Q")
    x = var("x")
    f = function_("f")
    
    println("━━━ Ejemplo 1: Universo simple ━━━")
    φ1 = ∃("x", P([f([x])]))
    println("📝 Fórmula: ", φ1)
    println()
    println("Universo profundidad 0:")
    u0 = H_Un(φ1, 0)
    println("  ", u0)
    println()
    println("Universo profundidad 1:")
    u1 = H_Un(φ1, 1)
    println("  ", u1)
    println()
    println("Universo profundidad 2:")
    u2 = H_Un(φ1, 2)
    println("  ", u2)
    println()
    
    println("━━━ Ejemplo 2: Extensión de Herbrand ━━━")
    φ2 = ∀("x", P([x]))
    println("📝 Fórmula: ", φ2)
    println()
    println("Extensión profundidad 1:")
    ex = H_Ex(φ2, 1)
    show_H_ex(ex)
    println()
    
    println("━━━ Ejemplo 3: L-estructura de Herbrand ━━━")
    φ3 = ∃("x", P([x]) ∧ Q([f([x])]))
    println("📝 Fórmula: ", φ3)
    println()
    ls = herbrand_structure(φ3, 1)
    show_LS(ls)
    println()
    
    println("💡 TIP: Usa help(:herbrand) para más información")
end
