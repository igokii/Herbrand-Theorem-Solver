module FirstOrderLogic

#=
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                  LÓGICA DE PRIMER ORDEN (First-Order Logic)                  ║
║                    Biblioteca completa para FOL en Julia                     ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝


ÍNDICE DE CONTENIDOS
════════════════════════════════════════════════════════════════════════════════

PARTE 1: NÚCLEO: TIPOS, CONSTRUCTORES Y OPERADORES
    1.1 Términos - Variables, constantes y funciones
    1.2 Fórmulas - Cuantificadores y conectivas lógicas
    1.3 Operadores proposicionales (¬, ∧, ∨, →, ↔)
    1.4 Cuantificadores (∀, ∃)
    1.5 Igualdad estructural para términos
    1.6 Hashing para estructuras
    1.7 Representación legible
    1.8 Constructores simples
    1.9 Wrappers parametrizables
    1.10 Constructores múltiples
    1.11 Parsing: Strings a fórmulas y Macros

PARTE 2: ANÁLISIS Y MANIPULACIÓN DE FÓRMULAS
    2.1 Subfórmulas y árbol de formación
    2.2 Variables Libres

PARTE 3: L-ESTRUCTURAS
    3.1 L-estructuras

PARTE 4: TABLEROS SEMÁNTICOS
    4.1 Estructuras y tipos para tableros
    4.2 Representación y visualización
    4.3 Funciones de alto nivel: SAT, VALID y solve
    4.4 Extracción y verificación de modelos

PARTE 5: FORMAS NORMALES
    5.1 Renombramiento de variables
    5.2 Forma Prenex
    5.3 Forma de Skolem
    5.4 Forma Normal Conjuntiva (CNF)
    5.5 Forma Clausal

PARTE 6: EXTENSIÓN DE HERBRAND
    6.1 Estructura para Herbrand
    6.2 Universo de Herbrand
    6.3 Extensión de Herbrand
    6.4 Instanciación de fórmulas (ground formulas)
    6.5 Representación
    6.6 Versiones para conjuntos y vectores de fórmulas
    6.7 L-estructuras y Extensiones de Herbrand

PARTE 7: UNIFICACIÓN: UMG

PARTE 8: RESOLUCIÓN
    8.1 Resolventes y Resolución
    8.2 Funciones de alto nivel: SAT, VALID, CONSECUENCIA LÓGICA
    8.3 Depuración y análisis paso a paso
    8.4 Resolución con tracking
      8.4.1 Estructuras para tracking
      8.4.2 Resolución con tracking
      8.4.3 Funciones para representación
      8.4.4 Pruebas por Refutación
    8.5 Representación Gráfica


════════════════════════════════════════════════════════════════════════════════
=#

# Importar GraphvizDotLang con alias (debe estar instalado)
#   se usa para la representación visual de tableaux y resolución 
import GraphvizDotLang as GVL


# ==================== INCLUSIÓN DE SUBMÓDULOS ====================

# Core modules (funcionalidad básica)
include("Core/Types.jl")
include("Core/Parser.jl") 
include("Core/Analysis.jl")
include("Core/LStructures.jl")
include("Core/State.jl")

# Algorithm modules (algoritmos de decisión)
# IMPORTANTE: Orden de dependencias
# - NormalForms: Funciones básicas como substitute_var
# - Unification: UMG
# - Tableaux: Usa NormalForms y Unification
include("Algorithms/NormalForms.jl")
include("Algorithms/Unification.jl")
include("Algorithms/Tableaux.jl")
include("Algorithms/Herbrand.jl")
include("Algorithms/Resolution.jl")

# Help system (sistema de ayuda interactivo)
include("Help/Help.jl")

# ==================== IMPORTACIÓN DE SUBMÓDULOS ====================

# Types: Importar todo lo exportado
import .Types: Term, Var_FOL, Const_FOL, Func_FOL
import .Types: FOLFormula, Predicate_FOL, NotFOL, AndFOL, OrFOL, ImpliesFOL, IffFOL
import .Types: Forall, Exists, FOLModel
import .Types: var, vars, const_, constants, func, function_, functions
import .Types: pred, predicate, predicates, PredicateWrapper, FunctionWrapper
import .Types: !, iff, ∀, ∃

# Parser
import .Parser: parse_formula, @parse

# Analysis
import .Analysis: free_vars, subformulas, formation_tree

# LStructures
import .LStructures: LStructure, eval_term, eval_formula, is_model_of, show_LS, validate
import .LStructures: validate_constants, validate_predicates, validate_functions

