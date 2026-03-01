# ════════════════════════════════════════════════════════════════════════════
# PARTE 1: TIPOS BÁSICOS Y CONSTRUCTORES
# ════════════════════════════════════════════════════════════════════════════


module Types

# ──────────────────────────────────────────────────────────────────────────
# 1. TIPOS BÁSICOS - Términos y Fórmulas
# ──────────────────────────────────────────────────────────────────────────
export Term, Var_FOL, Const_FOL, Func_FOL
export FOLFormula, Predicate_FOL, NotFOL, AndFOL, OrFOL, ImpliesFOL, IffFOL
export Forall, Exists
export FOLModel

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
# 1.1 TÉRMINOS - Variables, constantes y funciones
# ──────────────────────────────────────────────────────────────────────────


"""
    Term

Tipo abstracto para representar términos en lógica de primer orden.
Un término puede ser:
- Una variable (`Var_FOL`)
- Una constante (`Const_FOL`)
- Una función aplicada a términos (`Func_FOL`)
"""
abstract type Term end

"""
    Var_FOL <: Term

Representa una variable en lógica de primer orden.

# Campos
- `name::String`: Nombre de la variable (ej: "x", "y", "z")

# Ejemplo
```julia
x = Var_FOL("x")
```
"""
struct Var_FOL <: Term
    name::String
end

"""
    Const_FOL <: Term

Representa una constante en lógica de primer orden.

# Campos
- `name::String`: Nombre de la constante (ej: "a", "b", "Juan")

# Ejemplo
```julia
juan = Const_FOL("Juan")
```
"""
struct Const_FOL <: Term
    name::String
end

"""
    Func_FOL <: Term

Representa una función aplicada a términos en lógica de primer orden.

# Campos
- `name::String`: Nombre de la función (ej: "padre", "suma")
- `args::Vector{Term}`: Argumentos de la función

# Ejemplo
```julia
x = Var_FOL("x")
padre_de_x = Func_FOL("padre", [x])
```
"""
struct Func_FOL <: Term
    name::String
    args::Vector{Term}
end

# ──────────────────────────────────────────────────────────────────────────
# 1.2 FÓRMULAS - Cuantificadores y conectivas lógicas
# ──────────────────────────────────────────────────────────────────────────

"""
    FOLFormula

Tipo abstracto para representar fórmulas en lógica de primer orden.
Una fórmula puede ser:
- Un predicado aplicado a términos (`Predicate_FOL`)
- Negación (`NotFOL`) de una fórmula
- Conjunción (`AndFOL`) de dos fórmulas
- Disyunción (`OrFOL`) de dos fórmulas
- Implicación (`ImpliesFOL`) de dos fórmulas
- Bicondicional (`IffFOL`) de dos fórmulas
- Cuantificador universal (`Forall`) de una variable y una fórmula
- Cuantificador existencial (`Exists`) de una variable y una fórmula
"""
abstract type FOLFormula end

"""
    Predicate_FOL <: FOLFormula

Representa un predicado aplicado a términos.

# Campos
- `name::String`: Nombre del predicado (ej: "Hombre", "Ama")
- `args::Vector{Term}`: Argumentos del predicado

# Ejemplo
```julia
x = Var_FOL("x")
Hombre_x = Predicate_FOL("Hombre", [x])
```
"""
struct Predicate_FOL <: FOLFormula
    name::String
    args::Vector{Term}
end

"""Negación lógica: ¬φ"""
struct NotFOL <: FOLFormula
    operand::FOLFormula
end

"""Conjunción lógica: φ ∧ ψ"""
struct AndFOL <: FOLFormula
    left::FOLFormula
    right::FOLFormula
end

"""Disyunción lógica: φ ∨ ψ"""
struct OrFOL <: FOLFormula
    left::FOLFormula
    right::FOLFormula
end

"""Implicación lógica: φ → ψ"""
struct ImpliesFOL <: FOLFormula
    left::FOLFormula
    right::FOLFormula
end

"""Bicondicional lógico: φ ↔ ψ"""
struct IffFOL <: FOLFormula
    left::FOLFormula
    right::FOLFormula
end

"""Cuantificador universal: ∀x.φ"""
struct Forall <: FOLFormula
    var::Var_FOL
    body::FOLFormula
end

"""Cuantificador existencial: ∃x.φ"""
struct Exists <: FOLFormula
    var::Var_FOL
    body::FOLFormula
end

