"""
Cheatsheets y ayuda rápida por categorías
"""

function show_general_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                   FirstOrderLogic.jl - Ayuda                   ║
╚════════════════════════════════════════════════════════════════╝

📚 CATEGORÍAS PRINCIPALES:
  help(:syntax)         - Sintaxis para crear fórmulas
  help(:normalforms)    - Formas normales
  help(:algorithms)     - Algoritmos de decisión
  help(:unification)    - Unificación
  help(:models)         - L-estructuras y modelos
  help(:visualization)  - Visualización

🎓 TUTORIALES INTERACTIVOS:
  tutorial(:cnf)        - Forma Normal Conjuntiva
  tutorial(:tableaux)   - Tableaux semánticos
  tutorial(:resolution) - Método de resolución

🎮 DEMOS CON EJEMPLOS:
  demo(:cnf)           - Ejemplos de CNF
  demo(:tableaux)      - Ejemplos de tableaux
  demo(:resolution)    - Ejemplos de resolución

📋 EJEMPLOS DE USO:
  examples(:to_cnf)    - Ejemplos de to_cnf
  examples(:tableaux)  - Ejemplos de tableaux

💡 CHEATSHEET RÁPIDO:
  cheatsheet()         - Referencia completa
  cheatsheet(:syntax)  - Solo sintaxis
""")
end

function show_syntax_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                  SINTAXIS - Crear Fórmulas                     ║
╚════════════════════════════════════════════════════════════════╝

✏️  TÉRMINOS:
  var("x")                    - Variable
  const_("a")                 - Constante
  func("f", [var("x")])       - Función

  Shortcuts:
  vars("x", "y", "z")         - Múltiples variables
  constants("a", "b")         - Múltiples constantes

✏️  PREDICADOS:
  pred("P", [var("x")])       - Predicado con términos
  predicate("Q")([t1, t2])    - Wrapper parametrizable

✏️  CONECTIVAS LÓGICAS:
  !φ, -φ                      - Negación (¬)
  φ & ψ                       - Conjunción (∧)
  φ | ψ                       - Disyunción (∨)
  φ > ψ                       - Implicación (→)
  φ ~ ψ                       - Bicondicional (↔)

✏️  CUANTIFICADORES:
  ∀(x, φ)                     - Universal
  ∃(x, φ)                     - Existencial

📝 EJEMPLO COMPLETO:
  x, y = vars("x", "y")
  P, Q = predicates("P", "Q")
  
  φ = ∀(x, P(x) → ∃(y, Q(x, y))))
  
  # Formula: ∀x (P(x) → ∃y Q(x,y))

🔧 PARSING:
  parse_formula("∃x (P(x) ∧ Q(x))")

💡 TIP: usa `examples(:syntax)` para ver más ejemplos
""")
end

function show_normalforms_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                      FORMAS NORMALES                           ║
╚════════════════════════════════════════════════════════════════╝

🔄 TRANSFORMACIONES:

  to_Px(φ)           Forma Prenex
                     (Cuantificadores al inicio)

  to_Sk(φ)           Skolemización
                     (Elimina ∃, crea funciones de Skolem)

  to_cnf(φ)          Forma Normal Conjuntiva
                     (Conjunción de disyunciones)

  to_clauses(φ)      Conjunto de cláusulas
                     (Para resolución)

🔧 FUNCIONES AUXILIARES:

  remove_imp(φ)      Elimina → y ↔
  move_!_in(φ)       Mueve negaciones hacia dentro
  rename_vars(φ)     Renombra variables ligadas
  substitute_var(φ, x, t)  Sustituye variable por término

📊 PIPELINE TÍPICO:
  φ original
    ↓ remove_imp
  sin implicaciones
    ↓ move_!_in
  NNF
    ↓ to_Px
  Forma Prenex
    ↓ to_Sk
  Forma de Skolem
    ↓ to_cnf
  CNF (cláusulas)