# State
import .State: reset_counters!, reset_var_rename_counter!, reset_skolem_counter!, reset_TS_constant_counter!

# NormalForms
import .NormalForms: substitute_var, rename_vars
import .NormalForms: remove_imp, move_!_in
import .NormalForms: to_Px, to_Sk, to_Sk_optimal
import .NormalForms: has_∃, is_Sk_form, remove_∀_prefix
import .NormalForms: to_cnf, to_clauses, prenex_forms, prenex_forms_sorted
import .NormalForms: extract_Q_with_branches, compute_Sk_aridity, get_same_branch_pairs
import .NormalForms: all_perms, filter_valid_perms, is_prefix, extract_matrix
import .NormalForms: Literal, Clause

# Unification
import .Unification: UMG, Substitution, apply_substitution

# Herbrand
import .Herbrand: HerbrandExtension, H_Un, H_Ex
import .Herbrand: extract_constants, extract_functions, extract_predicates
import .Herbrand: show_H_ex
import .Herbrand: herbrand_structure, print_LS

# Tableaux
import .Tableaux: TSNodeFOL, TS_FOL, TS_SAT, TS_VALID, TS_solve
import .Tableaux: print_TS_FOL, print_TS_FOL_verbose
import .Tableaux: print_formula_registry
import .Tableaux: is_ground_term, get_ground_terms, extract_ground_terms
import .Tableaux: FormulaInfo, FormulaRegistry, add_formula!
import .Tableaux: one_model, all_models, print_model, verify_model
import .Tableaux: to_LS

# Resolution  
import .Resolution: RES_FOL, RES_FOL_with_tracking, RESHistory, RESStep
import .Resolution: RES_VALID, RES_SAT, RES_LC
import .Resolution: verify_argument, verify_argument_detailed
import .Resolution: format_clause_for_display
import .Resolution: extract_proof_path, proof_of_insat_text, proof_of_insat_graph

# Help system
import .Help: help, tutorial, demo, examples, cheatsheet


# ════════════════════════════════════════════════════════════════════════════
# FUNCIONES CON DISPATCH MÚLTIPLE - Wrapper para métodos en diferentes módulos
# ════════════════════════════════════════════════════════════════════════════

"""
    to_dot(x; kwargs...)

Genera representación DOT para visualización con Graphviz.

# Métodos disponibles:
- `to_dot(::TSNodeFOL)` - Tableaux semánticos
- `to_dot(::RESHistory)` - Historial de resolución
- `to_dot(::FOLFormula)` - Fórmula como grafo de resolución
"""
function to_dot(x; kwargs...)
    if isa(x, TSNodeFOL)
        return Tableaux.to_dot(x; kwargs...)
    elseif isa(x, RESHistory)
        return Resolution.to_dot(x; kwargs...)
    elseif isa(x, FOLFormula)
        return Resolution.to_dot(x; kwargs...)
    else
        error("No hay método to_dot para tipo $(typeof(x))")
    end
end

"""
    to_file(x; kwargs...)

Genera archivo DOT y lo visualiza.

# Métodos disponibles:
- `to_file(::TSNodeFOL; save_path=nothing)` - Tableaux semánticos
- `to_file(::RESHistory; save_path=nothing)` - Historial de resolución  
- `to_file(::FOLFormula; save_path=nothing)` - Fórmula como grafo de resolución
"""
function to_file(x; kwargs...)
    if isa(x, TSNodeFOL)
        return Tableaux.to_file(x; kwargs...)
    elseif isa(x, RESHistory)
        return Resolution.to_file(x; kwargs...)
    elseif isa(x, FOLFormula)
        return Resolution.to_file(x; kwargs...)
    else
        error("No hay método to_file para tipo $(typeof(x))")
    end
end


# ════════════════════════════════════════════════════════════════════════════
# RE-EXPORTS - Organizados por funcionalidad
# ════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────
# 1. TIPOS BÁSICOS - Términos y Fórmulas
# ──────────────────────────────────────────────────────────────────────────
export Term, Var_FOL, Const_FOL, Func_FOL
export FOLFormula, Predicate_FOL, NotFOL, AndFOL, OrFOL, ImpliesFOL, IffFOL
export Forall, Exists
export Literal, Clause, Substitution

# ──────────────────────────────────────────────────────────────────────────
# 2. CONSTRUCTORES - Sintaxis amigable para crear términos y fórmulas
# ──────────────────────────────────────────────────────────────────────────
export var, vars, const_, constants, func, function_, functions
export pred, predicate, predicates
export PredicateWrapper, FunctionWrapper