# ──────────────────────────────────────────────────────────────────────────
# 1.3 Operadores proposicionales
# ──────────────────────────────────────────────────────────────────────────
import Base: !

"""Negación: !φ o -φ produce ¬φ"""
!(f::FOLFormula) = NotFOL(f)
Base.:-(f::FOLFormula) = NotFOL(f)

"""Conjunción: φ & ψ produce φ ∧ ψ"""
function Base.:&(f1::FOLFormula, f2::FOLFormula)
    AndFOL(f1, f2)
end

"""Disyunción: φ | ψ produce φ ∨ ψ"""
function Base.:|(f1::FOLFormula, f2::FOLFormula)  
    OrFOL(f1, f2)
end

"""Implicación: φ > ψ produce φ → ψ"""
function Base.:>(f1::FOLFormula, f2::FOLFormula)
    ImpliesFOL(f1, f2)
end

"""Bicondicional: iff(φ, ψ) o φ ~ ψ produce φ ↔ ψ"""
iff(f1::FOLFormula, f2::FOLFormula) = IffFOL(f1, f2)
function Base.:~(f1::FOLFormula, f2::FOLFormula)
    iff(f1, f2)
end

# ──────────────────────────────────────────────────────────────────────────
# 1.4 Cuantificadores
# ──────────────────────────────────────────────────────────────────────────

"""Cuantificador universal: ∀(x, φ) produce ∀x.φ"""
∀(var::Var_FOL, body::FOLFormula) = Forall(var, body)

"""Cuantificador existencial: ∃(x, φ) produce ∃x.φ"""
∃(var::Var_FOL, body::FOLFormula) = Exists(var, body)

# ──────────────────────────────────────────────────────────────────────────
# 1.5 Igualdad estructural para términos
# ──────────────────────────────────────────────────────────────────────────

"""Dos variables son iguales si tienen el mismo nombre"""
function Base.:(==)(t1::Var_FOL, t2::Var_FOL)
    t1.name == t2.name
end

"""Dos constantes son iguales si tienen el mismo nombre"""
function Base.:(==)(t1::Const_FOL, t2::Const_FOL)
    t1.name == t2.name
end

"""Dos funciones son iguales si tienen el mismo nombre y mismos argumentos"""
function Base.:(==)(t1::Func_FOL, t2::Func_FOL)
    t1.name == t2.name && t1.args == t2.args
end

# Igualdad para fórmulas FOL
"""Dos predicados son iguales si tienen el mismo nombre y mismos argumentos"""
function Base.:(==)(p1::Predicate_FOL, p2::Predicate_FOL)
    p1.name == p2.name && p1.args == p2.args
end

"""Dos negaciones son iguales si sus operandos son iguales"""
function Base.:(==)(f1::NotFOL, f2::NotFOL)
    f1.operand == f2.operand
end

"""Dos conjunciones son iguales si sus operandos izquierdo y derecho son iguales"""
function Base.:(==)(f1::AndFOL, f2::AndFOL)
    f1.left == f2.left && f1.right == f2.right
end

"""Dos disyunciones son iguales si sus operandos izquierdo y derecho son iguales"""
function Base.:(==)(f1::OrFOL, f2::OrFOL)
    f1.left == f2.left && f1.right == f2.right
end

"""Dos implicaciones son iguales si sus operandos izquierdo y derecho son iguales"""
function Base.:(==)(f1::ImpliesFOL, f2::ImpliesFOL)
    f1.left == f2.left && f1.right == f2.right
end

"""Dos bicondicionales son iguales si sus operandos izquierdo y derecho son iguales"""
function Base.:(==)(f1::IffFOL, f2::IffFOL)
    f1.left == f2.left && f1.right == f2.right
end

"""Dos cuantificadores universales son iguales si sus variables y cuerpos son iguales"""
function Base.:(==)(f1::Forall, f2::Forall)
    f1.var == f2.var && f1.body == f2.body
end

"""Dos cuantificadores existenciales son iguales si sus variables y cuerpos son iguales"""
function Base.:(==)(f1::Exists, f2::Exists)
    f1.var == f2.var && f1.body == f2.body
end

# ──────────────────────────────────────────────────────────────────────────
# 1.6 Hashing para estructuras
# ──────────────────────────────────────────────────────────────────────────

Base.hash(t::Var_FOL, h::UInt) = hash(t.name, h)
Base.hash(t::Const_FOL, h::UInt) = hash(t.name, h)
Base.hash(t::Func_FOL, h::UInt) = hash((t.name, t.args), h)