💡 TIP: `tutorial(:cnf)` para aprender paso a paso
""")
end

function show_algorithms_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                  ALGORITMOS DE DECISIÓN                        ║
╚════════════════════════════════════════════════════════════════╝

🌳 TABLEAUX SEMÁNTICOS:
  TS_SAT(φ)          - ¿Es satisfacible?
  TS_VALID(φ)        - ¿Es válida (tautología)?
  TS_solve(φ)        - Construye tableau completo
  
  one_model(t)       - Extrae un modelo
  all_models(t)      - Extrae todos los modelos

🔗 RESOLUCIÓN:
  RES_SAT(φ)         - ¿Es satisfacible?
  RES_VALID(φ)       - ¿Es válida?
  RES_LC(Γ, φ)       - ¿Γ ⊨ φ? (consecuencia lógica)
  
  verify_argument(Γ, φ)  - Verifica argumento
  RES_FOL_with_tracking(clauses)  - Con tracking paso a paso

🌐 HERBRAND:
  H_Un(φ, depth)     - Universo de Herbrand (profundidad)
  H_Ex(φ, depth)     - Extensión de Herbrand
  herbrand_structure(φ, d)  - L-estructura de Herbrand

📊 COMPARACIÓN:
                    Tableaux    Resolution    Herbrand
  ─────────────────────────────────────────────────────
  Intuitivo           ✓✓          ✓            ✓
  Modelos             ✓✓          ✗            ✓✓
  Eficiencia          ✓           ✓✓           ✗
  Didáctico           ✓✓          ✓            ✓

💡 TIP: Usa `demo(:tableaux)` o `demo(:resolution)` para ejemplos
""")
end

function show_unification_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                        UNIFICACIÓN                             ║
╚════════════════════════════════════════════════════════════════╝

🔧 FUNCIÓN PRINCIPAL:
  UMG(t1, t2)        Unificador Más General

  Retorna:
    - Substitution si unificables
    - nothing si NO unificables

📝 TIPO: Substitution
  .bindings          Dict{String, Term}

🔄 APLICAR SUSTITUCIÓN:
  apply_substitution(t, σ)   - Aplica σ a término t
  apply_substitution(φ, σ)   - Aplica σ a fórmula φ

📋 EJEMPLOS:
  # Unificación exitosa
  t1 = f(x,a)
  t2 = f(b,y)
  σ = UMG(t1, t2)
  # σ = {x ↦ b, y ↦ a}

  # No unificables
  t3 = f(x)
  t4 = g(x)
  UMG(t3, t4) # nothing (símbolos diferentes)

  # Occurs check
  t5 = x
  t6 = f(x)
  UMG(t5, t6) # nothing (x aparece en f(x))

⚙️  ALGORITMO (Robinson):
  1. Si t1 == t2 → identidad
  2. Si t1 es variable → {t1 ↦ t2} (con occurs check)
  3. Si t2 es variable → {t2 ↦ t1} (con occurs check)
  4. Si f(...) y f(...) → símbolos iguales, unificar args

💡 TIP: `examples(:UMG)` para más ejemplos
""")
end

function show_models_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                  L-ESTRUCTURAS Y MODELOS                       ║
╚════════════════════════════════════════════════════════════════╝

🏗️  CREAR L-ESTRUCTURA:
  LStructure(
    domain,           # Vector de elementos
    constants,        # Dict{String, elemento}
    predicates,       # Dict{String, Function}
    functions         # Dict{String, Function}
  )

✅ VALIDACIÓN:
  validate(ls)      - Valida estructura completa
  is_model_of(ls, φ) - ¿ls es modelo de φ?

🔍 EVALUACIÓN:
  eval_term(t, ls, env)     - Evalúa término
  eval_formula(φ, ls, env)  - Evalúa fórmula

📊 VISUALIZACIÓN:
  show_LS(ls)       - Muestra estructura
  print_LS(ls)      - Imprime detalles

🌐 DESDE HERBRAND:
  herbrand_structure(φ, depth)
  to_LS(model)      - Convierte modelo a L-estructura

📝 EJEMPLO:
  # Dominio: {1, 2, 3}
  ls = LStructure(
    [1, 2, 3],
    Dict("a" => 1),
    Dict("P" => x -> x > 1),
    Dict("f" => x -> x + 1)
  )
  
  φ = parse_formula("P(f(a))")
  is_model_of(ls, φ)  # true (P(f(1)) = P(2) = true)

💡 TIP: `examples(:models)` para más ejemplos
""")
end

function show_visualization_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                      VISUALIZACIÓN                             ║
╚════════════════════════════════════════════════════════════════╝

📊 GRAPHVIZ (requiere instalación):
  to_dot(x)         - Genera código DOT
  to_file(x)        - Genera y abre archivo

🌳 TABLEAUX:
  t = TS_solve(φ)
  to_dot(t)         - Código DOT del árbol
  to_file(t)        - Visualiza tableau

🔗 RESOLUCIÓN:
  history = RES_FOL_with_tracking(clauses)
  to_dot(history)   - Código DOT del grafo
  to_file(history)  - Visualiza resolución
  
  proof_of_insat_text(φ)   - Prueba en texto
  proof_of_insat_graph(φ)  - Prueba en grafo

