# PropositionalLogic.jl - Claude API Reference

## Quick Module Overview

**Structure:** Modular Julia library for Propositional Logic education and research  
**Author:** Fernando Sancho Caparrini, Universidad de Sevilla  
**Purpose:** Complete implementation of propositional logic algorithms with educational focus

---

## 🏗️ CORE TYPE SYSTEM

```julia
# Abstract base type
abstract type FormulaPL end

# Concrete formula types
struct Var_PL <: FormulaPL; name::String; end                    # Variables: p, q, r
struct Neg_PL <: FormulaPL; sub::FormulaPL; end                  # Negation: ¬φ
struct And_PL <: FormulaPL; left::FormulaPL; right::FormulaPL; end  # Conjunction: φ ∧ ψ
struct Or_PL <: FormulaPL; left::FormulaPL; right::FormulaPL; end   # Disjunction: φ ∨ ψ
struct Imp_PL <: FormulaPL; left::FormulaPL; right::FormulaPL; end  # Implication: φ → ψ
struct Iff_PL <: FormulaPL; left::FormulaPL; right::FormulaPL; end  # Biconditional: φ ↔ ψ
struct Top_PL <: FormulaPL; end                                     # Truth: ⊤
struct Bottom_PL <: FormulaPL; end                                  # Falsity: ⊥

# Auxiliary types
const Valuation = Dict{Var_PL, Bool}
struct Literal; variable::Var_PL; positive::Bool; end
struct Clause; literals::Set{Literal}; end
struct Cube; literals::Set{Literal}; end
struct TableauNode; formulas::Set{FormulaPL}; valuation::Valuation; is_closed::Bool; children::Vector{TableauNode}; end
```

---

## 🔧 CONSTRUCTOR FUNCTIONS

```julia
# Variable construction
vars(names...) -> Vector{Var_PL}              # vars("p", "q", "r")
vars(names::Vector{String}) -> Vector{Var_PL}  # vars(["p", "q", "r"])

# Constants
⊤ = Top_PL()                                   # Truth constant
⊥ = Bottom_PL()                                # Falsity constant

# Overloaded operators (natural syntax)
!(f::FormulaPL) -> Neg_PL                      # Negation
&(f1::FormulaPL, f2::FormulaPL) -> And_PL      # Conjunction
|(f1::FormulaPL, f2::FormulaPL) -> Or_PL       # Disjunction
>(f1::FormulaPL, f2::FormulaPL) -> Imp_PL      # Implication
~(f1::FormulaPL, f2::FormulaPL) -> Iff_PL      # Biconditional

# Multiple operators
⋀(fs::FormulaPL...) -> FormulaPL               # Multiple conjunction
⋁(fs::FormulaPL...) -> FormulaPL               # Multiple disjunction

# Advanced constructor
@formula "((p & q) > r) | (!p ~ q)" -> FormulaPL
```

---

## 📊 EVALUATION SYSTEM

```julia
# Core evaluation
evaluate(f::FormulaPL, val::Valuation) -> Bool
(val::Valuation)(f::FormulaPL) -> Bool         # Functional syntax

# Valuation construction
valuation_from_assignment(vars::Vector{Var_PL}, values::Vector{Bool}) -> Valuation
valuation_from_binary(vars::Vector{Var_PL}, binary_string::String) -> Valuation
all_valuations_for(vars::Vector{Var_PL}) -> Vector{Valuation}

# Formula analysis
vars_of(f::FormulaPL) -> Set{Var_PL}           # Extract variables
subformulas(f::FormulaPL) -> Set{FormulaPL}    # Get all subformulas
complexity(f::FormulaPL) -> Int                # Syntactic complexity
```

---

## 📈 TRUTH TABLES & MODELS

```julia
# Truth table generation
truth_table(f::FormulaPL) -> DataFrame
truth_table(fs::Vector{FormulaPL}) -> DataFrame

# Model search
models(f::FormulaPL) -> Vector{Valuation}          # Satisfying models
countermodels(f::FormulaPL) -> Vector{Valuation}   # Refuting models

# Display
print_table(table::DataFrame) -> Nothing
export_table_latex(table::DataFrame) -> String
```

