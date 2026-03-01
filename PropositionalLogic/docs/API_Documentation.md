# PropositionalLogic.jl - API Documentation & Headers

## Información General

**Autor:** Fernando Sancho Caparrini  
**Curso:** Lógica Informática 2025-2026  
**Universidad:** Universidad de Sevilla  
**Versión:** 1.0  

## Descripción

Librería completa de Lógica Proposicional diseñada para enseñanza y aplicación práctica. Implementa los algoritmos fundamentales de decisión y análisis semántico con estructura modular y documentación educativa.

## Estructura del Proyecto

```
PropositionalLogic/
├── src/
│   ├── PropositionalLogic.jl          # Módulo principal
│   ├── Core/                          # Funcionalidad básica
│   │   ├── Types.jl                   # Jerarquía de tipos
│   │   ├── Evaluation.jl              # Sistema de evaluación
│   │   └── Display.jl                 # Visualización
│   ├── Analysis/                      # Análisis semántico
│   │   ├── TruthTables.jl            # Tablas de verdad
│   │   ├── Properties.jl             # Propiedades semánticas
│   │   └── NormalForms.jl            # Formas normales
│   └── Algorithms/                    # Algoritmos de decisión
│       ├── DPLL.jl                   # Davis-Putnam-Logemann-Loveland
│       ├── Tableaux.jl               # Tableros semánticos
│       └── Resolution.jl             # Método de resolución
```

---

## 🔧 CORE MODULES

### Core.Types - Sistema de Tipos Base

**Propósito:** Define la jerarquía de tipos para representar fórmulas proposicionales con sintaxis natural y operadores sobrecargados.

#### Tipos Principales

```julia
# Tipo abstracto base
abstract type FormulaPL end

# Tipos concretos para fórmulas
struct Var_PL <: FormulaPL
    name::String
end

struct Neg_PL <: FormulaPL
    sub::FormulaPL
end

struct And_PL <: FormulaPL
    left::FormulaPL
    right::FormulaPL
end

struct Or_PL <: FormulaPL
    left::FormulaPL
    right::FormulaPL
end

struct Imp_PL <: FormulaPL
    left::FormulaPL
    right::FormulaPL
end

struct Iff_PL <: FormulaPL
    left::FormulaPL
    right::FormulaPL
end

struct Top_PL <: FormulaPL end      # Constante verdad ⊤
struct Bottom_PL <: FormulaPL end   # Constante falsedad ⊥
```

#### Constructores y Operadores

```julia
# Constructores de variables
vars(names...)                      # Crear múltiples variables
vars(["p", "q", "r"])              # Desde vector de nombres

# Constantes lógicas
⊤ = Top_PL()                       # Verdad
⊥ = Bottom_PL()                    # Falsedad

# Operadores sobrecargados (sintaxis natural)
!(f::FormulaPL)                    # Negación: !p
&(f1::FormulaPL, f2::FormulaPL)    # Conjunción: p & q
|(f1::FormulaPL, f2::FormulaPL)    # Disyunción: p | q
>(f1::FormulaPL, f2::FormulaPL)    # Implicación: p > q
~(f1::FormulaPL, f2::FormulaPL)    # Bicondicional: p ~ q

# Operadores alternativos
⋀(fs::FormulaPL...)               # Conjunción múltiple
⋁(fs::FormulaPL...)               # Disyunción múltiple

# Macro para construcción avanzada
@formula "((p & q) > r) | (!p ~ q)"
```

#### Funciones Auxiliares

```julia
vars_of(f::FormulaPL)              # Extraer variables de una fórmula
subformulas(f::FormulaPL)          # Obtener todas las subfórmulas
complexity(f::FormulaPL)           # Calcular complejidad sintáctica
```

---

### Core.Evaluation - Sistema de Evaluación

**Propósito:** Implementa la evaluación semántica de fórmulas bajo valoraciones específicas.

#### Tipos de Valoración

```julia
# Valoración como función de variables a valores booleanos
const Valuation = Dict{Var_PL, Bool}

# Literales para formas normales
struct Literal
    variable::Var_PL
    positive::Bool                  # true = p, false = ¬p
end

# Cláusulas (disyunciones de literales)
struct Clause
    literals::Set{Literal}
end

# Cubos (conjunciones de literales)
struct Cube
    literals::Set{Literal}
end
```

#### Funciones de Evaluación

```julia
# Evaluación principal
evaluate(f::FormulaPL, val::Valuation) -> Bool

# Evaluación con sintaxis funcional
(val::Valuation)(f::FormulaPL) -> Bool

# Construcción de valoraciones
valuation_from_assignment(vars, values)
valuation_from_binary(vars, binary_string)

# Utilidades para literales
complement(l::Literal) -> Literal
are_complementary(l1::Literal, l2::Literal) -> Bool
```

---