📝 TEXTO:
  print_TS_FOL(t)           - Tableau básico
  print_TS_FOL_verbose(t)   - Tableau detallado
  print_model(m)            - Modelo extraído

📋 EJEMPLO:
  # Visualizar tableau
  φ = parse_formula("∀x (P(x) → Q(x))")
  t = TS_solve(!φ)
  to_file(t, save_path="tableau.html")
  
  # Visualizar resolución
  proof_of_insat_graph(parse_formula("P ∧ !P"))

💡 NOTA: Requiere GraphvizDotLang.jl instalado
""")
end

function show_cheatsheet(category::Symbol)
    if category == :all || category == :syntax
        println("┌────────────────────────────────────────────────────────────────┐")
        println("│                      📄 SINTAXIS                               │")
        println("└────────────────────────────────────────────────────────────────┘")
        println("  Términos:      var(\"x\"), const_(\"a\"), func(\"f\", [t1, t2])")
        println("  Predicados:    pred(\"P\", [t1, t2])")
        println("  Negación:      !φ")
        println("  Conjunción:    φ ∧ ψ")
        println("  Disyunción:    φ ∨ ψ")
        println("  Implicación:   φ → ψ")
        println("  Bicondicional: iff(φ, ψ)")
        println("  Universal:     ∀(\"x\", φ)")
        println("  Existencial:   ∃(\"x\", φ)")
        println("  Parsing:       parse_formula(\"∀x P(x)\")")
        println()
    end
    
    if category == :all || category == :normalforms
        println("┌────────────────────────────────────────────────────────────────┐")
        println("│                   🔄 FORMAS NORMALES                           │")
        println("└────────────────────────────────────────────────────────────────┘")
        println("  remove_imp(φ)    - Elimina implicaciones")
        println("  move_!_in(φ)     - Forma Normal Negativa")
        println("  to_Px(φ)         - Forma Prenex")
        println("  to_Sk(φ)         - Skolemización")
        println("  to_cnf(φ)        - Forma Normal Conjuntiva")
        println("  to_clauses(φ)    - Conjunto de cláusulas")
        println("  rename_vars(φ)   - Renombra variables")
        println()
    end
    
    if category == :all || category == :algorithms
        println("┌────────────────────────────────────────────────────────────────┐")
        println("│                  🔧 ALGORITMOS                                 │")
        println("└────────────────────────────────────────────────────────────────┘")
        println("  TABLEAUX:")
        println("    TS_SAT(φ), TS_VALID(φ), TS_solve(φ)")
        println("    one_model(t), all_models(t)")
        println()
        println("  RESOLUCIÓN:")
        println("    RES_SAT(φ), RES_VALID(φ), RES_LC(Γ, φ)")
        println("    verify_argument(Γ, φ)")
        println("    RES_FOL_with_tracking(clauses)")
        println()
        println("  HERBRAND:")
        println("    H_Un(φ, depth), H_Ex(φ, depth)")
        println("    herbrand_structure(φ, depth)")
        println()
        println("  UNIFICACIÓN:")
        println("    UMG(t1, t2), apply_substitution(t, σ)")
        println()
    end
end

# Ayuda específica para temas comunes

function show_cnf_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║         FORMA NORMAL CONJUNTIVA (CNF)                          ║
╚════════════════════════════════════════════════════════════════╝

📖 DEFINICIÓN:
  Una fórmula está en CNF si es una conjunción de disyunciones
  de literales: (L₁ ∨ ... ∨ Lₙ) ∧ ... ∧ (M₁ ∨ ... ∨ Mₘ)

🔧 FUNCIÓN:
  to_cnf(φ)  - Convierte φ a CNF

📊 ALGORITMO:
  1. Elimina → y ↔
  2. Mueve ¬ hacia dentro (NNF)
  3. Aplica distributividad: P ∨ (Q ∧ R) ≡ (P ∨ Q) ∧ (P ∨ R)

📝 EJEMPLOS:
  φ1 = parse_formula("P ∨ Q")              → Ya en CNF
  φ2 = parse_formula("(P ∧ Q) → R")        → (!P ∨ !Q ∨ R)
  φ3 = parse_formula("P ∨ (Q ∧ R)")        → (P ∨ Q) ∧ (P ∨ R)

🎯 USO:
  Necesario para método de resolución

💡 VER TAMBIÉN:
  - to_clauses(φ)  - Convierte a cláusulas para resolución
  - tutorial(:cnf) - Tutorial paso a paso
  - demo(:cnf)     - Ejemplos ejecutables
""")
end

function show_tableaux_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║              TABLEAUX SEMÁNTICOS                               ║
╚════════════════════════════════════════════════════════════════╝