---

## 🔍 SEMANTIC PROPERTIES

```julia
# Basic properties
TAUT(f::FormulaPL) -> Bool                     # Is tautology?
SAT(f::FormulaPL) -> Bool                      # Is satisfiable?
UNSAT(f::FormulaPL) -> Bool                    # Is unsatisfiable?

# Logical equivalence
EQUIV(f1::FormulaPL, f2::FormulaPL) -> Bool
EQUIV_models(f1::FormulaPL, f2::FormulaPL) -> Bool

# Logical consequence (multiple methods)
LC_Def(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool      # Semantic definition
LC_TAUT(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool     # Reduction to tautology
LC_RA(premises::Vector{FormulaPL}, conclusion::FormulaPL) -> Bool       # Reductio ad absurdum

# Simplification
simplify_constants(f::FormulaPL) -> FormulaPL
```

---

## 🔄 NORMAL FORMS

```julia
# Main transformations
to_CNF(f::FormulaPL) -> FormulaPL              # Conjunctive Normal Form
to_DNF(f::FormulaPL) -> FormulaPL              # Disjunctive Normal Form

# Intermediate steps
remove_imp(f::FormulaPL) -> FormulaPL          # Remove implications
move_negation_in(f::FormulaPL) -> FormulaPL    # De Morgan's laws
dist_and_or(f::FormulaPL) -> FormulaPL         # Distribute ∧ over ∨
dist_or_and(f::FormulaPL) -> FormulaPL         # Distribute ∨ over ∧

# Clause/cube manipulation
extract_clauses_from_CNF(f::FormulaPL) -> Set{Clause}
extract_cubes_from_DNF(f::FormulaPL) -> Set{Cube}
build_CNF_from_clauses(clauses::Set{Clause}) -> FormulaPL
build_DNF_from_cubes(cubes::Set{Cube}) -> FormulaPL

# Clause analysis
is_tautological(c::Clause) -> Bool
is_contradictory(c::Clause) -> Bool
complement(l::Literal) -> Literal
are_complementary(l1::Literal, l2::Literal) -> Bool
```

---

## 🎯 DPLL ALGORITHM

```julia
# Main interface
DPLL_SAT(f::FormulaPL; verbose::Bool = false) -> Bool
DPLL_solve(f::FormulaPL; verbose::Bool = false) -> Union{Valuation, Nothing}
DPLL_LC(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Bool

# Clause form conversion
to_CF(f::FormulaPL) -> Vector{Clause}
clean_CF(clauses::Vector{Clause}) -> Vector{Clause}

# DPLL techniques
unit_clauses(clauses::Vector{Clause}) -> Vector{Literal}
pure_literals(clauses::Vector{Clause}) -> Vector{Literal}
apply_val(clauses::Vector{Clause}, val::Valuation) -> Vector{Clause}

# Core algorithm
DPLL(clauses::Vector{Clause}; verbose::Bool = false) -> Union{Valuation, Nothing}
```

---

## 🌳 SEMANTIC TABLEAUX

```julia
# Main interface
TS_SAT(f::FormulaPL) -> Bool
TS_TAUT(f::FormulaPL) -> Bool
TS_solve(f::FormulaPL) -> Union{Valuation, Nothing}

# Tableau construction
build_TS(f::FormulaPL) -> TableauNode
TS_from_formula(f::FormulaPL) -> TableauNode

# Tableau analysis
has_contradiction(node::TableauNode) -> Bool
is_atomic(f::FormulaPL) -> Bool
is_α_formula(f::FormulaPL) -> Bool              # Non-branching
is_β_formula(f::FormulaPL) -> Bool              # Branching

# Rule application
apply_α(node::TableauNode, formula::FormulaPL) -> TableauNode
apply_β(node::TableauNode, formula::FormulaPL) -> Vector{TableauNode}

# Display
print_TS(tableau::TableauNode) -> Nothing
export_TS_graphviz(tableau::TableauNode) -> String
```