### Core.Display - Sistema de Visualización

**Propósito:** Proporciona representaciones legibles y formateo avanzado de fórmulas.

```julia
# Representación en strings
show(io::IO, f::FormulaPL)         # Formato estándar
latex_string(f::FormulaPL)         # Formato LaTeX
unicode_string(f::FormulaPL)       # Símbolos Unicode

# Árbol de formación
formation_tree(f::FormulaPL)       # Árbol sintáctico
print_tree(f::FormulaPL)          # Visualización del árbol

# Formateo de valoraciones
show_valuation(val::Valuation)     # Formato legible
```

---

## 📊 ANALYSIS MODULES

### Analysis.TruthTables - Tablas de Verdad

**Propósito:** Generación y análisis de tablas de verdad, búsqueda de modelos y contramodelos.

#### Funciones Principales

```julia
# Generación de tablas de verdad
truth_table(f::FormulaPL) -> DataFrame
truth_table(fs::Vector{FormulaPL}) -> DataFrame

# Búsqueda de modelos
models(f::FormulaPL) -> Vector{Valuation}
countermodels(f::FormulaPL) -> Vector{Valuation}

# Generación de valoraciones
all_valuations_for(vars::Vector{Var_PL}) -> Vector{Valuation}

# Visualización
print_table(table::DataFrame)
export_table_latex(table::DataFrame)
```

#### Casos de Uso

```julia
# Análisis completo
p, q = vars("p", "q")
formula = (p > q) & p
table = truth_table(formula)
print_table(table)

# Búsqueda de modelos específicos
satisfying_models = models(formula)
refuting_models = countermodels(formula)
```

---

### Analysis.Properties - Propiedades Semánticas

**Propósito:** Verificación de propiedades fundamentales y relaciones lógicas.

#### Propiedades Básicas

```julia
# Propiedades semánticas fundamentales
TAUT(f::FormulaPL) -> Bool         # ¿Es tautología?
SAT(f::FormulaPL) -> Bool          # ¿Es satisfactible?
UNSAT(f::FormulaPL) -> Bool        # ¿Es insatisfactible?

# Equivalencia lógica
EQUIV(f1::FormulaPL, f2::FormulaPL) -> Bool
EQUIV_models(f1::FormulaPL, f2::FormulaPL) -> Bool
```

#### Consecuencia Lógica

```julia
# Múltiples métodos para verificar Γ ⊨ α
LC_Def(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool     # Definición semántica
LC_TAUT(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool    # Reducción a tautología
LC_RA(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool      # Reducción al absurdo

# Análisis de argumentos
analyze_argument(premises, conclusion)
```

#### Simplificación

```julia
# Simplificación con constantes lógicas
simplify_constants(f::FormulaPL) -> FormulaPL

# Detección de casos triviales
is_trivial_tautology(f::FormulaPL) -> Bool
is_trivial_contradiction(f::FormulaPL) -> Bool
```

---

### Analysis.NormalForms - Formas Normales

**Propósito:** Transformaciones a formas normales estándar (CNF, DNF) y manipulación de estructuras clausales.

#### Transformaciones Principales

```julia
# Formas normales estándar
to_CNF(f::FormulaPL) -> FormulaPL          # Forma Normal Conjuntiva
to_DNF(f::FormulaPL) -> FormulaPL          # Forma Normal Disyuntiva

# Pasos intermedios
remove_imp(f::FormulaPL) -> FormulaPL      # Eliminar implicaciones
move_negation_in(f::FormulaPL) -> FormulaPL # Ley de De Morgan
dist_and_or(f::FormulaPL) -> FormulaPL     # Distributividad ∧ sobre ∨
dist_or_and(f::FormulaPL) -> FormulaPL     # Distributividad ∨ sobre ∧
```

#### Manipulación de Cláusulas

```julia
# Extracción de estructuras
extract_clauses_from_CNF(f::FormulaPL) -> Set{Clause}
extract_cubes_from_DNF(f::FormulaPL) -> Set{Cube}

# Construcción desde estructuras
build_CNF_from_clauses(clauses::Set{Clause}) -> FormulaPL
build_DNF_from_cubes(cubes::Set{Cube}) -> FormulaPL

# Análisis de cláusulas
is_tautological(c::Clause) -> Bool         # Cláusula siempre verdadera
is_contradictory(c::Clause) -> Bool        # Cláusula siempre falsa
```

#### Utilidades para Literales

```julia
# Construcción y manipulación
formula_from_literal(l::Literal) -> FormulaPL
literal_from_formula(f::FormulaPL) -> Union{Literal, Nothing}

# Relaciones entre literales
are_complementary(l1::Literal, l2::Literal) -> Bool
complement(l::Literal) -> Literal
```

---

## 🔍 ALGORITHM MODULES

### Algorithms.DPLL - Davis-Putnam-Logemann-Loveland

