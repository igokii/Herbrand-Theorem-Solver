"""
Tutoriales interactivos paso a paso
"""

"""
    tutorial(topic::Symbol)

Inicia un tutorial interactivo sobre un tema específico.

# Tutoriales disponibles
- `:cnf` - Forma Normal Conjuntiva
- `:tableaux` - Tableaux semánticos
- `:resolution` - Método de resolución
- `:unification` - Unificación y UMG

# Uso
```julia
tutorial(:cnf)        # Tutorial de CNF
tutorial(:tableaux)   # Tutorial de tableaux
```
"""
function tutorial(topic::Symbol)
    if topic == :cnf
        tutorial_cnf()
    elseif topic == :tableaux
        tutorial_tableaux()
    elseif topic == :resolution
        tutorial_resolution()
    elseif topic == :unification
        tutorial_unification()
    else
        println("⚠️  Tutorial no disponible: $topic")
        println("\n📚 Tutoriales disponibles:")
        println("  :cnf, :tableaux, :resolution, :unification")
    end
end

function tutorial_cnf()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║       🎓 Tutorial: Forma Normal Conjuntiva (CNF)              ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("1️⃣  ¿Qué es CNF?")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("Una fórmula está en CNF si es una CONJUNCIÓN de DISYUNCIONES:")
    println("  (L₁ ∨ L₂ ∨ ... ∨ Lₙ) ∧ (M₁ ∨ ... ∨ Mₘ) ∧ ...")
    println()
    println("Donde cada Lᵢ, Mⱼ es un literal (átomo o átomo negado)")
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("2️⃣  Ejemplo paso a paso")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    
    P = predicate("P")
    Q = predicate("Q")
    R = predicate("R")
    
    φ = (P([]) ∧ Q([])) → R([])
    println("Fórmula original: ", φ)
    println()
    
    println("Paso 1: Eliminar implicaciones (A → B ≡ !A ∨ B)")
    step1 = remove_imp(φ)
    println("  Resultado: ", step1)
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("Paso 2: Mover negaciones hacia dentro (De Morgan)")
    step2 = move_!_in(step1)
    println("  Resultado: ", step2)
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("Paso 3: Aplicar distributividad")
    step3 = to_CNF(φ)
    println("  Resultado: ", step3)
    println()
    println("✅ Esta es la Forma Normal Conjuntiva!")
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("3️⃣  Ahora prueba tú")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("Intenta convertir estas fórmulas a CNF:")
    println()
    println("  1. φ1 = parse_formula(\"P ∨ (Q ∧ R)\")")
    println("     to_CNF(φ1)")
    println()
    println("  2. φ2 = parse_formula(\"(P → Q) ∧ (Q → R)\")")
    println("     to_CNF(φ2)")
    println()
    println("  3. φ3 = parse_formula(\"!(P ∧ Q) ∨ R\")")
    println("     to_CNF(φ3)")
    println()
    println("💡 RECUERDA: La función principal es to_CNF(φ)")
    println()
    println("📚 Para más información: help(:cnf)")
    println("🎮 Para ver ejemplos ejecutables: demo(:cnf)")
end

function tutorial_tableaux()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║          🎓 Tutorial: Tableaux Semánticos                      ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("1️⃣  ¿Qué son los tableaux?")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("Los tableaux semánticos construyen un árbol buscando:")
    println("  ✓ Contradicciones (φ y !φ juntos)")
    println("  ✓ Ramas cerradas → fórmula insatisfacible")
    println("  ✓ Ramas abiertas → posibles modelos")
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("2️⃣  Ejemplo: Verificar contradicción")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    
    P = predicate("P")
    φ = P([]) ∧ !P([])
    
    println("Fórmula: ", φ)
    println()
    println("Construyendo tableau...")
    
    result = TS_SAT(φ)
    println("Resultado: ", result)
    println()
    
    if result == :UNSAT
        println("✅ La fórmula es INSATISFACIBLE (contradicción)")
    end
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("3️⃣  Ejemplo: Extraer modelo")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    
    x = var("x")
    P = predicate("P")
    ψ = ∃("x", P([x]))
    
    println("Fórmula: ", ψ)
    println()
    println("Construyendo tableau y extrayendo modelo...")
    println()
    
    t = TS_solve(ψ)
    m = one_model(t)
    
    if !isnothing(m)
        println("✅ Modelo encontrado:")
        print_model(m)
    end
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("4️⃣  Funciones principales")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("  TS_SAT(φ)      → ¿Satisfacible?")
    println("  TS_VALID(φ)    → ¿Válida (tautología)?")
    println("  TS_solve(φ)    → Construye tableau completo")
    println("  one_model(t)   → Extrae un modelo")
    println("  all_models(t)  → Extrae todos los modelos")
    println()
    println("📚 Para más información: help(:tableaux)")
    println("🎮 Para ver ejemplos ejecutables: demo(:tableaux)")