---

## ⚡ RESOLUTION METHOD

```julia
# Main interface
RES_SAT(f::FormulaPL; verbose::Bool = false) -> Bool
RES_TAUT(f::FormulaPL; verbose::Bool = false) -> Bool
RES_LC(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Bool
RES_solve(f::FormulaPL; verbose::Bool = false) -> Bool

# Resolution operations
resolve(c1::Clause, c2::Clause) -> Union{Clause, Nothing}
find_complementary_pairs(c1::Clause, c2::Clause) -> Vector{Tuple{Literal, Literal}}

# Optimizations
is_subsumed(c1::Clause, c2::Clause) -> Bool
remove_subsumed(clauses::Vector{Clause}) -> Vector{Clause}

# Preparation
to_resolution_clauses(f::FormulaPL) -> Vector{Clause}

# Core algorithm
RES(clauses::Vector{Clause}; verbose::Bool = false) -> Bool

# Proof generation
show_resolution_trace(clauses::Vector{Clause}) -> Nothing
resolution_statistics(clauses::Vector{Clause}) -> Dict
```

---

## 🚀 HIGH-LEVEL FUNCTIONS

```julia
# Comprehensive analysis
analyze(f::FormulaPL; verbose::Bool = false) -> Tuple{Bool, Bool}

# Algorithm comparison
compare_algorithms(f::FormulaPL; iterations::Int = 1) -> Tuple

# Multi-method logical consequence verification
verify_logical_consequence(premises::Vector{FormulaPL}, conclusion::FormulaPL; verbose::Bool = false) -> Tuple{Bool, Bool, Bool}

# Module information
version() -> Nothing
```

---

## 💡 USAGE PATTERNS

### Basic Formula Construction
```julia
p, q, r = vars("p", "q", "r")
formula = (p & q) > r                          # Standard operators
formula2 = ⋀(p > q, q > r, p)                 # Multiple conjunction
```

### Property Checking
```julia
TAUT(p | !p)                                  # true (law of excluded middle)
SAT(p & q)                                    # true (satisfiable)
EQUIV(p > q, !p | q)                          # true (implication equivalence)
```

### Algorithm Application
```julia
# All three methods for same problem
dpll_result = DPLL_SAT(formula)
ts_result = TS_SAT(formula)
res_result = RES_SAT(formula)

# Detailed analysis
model = DPLL_solve(formula, verbose=true)
```

### Logical Arguments
```julia
premises = [p > q, q > r, p]
conclusion = r
is_valid = LC_Def(premises, conclusion)        # true (valid modus ponens chain)
```

---

## 🔧 EXTENSION POINTS

### Custom Formula Types
```julia
# Define new type inheriting from FormulaPL
struct CustomFormula <: FormulaPL
    # fields...
end

# Implement required methods
evaluate(f::CustomFormula, val::Valuation) = # implementation
Base.show(io::IO, f::CustomFormula) = # implementation
vars_of(f::CustomFormula) = # implementation
```

### Custom Algorithms
```julia
# Follow existing module pattern
module MyAlgorithm
    using ..Types, ..Evaluation
    function my_solver(f::FormulaPL)
        # implementation
    end
    export my_solver
end
```

---

## 🎯 KEY DESIGN PRINCIPLES

1. **Educational Focus**: Clear, documented implementations over maximum optimization
2. **Modular Structure**: Independent modules that can be studied separately
3. **Multiple Methods**: Same problems solved by different algorithms for comparison
4. **Natural Syntax**: Overloaded operators for intuitive formula construction
5. **Comprehensive Testing**: All algorithms verify consistency with each other
6. **Extensibility**: Easy to add new formula types and algorithms

---

This reference provides all essential information for extending, using, or analyzing the PropositionalLogic.jl library. Each module is self-contained with clear interfaces and comprehensive functionality for propositional logic education and research.
