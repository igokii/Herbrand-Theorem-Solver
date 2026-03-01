# PropositionalLogic.jl - Function Headers Extract

## CORE TYPE CONSTRUCTORS

```julia
# Variable construction
vars(names::String...) -> Vector{Var_PL}
vars(names::Vector{String}) -> Vector{Var_PL}

# Constants
const ⊤ = Top_PL()
const ⊥ = Bottom_PL()

# Operators (overloaded)
!(f::FormulaPL) -> Neg_PL
&(f1::FormulaPL, f2::FormulaPL) -> And_PL
|(f1::FormulaPL, f2::FormulaPL) -> Or_PL
>(f1::FormulaPL, f2::FormulaPL) -> Imp_PL
~(f1::FormulaPL, f2::FormulaPL) -> Iff_PL

# Multiple operators
⋀(fs::FormulaPL...) -> FormulaPL
⋁(fs::FormulaPL...) -> FormulaPL

# Advanced constructor
macro formula(expr::String) -> FormulaPL
```

---

## EVALUATION FUNCTIONS

```julia
# Core evaluation
evaluate(f::FormulaPL, val::Valuation) -> Bool
(val::Valuation)(f::FormulaPL) -> Bool

# Formula analysis
vars_of(f::FormulaPL) -> Set{Var_PL}
subformulas(f::FormulaPL) -> Set{FormulaPL}
complexity(f::FormulaPL) -> Int
formation_tree(f::FormulaPL) -> String

# Valuation utilities
valuation_from_assignment(vars::Vector{Var_PL}, values::Vector{Bool}) -> Valuation
valuation_from_binary(vars::Vector{Var_PL}, binary::String) -> Valuation
all_valuations_for(vars::Vector{Var_PL}) -> Vector{Valuation}
```

---

## TRUTH TABLES

```julia
# Truth table generation
truth_table(f::FormulaPL) -> DataFrame
truth_table(fs::Vector{FormulaPL}) -> DataFrame

# Model search
models(f::FormulaPL) -> Vector{Valuation}
countermodels(f::FormulaPL) -> Vector{Valuation}

# Display utilities
print_table(table::DataFrame) -> Nothing
export_table_latex(table::DataFrame) -> String
```

---

## SEMANTIC PROPERTIES

```julia
# Basic properties
TAUT(f::FormulaPL) -> Bool
SAT(f::FormulaPL) -> Bool
UNSAT(f::FormulaPL) -> Bool

# Logical equivalence
EQUIV(f1::FormulaPL, f2::FormulaPL) -> Bool
EQUIV_models(f1::FormulaPL, f2::FormulaPL) -> Bool

# Logical consequence
LC_Def(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool
LC_TAUT(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool
LC_RA(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool

# Simplification
simplify_constants(f::FormulaPL) -> FormulaPL
```

---

## NORMAL FORMS

```julia
# Main transformations
to_CNF(f::FormulaPL) -> FormulaPL
to_DNF(f::FormulaPL) -> FormulaPL

# Transformation steps
remove_imp(f::FormulaPL) -> FormulaPL
move_negation_in(f::FormulaPL) -> FormulaPL
dist_and_or(f::FormulaPL) -> FormulaPL
dist_or_and(f::FormulaPL) -> FormulaPL

# Structure extraction
extract_clauses_from_CNF(f::FormulaPL) -> Set{Clause}
extract_cubes_from_DNF(f::FormulaPL) -> Set{Cube}

# Structure construction
build_CNF_from_clauses(clauses::Set{Clause}) -> FormulaPL
build_DNF_from_cubes(cubes::Set{Cube}) -> FormulaPL

# Literal utilities
formula_from_literal(l::Literal) -> FormulaPL
complement(l::Literal) -> Literal
are_complementary(l1::Literal, l2::Literal) -> Bool

# Clause analysis
is_tautological(c::Clause) -> Bool
is_contradictory(c::Clause) -> Bool
```

---

## DPLL ALGORITHM

```julia
# Main interface
DPLL_SAT(f::FormulaPL; verbose::Bool = false) -> Bool
DPLL_solve(f::FormulaPL; verbose::Bool = false) -> Union{Valuation, Nothing}
DPLL_LC(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Bool

# Clause form utilities
to_CF(f::FormulaPL) -> Vector{Clause}
clean_CF(clauses::Vector{Clause}) -> Vector{Clause}
vars_of(clauses::Vector{Clause}) -> Vector{Var_PL}

# DPLL techniques
unit_clauses(clauses::Vector{Clause}) -> Vector{Literal}
pure_literals(clauses::Vector{Clause}) -> Vector{Literal}
apply_val(clauses::Vector{Clause}, val::Valuation) -> Vector{Clause}

# Core algorithm
DPLL(clauses::Vector{Clause}; verbose::Bool = false) -> Union{Valuation, Nothing}
```

---

## SEMANTIC TABLEAUX

```julia
# Main interface
TS_SAT(f::FormulaPL) -> Bool
TS_TAUT(f::FormulaPL) -> Bool
TS_solve(f::FormulaPL) -> Union{Valuation, Nothing}

# Tableau construction
build_TS(f::FormulaPL) -> TableauNode
TS_from_formula(f::FormulaPL) -> TableauNode

# Node analysis
has_contradiction(node::TableauNode) -> Bool
is_atomic(f::FormulaPL) -> Bool
is_α_formula(f::FormulaPL) -> Bool
is_β_formula(f::FormulaPL) -> Bool

# Rule application
apply_α(node::TableauNode, formula::FormulaPL) -> TableauNode
apply_β(node::TableauNode, formula::FormulaPL) -> Vector{TableauNode}

# Display
print_TS(tableau::TableauNode; level::Int = 0) -> Nothing
```