📖 MÉTODO:
  Construye un árbol buscando contradicciones
  - Rama cerrada (✗): contiene φ y !φ
  - Rama abierta (✓): posible modelo
  - Árbol cerrado: fórmula insatisfacible

🔧 FUNCIONES PRINCIPALES:
  TS_SAT(φ)     - ¿Es satisfacible? → :SAT / :UNSAT
  TS_VALID(φ)   - ¿Es válida? → :VALID / :INVALID  
  TS_solve(φ)   - Construye tableau completo

📊 MODELOS:
  one_model(t)  - Extrae un modelo de rama abierta
  all_models(t) - Extrae todos los modelos
  to_LS(m)      - Convierte a L-estructura

📝 EJEMPLO:
  # Verificar validez
  φ = parse_formula("∀x (P(x) → P(x))")
  TS_VALID(φ)  # :VALID
  
  # Construir tableau
  t = TS_solve(!φ)
  print_TS_FOL(t)
  
  # Extraer modelo
  ψ = parse_formula("∃x P(x)")
  t2 = TS_solve(ψ)
  m = one_model(t2)
  print_model(m)

🎨 VISUALIZACIÓN:
  to_file(t)    - Visualiza árbol con Graphviz

💡 VER TAMBIÉN:
  - tutorial(:tableaux) - Tutorial interactivo
  - demo(:tableaux)     - Ejemplos ejecutables
""")
end

function show_resolution_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                  MÉTODO DE RESOLUCIÓN                          ║
╚════════════════════════════════════════════════════════════════╝

📖 MÉTODO:
  Refutación por resolución en FOL
  - Convierte a CNF (cláusulas)
  - Aplica regla de resolución: P∨C₁, !P∨C₂ ⊢ C₁∨C₂
  - Si deriva cláusula vacía □ → insatisfacible

🔧 FUNCIONES:
  RES_SAT(φ)         - ¿Es satisfacible?
  RES_VALID(φ)       - ¿Es válida?
  RES_LC(Γ, φ)       - ¿Γ ⊨ φ?
  verify_argument(Γ, φ) - Verifica argumento

📊 CON TRACKING:
  RES_FOL_with_tracking(clauses)
  proof_of_insat_text(φ)   - Prueba en texto
  proof_of_insat_graph(φ)  - Prueba visualizada

📝 EJEMPLO:
  # Verificar argumento
  Γ = [parse_formula("∀x (P(x) → Q(x))"), parse_formula("P(a)")]
  φ = parse_formula("Q(a)")
  verify_argument(Γ, φ)
  
  # Con tracking visual
  ψ = parse_formula("P ∧ !P")
  proof_of_insat_graph(ψ)

🎯 VENTAJAS:
  - Muy eficiente
  - Automatizable
  - Base de ATP (Automated Theorem Proving)

💡 VER TAMBIÉN:
  - to_clauses(φ)       - Convierte a cláusulas
  - tutorial(:resolution) - Tutorial paso a paso
  - demo(:resolution)   - Ejemplos ejecutables
""")
end

function show_herbrand_help()
    println("""
╔════════════════════════════════════════════════════════════════╗
║                  UNIVERSO DE HERBRAND                          ║
╚════════════════════════════════════════════════════════════════╝

📖 TEOREMA DE HERBRAND:
  Toda fórmula satisfacible tiene modelo de Herbrand
  Universo construido con constantes y funciones de la fórmula

🔧 FUNCIONES:
  H_Un(φ, depth)    - Universo de Herbrand (prof. limitada)
  H_Ex(φ, depth)    - Extensión de Herbrand
  herbrand_structure(φ, d) - L-estructura de Herbrand

📊 CONSTRUCCIÓN:
  depth=0: Constantes de φ (o {c₀} si no hay)
  depth=1: + aplicar funciones 1 vez
  depth=2: + aplicar funciones 2 veces
  ...

📝 EJEMPLO:
  φ = parse_formula("∃x P(f(x))")
  
  # Universo profundidad 2
  u = H_Un(φ, 2)
  # {c₀, f(c₀), f(f(c₀))}
  
  # Extensión (ground instances)
  ex = H_Ex(φ, 2)
  # {P(f(c₀)), P(f(f(c₀))), ...}
  
  # L-estructura
  ls = herbrand_structure(φ, 2)
  show_LS(ls)

⚠️  ADVERTENCIA:
  Profundidad alta → explosión combinatoria

💡 VER TAMBIÉN:
  - demo(:herbrand)     - Ejemplos ejecutables
  - extract_constants   - Extrae constantes
  - extract_functions   - Extrae funciones
""")
end