# Hash para fórmulas FOL
Base.hash(p::Predicate_FOL, h::UInt) = hash((p.name, p.args), h)
Base.hash(f::NotFOL, h::UInt) = hash((:not, f.operand), h)
Base.hash(f::AndFOL, h::UInt) = hash((:and, f.left, f.right), h)
Base.hash(f::OrFOL, h::UInt) = hash((:or, f.left, f.right), h)
Base.hash(f::ImpliesFOL, h::UInt) = hash((:implies, f.left, f.right), h)
Base.hash(f::IffFOL, h::UInt) = hash((:iff, f.left, f.right), h)
Base.hash(f::Forall, h::UInt) = hash((:forall, f.var, f.body), h)
Base.hash(f::Exists, h::UInt) = hash((:exists, f.var, f.body), h)

# ──────────────────────────────────────────────────────────────────────────
# 1.7 Representación legible
# ──────────────────────────────────────────────────────────────────────────

"""Mostrar variable: x"""
function Base.show(io::IO, t::Var_FOL)
    print(io, t.name)
end

"""Mostrar constante: a"""
function Base.show(io::IO, t::Const_FOL)
    print(io, t.name)
end

"""Mostrar función: f(x, y)"""
function Base.show(io::IO, t::Func_FOL)
    if isempty(t.args)
        print(io, "$(t.name)()")
    else
        print(io, "$(t.name)(", join(t.args, ", "), ")")
    end
end

"""Mostrar predicado: P(x, y)"""
function Base.show(io::IO, p::Predicate_FOL)
    if isempty(p.args)
        print(io, "$(p.name)()")
    else
        print(io, "$(p.name)(", join(p.args, ", "), ")")
    end
end

"""Mostrar negación: ¬φ"""
function Base.show(io::IO, f::NotFOL)
    print(io, "¬$(f.operand)")
end

"""Mostrar conjunción: (φ ∧ ψ)"""
function Base.show(io::IO, f::AndFOL)
    print(io, "($(f.left) ∧ $(f.right))")
end

"""Mostrar disyunción: (φ ∨ ψ)"""
function Base.show(io::IO, f::OrFOL)
    print(io, "($(f.left) ∨ $(f.right))")
end

"""Mostrar implicación: (φ → ψ)"""
function Base.show(io::IO, f::ImpliesFOL)
    print(io, "($(f.left) → $(f.right))")
end

"""Mostrar bicondicional: (φ ↔ ψ)"""
function Base.show(io::IO, f::IffFOL)
    print(io, "($(f.left) ↔ $(f.right))")
end

"""Mostrar cuantificador universal: ∀x.φ"""
function Base.show(io::IO, f::Forall)
    print(io, "∀$(f.var).$(f.body)")
end

"""Mostrar cuantificador existencial: ∃x.φ"""
function Base.show(io::IO, f::Exists)
    print(io, "∃$(f.var).$(f.body)")
end

# ──────────────────────────────────────────────────────────────────────────
# 1.8 Constructores simples
# ──────────────────────────────────────────────────────────────────────────

"""Constructor simple de variable: var("x")"""
var(name::String) = Var_FOL(name)

"""Constructor simple de constante: const_("a")"""
const_(name::String) = Const_FOL(name)  

"""Constructor simple de función: func("f", x, y)"""
func(name::String, args::Term...) = Func_FOL(name, collect(args))

"""Constructor simple de predicado: pred("P", x, y)"""
pred(name::String, args::Term...) = Predicate_FOL(name, collect(args))

# ──────────────────────────────────────────────────────────────────────────
# 1.9 Constructores parametrizables
# ──────────────────────────────────────────────────────────────────────────

"""
Envoltorio para crear predicados parametrizables.
Permite usar sintaxis: P = predicate("P"); P(x, y)
"""
struct PredicateWrapper
    name::String
    callable::Function
end

"""
Envoltorio para crear funciones parametrizables.
Permite usar sintaxis: f = function_("f"); f(x, y)
"""
struct FunctionWrapper
    name::String
    callable::Function
end

# Mostrar wrappers de forma legible
function Base.show(io::IO, p::PredicateWrapper)
    print(io, "Predicate(\"$(p.name)\")")
end

function Base.show(io::IO, f::FunctionWrapper)
    print(io, "Function(\"$(f.name)\")")
end

# Hacer que los wrappers sean callables (permiten aplicarse a argumentos)
function (p::PredicateWrapper)(args::Term...)
    return p.callable(args...)
end