**Propósito:** Implementación completa del algoritmo DPLL para satisfactibilidad con técnicas de optimización.

#### API Principal

```julia
# Funciones de entrada principales
DPLL_SAT(f::FormulaPL; verbose::Bool = false) -> Bool
DPLL_solve(f::FormulaPL; verbose::Bool = false) -> Union{Valuation, Nothing}
DPLL_LC(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Bool
```

#### Conversión a Forma Clausal

```julia
# Preparación para DPLL
to_CF(f::FormulaPL) -> Vector{Clause}      # Conversión a forma clausal
clean_CF(clauses::Vector{Clause}) -> Vector{Clause}  # Limpieza y optimización
```

#### Técnicas de Optimización

```julia
# Propagación unitaria
unit_clauses(clauses::Vector{Clause}) -> Vector{Literal}
apply_val(clauses::Vector{Clause}, val::Valuation) -> Vector{Clause}

# Eliminación de literales puros
pure_literals(clauses::Vector{Clause}) -> Vector{Literal}

# Algoritmo principal
DPLL(clauses::Vector{Clause}; verbose::Bool = false) -> Union{Valuation, Nothing}
```

#### Análisis y Debugging

```julia
# Información del proceso
show_dpll_trace(clauses::Vector{Clause})
dpll_statistics(clauses::Vector{Clause})

# Verificación de corrección
verify_dpll_result(original_formula::FormulaPL, result::Union{Valuation, Nothing})
```

---

### Algorithms.Tableaux - Tableros Semánticos

**Propósito:** Implementación del método de tableros semánticos para análisis sistemático de fórmulas.

#### Tipos y Estructuras

```julia
# Nodo del tablero semántico
struct TableauNode
    formulas::Set{FormulaPL}       # Fórmulas en el nodo
    valuation::Valuation           # Valoración parcial
    is_closed::Bool                # ¿Nodo cerrado?
    children::Vector{TableauNode}  # Nodos hijos
end
```

#### API Principal

```julia
# Construcción de tableros
build_TS(f::FormulaPL) -> TableauNode
TS_from_formula(f::FormulaPL) -> TableauNode

# Verificación usando tableros
TS_SAT(f::FormulaPL) -> Bool
TS_TAUT(f::FormulaPL) -> Bool
TS_solve(f::FormulaPL) -> Union{Valuation, Nothing}

# Visualización
print_TS(tableau::TableauNode)
export_TS_graphviz(tableau::TableauNode)
```

#### Reglas de Expansión

```julia
# Detección de tipos de fórmula
is_atomic(f::FormulaPL) -> Bool
has_contradiction(node::TableauNode) -> Bool

# Aplicación de reglas
apply_α(node::TableauNode, formula::FormulaPL) -> TableauNode    # Reglas α (no ramificantes)
apply_β(node::TableauNode, formula::FormulaPL) -> Vector{TableauNode}  # Reglas β (ramificantes)

# Clasificación de fórmulas
is_α_formula(f::FormulaPL) -> Bool
is_β_formula(f::FormulaPL) -> Bool
```

---

### Algorithms.Resolution - Método de Resolución

**Propósito:** Implementación del algoritmo de resolución para refutación automática.

#### API Principal

```julia
# Funciones de entrada
RES_SAT(f::FormulaPL; verbose::Bool = false) -> Bool
RES_TAUT(f::FormulaPL; verbose::Bool = false) -> Bool
RES_LC(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Bool
RES_solve(f::FormulaPL; verbose::Bool = false) -> Bool
```

#### Operaciones de Resolución

```julia
# Resolución básica
resolve(c1::Clause, c2::Clause) -> Union{Clause, Nothing}
find_complementary_pairs(c1::Clause, c2::Clause) -> Vector{Tuple{Literal, Literal}}

# Optimizaciones
is_subsumed(c1::Clause, c2::Clause) -> Bool
remove_subsumed(clauses::Vector{Clause}) -> Vector{Clause}
```

#### Conversión y Preparación

```julia
# Preparación para resolución
to_resolution_clauses(f::FormulaPL) -> Vector{Clause}

# Algoritmo principal
RES(clauses::Vector{Clause}; verbose::Bool = false) -> Bool
```

#### Trazabilidad y Análisis

```julia
# Información del proceso
show_resolution_trace(clauses::Vector{Clause})
resolution_statistics(clauses::Vector{Clause})

# Generación de pruebas
generate_resolution_proof(premises::Vector{FormulaPL}, conclusion::FormulaPL)
```

---

## 🚀 FUNCIONES DE ALTO NIVEL

### Análisis Completo

```julia
# Análisis exhaustivo con múltiples métodos
analyze(f::FormulaPL; verbose::Bool = false) -> Tuple{Bool, Bool}

# Comparación de rendimiento entre algoritmos
compare_algorithms(f::FormulaPL; iterations::Int = 1) -> Tuple

# Verificación de consecuencia lógica con múltiples métodos
verify_logical_consequence(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Tuple{Bool, Bool, Bool}
```