# ──────────────────────────────────────────────────────────────────────────
# 3. OPERADORES LÓGICOS - Sintaxis simbólica
# ──────────────────────────────────────────────────────────────────────────
export !, iff, ∀, ∃

# ──────────────────────────────────────────────────────────────────────────
# 3.5 PARSING - Parseador de fórmulas matemáticas
# ──────────────────────────────────────────────────────────────────────────
export parse_formula, @parse

# ──────────────────────────────────────────────────────────────────────────
# 4. TRANSFORMACIONES DE FÓRMULAS - Manipulación y normalización
# ──────────────────────────────────────────────────────────────────────────
export free_vars, subformulas, formation_tree
export substitute_var, rename_vars, reset_var_rename_counter!
export remove_imp, move_!_in, move_Q_out
export to_Px, to_Sk, to_Sk_optimal
export reset_skolem_counter!, reset_TS_constant_counter!
export apply_substitution, has_∃, is_Sk_form, remove_∀_prefix
export to_cnf, to_clauses
export prenex_forms, prenex_forms_sorted
export extract_Q_with_branches, compute_Sk_aridity, get_same_branch_pairs
export all_perms, filter_valid_perms, is_prefix, extract_matrix

# ──────────────────────────────────────────────────────────────────────────
# 5. UNIFICACIÓN Y RESOLUCIÓN - Razonamiento automático
# ──────────────────────────────────────────────────────────────────────────
export UMG
export RES_FOL, RES_FOL_with_tracking, RESHistory, RESStep
export RES_VALID, RES_SAT, RES_LC
export verify_argument, verify_argument_detailed

# ──────────────────────────────────────────────────────────────────────────
# 6.5 EXTENSIÓN DE HERBRAND - Universo de Herbrand limitado por profundidad
# ──────────────────────────────────────────────────────────────────────────
export HerbrandExtension
export H_Un, H_Ex
export extract_constants, extract_functions, extract_predicates, extract_terms
export show_H_ex

# ──────────────────────────────────────────────────────────────────────────
# 7. TABLEAUX - Método de tableaux semánticos
# ──────────────────────────────────────────────────────────────────────────
export TSNodeFOL, TS_FOL
export TS_SAT, TS_VALID, TS_solve
export print_TS_FOL, print_TS_FOL_verbose
export print_formula_registry, to_dot, to_file
export is_ground_term, get_ground_terms, extract_ground_terms
export FormulaInfo, FormulaRegistry, add_formula!

# ──────────────────────────────────────────────────────────────────────────
# 8. MODELOS - Extracción y verificación de modelos
# ──────────────────────────────────────────────────────────────────────────
export FOLModel, one_model, all_models, print_model, verify_model
export TS_get_model, TS_get_all_models
export LStructure, eval_term, eval_formula, is_model_of, validate
export validate_constants, validate_predicates, validate_functions
export to_LS, herbrand_structure, print_LS, show_LS

# ──────────────────────────────────────────────────────────────────────────
# 9. VISUALIZACIÓN - Gráficos y representación visual
# ──────────────────────────────────────────────────────────────────────────
# Visualización de resolución
export format_clause_for_display
export extract_proof_path, proof_of_insat_text, proof_of_insat_graph
export to_dot, to_file  # Grafos DOT para resolución y TS

# ──────────────────────────────────────────────────────────────────────────
# 10. SISTEMA DE AYUDA - Ayuda interactiva en REPL
# ──────────────────────────────────────────────────────────────────────────
export help, tutorial, demo, examples, cheatsheet

export version


# ==================== INFORMACIÓN DEL MÓDULO ====================

"""
    version()

Muestra información sobre la versión y estructura del módulo.
"""
function version()
    println("FirstOrderLogic.jl v1.3")
    println("First Order Logic Module")
    println("Author: Fernando Sancho Caparrini")
    println("Date: 30-11-2025")
    println("University of Seville")
    println()
    println("Included Submodules:")
    println("  Core: Types, Parser, Analysis and LStructures")
    println("  Algorithms: Tableaux, NormalForms, Herbrand, Unification and Resolution")
    println()

    # println("Uso: help(PropositionalLogic) para documentación completa")
end

# Mostrar información al cargar el módulo
function __init__()
    println("FirstOrderLogic.jl loaded successfully")
    println("Use version() for module information")
    println("Use help() for interactive help system")
end


end # module