function (f::FunctionWrapper)(args::Term...)
    return f.callable(args...)
end

# ──────────────────────────────────────────────────────────────────────────
# 1.10 Constructores múltiples
# ──────────────────────────────────────────────────────────────────────────

"""
    vars(names::AbstractString...)
    vars(names::Symbol...)

Crea múltiples variables de primer orden de una sola vez mediante desempaquetado.

# Ejemplos
```julia
x, y, z = vars("x", "y", "z")
a, b = vars(:a, :b)
```

# Retorna
Tupla de variables de tipo `Var_FOL`
"""
vars(names::AbstractString...) = tuple(var.(names)...)
vars(names::Symbol...) = vars(string.(names)...)

"""
    constants(names::AbstractString...)
    constants(names::Symbol...)

Crea múltiples constantes de primer orden de una sola vez mediante desempaquetado.

# Ejemplos
```julia
a, b, c = constants("a", "b", "c")
x, y = constants(:x, :y)
```

# Retorna
Tupla de constantes de tipo `Const_FOL`
"""
constants(names::AbstractString...) = tuple(const_.(names)...)
constants(names::Symbol...) = constants(string.(names)...)

"""
    predicate(name::String)

Crea un predicado parametrizable que admite cualquier número de argumentos.

# Uso
```julia
P = predicate("P")
Ama = predicate("Ama")

x, y = vars("x", "y")
formula1 = P(x)          # P(x)
formula2 = Ama(x, y)     # Ama(x, y)
```

# Retorna
`PredicateWrapper` callable que construye fórmulas `Predicate_FOL`
"""
function predicate(name::String)
    callable = (args::Term...) -> pred(name, args...)
    return PredicateWrapper(name, callable)
end

"""
    predicates(names::AbstractString...)
    predicates(names::Symbol...)

Crea múltiples predicados de primer orden de una sola vez mediante desempaquetado.

# Ejemplos
```julia
P, Q, R = predicates("P", "Q", "R")
Padre, Hijo = predicates(:Padre, :Hijo)
```

# Retorna
Tupla de `PredicateWrapper` callables
"""
predicates(names::AbstractString...) = tuple(predicate.(names)...)
predicates(names::Symbol...) = predicates(string.(names)...)

"""
    function_(name::String)

Crea una función de primer orden parametrizable que admite cualquier número de argumentos.

*Nota*: Se usa `function_` (con underscore) porque `function` es palabra reservada en Julia.

# Uso
```julia
f = function_("f")
padre = function_("padre")

x, y = vars("x", "y")
term1 = f(x)            # f(x)
term2 = padre(x, y)     # padre(x, y)
```

# Retorna
`FunctionWrapper` callable que construye términos `Func_FOL`
"""
function function_(name::String)
    callable = (args::Term...) -> func(name, args...)
    return FunctionWrapper(name, callable)
end

"""
    functions(names::AbstractString...)
    functions(names::Symbol...)

Crea múltiples funciones de primer orden de una sola vez mediante desempaquetado.

# Ejemplos
```julia
f, g, h = functions("f", "g", "h")
padre, madre = functions(:padre, :madre)
```

# Retorna
Tupla de `FunctionWrapper` callables
"""
functions(names::AbstractString...) = tuple(function_.(names)...)
functions(names::Symbol...) = functions(string.(names)...)

# ──────────────────────────────────────────────────────────────────────────
# 4. MODELOS DE LÓGICA DE PRIMER ORDEN
# ──────────────────────────────────────────────────────────────────────────

"""
    FOLModel

Representa un modelo extraído de una rama abierta del tablero semántico.

# Campos
- `domain::Set{Term}`: Dominio del modelo (constantes)
- `true_atoms::Set{FOLFormula}`: Literales atómicos positivos verdaderos
- `false_atoms::Set{FOLFormula}`: Literales atómicos positivos falsos
- `universal_constraints::Vector{FOLFormula}`: Fórmulas universales que deben cumplirse
- `branch_id::String`: Identificador de la rama de donde se extrajo

# Ejemplo
```julia
model = FOLModel(
    Set([Const_FOL("a"), Const_FOL("b")]),
    Set([P(a), Q(b)]),
    Set([R(a)]),
    [∀(x, P(x) > Q(x))],
    "1.2"
)
```
"""
struct FOLModel
    domain::Set{Term}
    true_atoms::Set{FOLFormula}
    false_atoms::Set{FOLFormula}
    universal_constraints::Vector{FOLFormula}
    branch_id::String
end

end