end

function tutorial_resolution()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║          🎓 Tutorial: Método de Resolución                     ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("1️⃣  Principio de resolución")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("Regla de resolución:")
    println("  Si tenemos: P ∨ C₁  y  !P ∨ C₂")
    println("  Podemos derivar: C₁ ∨ C₂  (resolvente)")
    println()
    println("Objetivo: Derivar la cláusula vacía □ → INSATISFACIBLE")
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("2️⃣  Ejemplo: Verificar argumento")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("Argumento:")
    println("  Premisa 1: Todos los humanos son mortales")
    println("  Premisa 2: Sócrates es humano")
    println("  Conclusión: Sócrates es mortal")
    println()
    
    H = predicate("H")  # Humano
    M = predicate("M")  # Mortal
    s = const_("Sócrates")
    x = var("x")
    
    premises = [
        ∀("x", H([x]) → M([x])),
        H([s])
    ]
    conclusion = M([s])
    
    println("En lógica:")
    println("  ∀x (H(x) → M(x))")
    println("  H(Sócrates)")
    println("  ⊢ M(Sócrates)")
    println()
    
    println("Verificando...")
    result = verify_argument(premises, conclusion)
    
    println()
    if result[:valid]
        println("✅ Argumento VÁLIDO")
        println("   Pasos de resolución: ", result[:resolution_steps])
    end
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("3️⃣  Funciones principales")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("  RES_SAT(φ)           → ¿Satisfacible?")
    println("  RES_VALID(φ)         → ¿Válida?")
    println("  RES_LC(Γ, φ)         → ¿Γ ⊨ φ?")
    println("  verify_argument(Γ, φ) → Verifica argumento")
    println("  proof_of_insat_graph(φ) → Visualiza prueba")
    println()
    println("📚 Para más información: help(:resolution)")
    println("🎮 Para ver ejemplos ejecutables: demo(:resolution)")
end

function tutorial_unification()
    println("╔════════════════════════════════════════════════════════════════╗")
    println("║          🎓 Tutorial: Unificación (UMG)                        ║")
    println("╚════════════════════════════════════════════════════════════════╝")
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("1️⃣  ¿Qué es unificación?")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("Encontrar una sustitución σ tal que:")
    println("  σ(t₁) = σ(t₂)")
    println()
    println("UMG = Unificador Más General (más simple posible)")
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("2️⃣  Ejemplo exitoso")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    
    t1 = func("f", [var("x"), const_("a")])
    t2 = func("f", [const_("b"), var("y")])
    
    println("Término 1: ", t1)
    println("Término 2: ", t2)
    println()
    println("Buscando UMG...")
    
    σ = UMG(t1, t2)
    
    if !isnothing(σ)
        println("✅ Unificables!")
        println("   UMG: ", σ)
        println()
        println("   Aplicando:")
        println("   σ(", t1, ") = ", apply_substitution(t1, σ))
        println("   σ(", t2, ") = ", apply_substitution(t2, σ))
    end
    println()
    
    print("▶ Presiona ENTER para continuar...")
    readline()
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("3️⃣  Ejemplo fallido: Occurs check")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    
    t3 = var("x")
    t4 = func("f", [var("x")])
    
    println("Término 1: ", t3)
    println("Término 2: ", t4)
    println()
    println("Buscando UMG...")
    
    σ2 = UMG(t3, t4)
    
    if isnothing(σ2)
        println("❌ NO unificables")
        println("   Razón: x aparece en f(x) (occurs check)")
        println("   No hay sustitución finita que los iguale")
    end
    println()
    
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println("4️⃣  Función principal")
    println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    println()
    println("  UMG(t1, t2)              → Unificador Más General")
    println("  apply_substitution(t, σ) → Aplica sustitución")
    println()
    println("📚 Para más información: help(:unification)")
    println("🎮 Para ver ejemplos ejecutables: examples(:UMG)")
end