---

## RESOLUTION METHOD

```julia
# Main interface
RES_SAT(f::FormulaPL; verbose::Bool = false) -> Bool
RES_TAUT(f::FormulaPL; verbose::Bool = false) -> Bool
RES_LC(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Bool
RES_solve(f::FormulaPL; verbose::Bool = false) -> Bool

# Resolution operations
resolve(c1::Clause, c2::Clause) -> Union{Clause, Nothing}
find_complementary_pairs(c1::Clause, c2::Clause) -> Vector{Tuple{Literal, Literal}}

# Subsumption and optimization
is_subsumed(c1::Clause, c2::Clause) -> Bool
remove_subsumed(clauses::Vector{Clause}) -> Vector{Clause}

# Conversion utilities
to_resolution_clauses(f::FormulaPL) -> Vector{Clause}

# Core algorithm
RES(clauses::Vector{Clause}; verbose::Bool = false) -> Bool

# Tracing and statistics
show_resolution_trace(clauses::Vector{Clause}) -> Nothing
resolution_statistics(clauses::Vector{Clause}) -> Dict{String, Any}
```

---

## HIGH-LEVEL ANALYSIS FUNCTIONS

```julia
# Comprehensive analysis
analyze(f::FormulaPL; verbose::Bool = false) -> Tuple{Bool, Bool}

# Performance comparison
compare_algorithms(f::FormulaPL; iterations::Int = 1) -> Tuple{Tuple{Bool, Float64}, Tuple{Bool, Float64}, Tuple{Bool, Float64}}

# Multi-method logical consequence
verify_logical_consequence(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Tuple{Bool, Bool, Bool}

# Module information
version() -> Nothing
```

---

## DISPLAY AND FORMATTING

```julia
# Basic display
Base.show(io::IO, f::FormulaPL) -> Nothing
Base.show(io::IO, v::Valuation) -> Nothing
Base.show(io::IO, l::Literal) -> Nothing
Base.show(io::IO, c::Clause) -> Nothing

# Advanced formatting
latex_string(f::FormulaPL) -> String
unicode_string(f::FormulaPL) -> String
ascii_string(f::FormulaPL) -> String

# Tree visualization
formation_tree(f::FormulaPL) -> String
print_tree(f::FormulaPL) -> Nothing
```

---

## UTILITY FUNCTIONS

```julia
# Type predicates
is_variable(f::FormulaPL) -> Bool
is_negation(f::FormulaPL) -> Bool
is_conjunction(f::FormulaPL) -> Bool
is_disjunction(f::FormulaPL) -> Bool
is_implication(f::FormulaPL) -> Bool
is_biconditional(f::FormulaPL) -> Bool
is_constant(f::FormulaPL) -> Bool

# Formula manipulation
substitute(f::FormulaPL, var::Var_PL, replacement::FormulaPL) -> FormulaPL
rename_variables(f::FormulaPL, mapping::Dict{Var_PL, Var_PL}) -> FormulaPL

# Statistics
count_operators(f::FormulaPL) -> Dict{String, Int}
depth(f::FormulaPL) -> Int
size(f::FormulaPL) -> Int
```

---

## TYPICAL USAGE PATTERNS

```julia
# Basic formula creation and analysis
p, q, r = vars("p", "q", "r")
formula = (p & q) > r
result_sat = SAT(formula)
result_taut = TAUT(formula)

# Truth table analysis
table = truth_table(formula)
print_table(table)
satisfying_models = models(formula)

# Normal form transformations
cnf_form = to_CNF(formula)
dnf_form = to_DNF(formula)

# Algorithm comparison
dpll_result = DPLL_SAT(formula, verbose=true)
tableau_result = TS_SAT(formula)
resolution_result = RES_SAT(formula, verbose=true)

# Logical consequence verification
premises = [p > q, q > r, p]
conclusion = r
is_consequence = LC_Def(premises, conclusion)

# Comprehensive analysis
sat_result, taut_result = analyze(formula, verbose=true)
performance_data = compare_algorithms(formula, iterations=10)
```

---

## MODULE INITIALIZATION

```julia
# Module structure
module PropositionalLogic
    # Core modules
    include("Core/Types.jl")
    include("Core/Evaluation.jl")
    include("Core/Display.jl")
    
    # Analysis modules
    include("Analysis/TruthTables.jl")
    include("Analysis/Properties.jl")
    include("Analysis/NormalForms.jl")
    
    # Algorithm modules
    include("Algorithms/DPLL.jl")
    include("Algorithms/Tableaux.jl")
    include("Algorithms/Resolution.jl")
    
    # Re-export all public functions
    # ... (extensive export list)
    
    # Initialization
    function __init__()
        println("PropositionalLogic.jl cargado exitosamente")
        println("Usar version() para información del módulo")
        println("Usar analyze(formula) para análisis completo")
    end
end
```

---

This header extract provides the essential function signatures and typical usage patterns for the PropositionalLogic.jl library, making it easy for Claude to understand the API structure and extend or use the library effectively.