### Utilidades del Sistema

```julia
# Información del módulo
version()                          # Información de versión
help()                            # Ayuda general

# Configuración
set_display_mode(mode::Symbol)     # :unicode, :ascii, :latex
enable_verbose_mode(enable::Bool)
```

---

## 💡 EJEMPLOS DE USO

### Uso Básico

```julia
using PropositionalLogic

# Crear variables
p, q, r = vars("p", "q", "r")

# Construir fórmulas con sintaxis natural
formula1 = (p & q) > r
formula2 = (p > q) & (q > r) & p

# Análisis básico
println("¿Es tautología? ", TAUT(formula1))
println("¿Es satisfactible? ", SAT(formula2))

# Tabla de verdad
table = truth_table(formula1)
print_table(table)
```

### Análisis Completo

```julia
# Análisis exhaustivo
formula = (p > q) & (!q > !p)  # Contraposición
sat_result, taut_result = analyze(formula, verbose=true)

# Comparación de algoritmos
performance = compare_algorithms(formula, iterations=100)
```

### Consecuencia Lógica

```julia
# Verificar un argumento lógico
premises = [p > q, q > r, p]
conclusion = r

result1, result2, result3 = verify_logical_consequence(premises, conclusion, verbose=true)
```

### Trabajo con Formas Normales

```julia
# Transformaciones
original = (p > q) & (r ~ s)
cnf_form = to_CNF(original)
dnf_form = to_DNF(original)

# Extracción de cláusulas
clauses = extract_clauses_from_CNF(cnf_form)
```

### Algoritmos Específicos

```julia
# DPLL con traza detallada
model = DPLL_solve(formula, verbose=true)

# Tableros semánticos
tableau = build_TS(!formula)
print_TS(tableau)

# Resolución
proof_exists = RES_TAUT(formula, verbose=true)
```

---

## 🔧 EXTENSIONES Y PERSONALIZACIÓN

### Añadir Nuevos Tipos de Fórmula

```julia
# Definir nuevo tipo (ejemplo: XOR)
struct Xor_PL <: FormulaPL
    left::FormulaPL
    right::FormulaPL
end

# Implementar evaluación
function evaluate(f::Xor_PL, val::Valuation)
    return evaluate(f.left, val) ⊻ evaluate(f.right, val)
end

# Implementar visualización
Base.show(io::IO, f::Xor_PL) = print(io, "($(f.left) ⊕ $(f.right))")
```

### Nuevos Algoritmos

```julia
# Plantilla para nuevo algoritmo
module MyAlgorithm
    using ..Types, ..Evaluation
    
    function my_sat_solver(f::FormulaPL)
        # Implementación personalizada
        # ...
        return result
    end
    
    export my_sat_solver
end
```

---

## 📚 REFERENCIAS Y RECURSOS

### Documentación Académica
- Mendelson, E. "Mathematical Logic" (Capítulos 1-2)
- Shoenfield, J.R. "Mathematical Logic" (Capítulo 1)
- Van Dalen, D. "Logic and Structure" (Capítulos 1-3)

### Implementación Técnica
- Handbook of Satisfiability (DPLL y variantes)
- Handbook of Automated Reasoning (Resolución)
- Handbook of Tableaux Methods (Tableros semánticos)

### Recursos Online
- [Julia Documentation](https://docs.julialang.org/)
- [Propositional Logic (Stanford Encyclopedia)](https://plato.stanford.edu/entries/logic-propositional/)

---

## 🐛 DEBUGGING Y RESOLUCIÓN DE PROBLEMAS

### Problemas Comunes

1. **Fórmulas muy grandes**: Usar `verbose=false` y considerar algoritmos optimizados
2. **Memoria insuficiente**: Para más de 20 variables, considerar algoritmos probabilísticos
3. **Resultados inconsistentes**: Verificar que todos los algoritmos concuerden

### Herramientas de Debug

```julia
# Verificar estructura de fórmula
println("Variables: ", vars_of(formula))
println("Complejidad: ", complexity(formula))

# Verificar valoraciones
val = valuation_from_assignment([p, q], [true, false])
println("Evaluación: ", evaluate(formula, val))

# Comparar métodos
result_basic = SAT(formula)
result_dpll = DPLL_SAT(formula)
@assert result_basic == result_dpll "Inconsistencia detectada"
```

---

Esta documentación proporciona una visión completa de la API de PropositionalLogic.jl, incluyendo todas las funciones públicas, tipos de datos, ejemplos de uso y guías para extensión. La librería está diseñada para ser tanto educativa como práctica, proporcionando implementaciones claras de los algoritmos fundamentales de la lógica proposicional.
