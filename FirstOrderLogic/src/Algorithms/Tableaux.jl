module Tableaux

import GraphvizDotLang as GVL

using ..Types
using ..State
using ..LStructures
using ..NormalForms: substitute_var
using ..Unification: UMG, apply_substitution

# ════════════════════════════════════════════════════════════════════════════
# TABLEAUX SEMÁNTICOS PARA LÓGICA DE PRIMER ORDEN
# 
# Módulo dividido en submódulos para mejor mantenibilidad:
# - Types.jl: Estructuras de datos (TSNodeFOL, FormulaRegistry)
# - Terms.jl: Manejo de términos y contradicciones
# - Rules.jl: Reglas α, β, γ, δ
# - Core.jl: Algoritmo principal TS_FOL y funciones SAT/VALID/solve
# - Models.jl: Extracción y verificación de modelos
# - Visualization.jl: Impresión y visualización con Graphviz
# ════════════════════════════════════════════════════════════════════════════

# Incluir submódulos
include("Tableaux/Types.jl")
include("Tableaux/Terms.jl")
include("Tableaux/Rules.jl")
include("Tableaux/Core.jl")
include("Tableaux/Models.jl")
include("Tableaux/Visualization.jl")

# Exportar símbolos públicos
export TSNodeFOL, TS_FOL
export TS_SAT, TS_VALID, TS_solve
export print_TS_FOL, print_TS_FOL_verbose
export print_formula_registry, to_dot, to_file
export is_ground_term, get_ground_terms, extract_ground_terms
export FormulaInfo, FormulaRegistry, add_formula!
export one_model, all_models, print_model, verify_model
export to_LS

end
