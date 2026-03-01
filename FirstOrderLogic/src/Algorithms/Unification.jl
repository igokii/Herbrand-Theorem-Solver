module Unification

using ..Types
using ..NormalForms

export UMG, Substitution, apply_substitution


# ════════════════════════════════════════════════════════════════════════════
# PARTE 7: UNIFICACIÓN: UMG (Unificador Más General)
# ════════════════════════════════════════════════════════════════════════════

#=
TEORÍA DE UNIFICACIÓN
═══════════════════════

La **unificación** es el proceso de encontrar una sustitución que haga que dos
expresiones sean sintácticamente idénticas.

## Definición
Dados dos términos (o fórmulas atómicas) t₁ y t₂, un **unificador** es una 
sustitución σ tal que σ(t₁) = σ(t₂).

El **Unificador Más General (UMG)** es el unificador que hace el mínimo número 
de compromisos, es decir, cualquier otro unificador puede obtenerse componiendo 
el UMG con otra sustitución.

## Algoritmo
El algoritmo de Robinson (1965) funciona recursivamente:
1. Si t₁ = t₂, retornar sustitución vacía
2. Si t₁ es variable, retornar {t₁ → t₂} (con occurs check)
3. Si t₂ es variable, retornar {t₂ → t₁} (con occurs check)
4. Si t₁ = f(s₁,...,sₙ) y t₂ = f(t₁,...,tₙ), unificar recursivamente

## Occurs Check
Antes de crear una sustitución {X → t}, verificamos que X no ocurra en t,
para evitar términos infinitos como {X → f(X)}.

## Ejemplos
```julia
# Unificación exitosa
UMG(var("X"), const_("a"))           # {X → a}
UMG(func("f", var("X")), func("f", const_("a")))  # {X → a}

# Falla por occurs check
UMG(var("X"), func("f", var("X")))   # nothing

# Unificación de predicados
UMG(pred("P", var("X"), var("Y")), 
    pred("P", const_("a"), const_("b")))  # {X → a, Y → b}
```
=#

"""
    Substitution

Representa una sustitución unificadora para unificación y transformaciones.
Mapea nombres de variables (String) a términos.

Una sustitución σ = {X₁ → t₁, X₂ → t₂, ...} reemplaza cada variable Xᵢ 
por el término tᵢ cuando se aplica a una expresión.

# Constructores
```julia
Substitution()                                    # Sustitución vacía (identidad)
Substitution(Dict("x" => const_("a")))           # Desde diccionario String → Term
Substitution(Dict(var("x") => const_("a")))      # Desde Dict{Var_FOL, Term}
```

# Campos
- `bindings::Dict{String, Term}` - Mapeo de nombres de variables a términos

# Ver también
- [`UMG`](@ref) - Calcula el Unificador Más General
- [`apply_substitution`](@ref) - Aplica una sustitución a un término o fórmula
- [`compose_substitutions`](@ref) - Compone dos sustituciones
"""
struct Substitution
    bindings::Dict{String, Term}
end

Substitution() = Substitution(Dict{String, Term}())

# Constructor desde Dict{Var_FOL, Term} para compatibilidad
"""
    Substitution(dict::Dict{Var_FOL, Term})

Convierte un diccionario de variables a términos en una Substitution.
Útil para código que usa el sistema antiguo.
"""
function Substitution(dict::Dict{Var_FOL, Term})
    Substitution(Dict(v.name => t for (v, t) in dict))
end

function Base.show(io::IO, s::Substitution)
    if isempty(s.bindings)
        print(io, "{}")
    else
        items = ["$(k) → $(v)" for (k, v) in s.bindings]
        print(io, "{", join(items, ", "), "}")
    end
end

# ════════════════════════════════════════════════════════════════════════════
# APLICACIÓN DE SUSTITUCIONES
# ════════════════════════════════════════════════════════════════════════════

"""
    apply_substitution(x, s::Substitution)

Aplica una sustitución `s` a un término, predicado, literal o fórmula `x`.

Esta función utiliza **dispatch múltiple** de Julia: hay un método especializado
para cada tipo de expresión FOL. El compilador selecciona automáticamente el
método correcto según el tipo del argumento.

# Métodos disponibles
- `apply_substitution(::Var_FOL, ::Substitution)` - Variable
- `apply_substitution(::Const_FOL, ::Substitution)` - Constante (sin cambios)
- `apply_substitution(::Func_FOL, ::Substitution)` - Función (recursivo en args)
- `apply_substitution(::Predicate_FOL, ::Substitution)` - Predicado
- `apply_substitution(::Literal, ::Substitution)` - Literal (para resolución)
- `apply_substitution(::FOLFormula, ::Substitution)` - Fórmula completa
  - Respeta variables ligadas (∀, ∃)
  - Recursivo en subfórmulas

# Argumentos
- `x` - Término, predicado, literal o fórmula a sustituir
- `s::Substitution` - Sustitución a aplicar

# Retorna
- Expresión con variables reemplazadas según `s`

# Ejemplos
```julia
# Términos
s = Substitution(Dict("x" => const_("a"), "y" => const_("b")))
apply_substitution(var("x"), s)                    # a
apply_substitution(func("f", var("x"), var("y")), s)  # f(a, b)

# Predicados
apply_substitution(pred("P", var("x")), s)         # P(a)

# Fórmulas (respeta variables ligadas)
f = ∀(var("x"), pred("P", var("x")))
apply_substitution(f, s)                           # ∀x.P(x) - x ligada, no se sustituye

f2 = pred("P", var("x")) & pred("Q", var("y"))
apply_substitution(f2, s)                          # P(a) ∧ Q(b)
```

# Nota sobre variables ligadas
Cuando se aplica una sustitución a fórmulas con cuantificadores (∀, ∃),
las variables ligadas NO se sustituyen. Por ejemplo:
```julia
s = Substitution(Dict("x" => const_("a")))
f = ∀(var("x"), pred("P", var("x")))
apply_substitution(f, s)  # ∀x.P(x) - x NO se sustituye porque está ligada
```
"""
function apply_substitution(t::Term, s::Substitution)
    if t isa Var_FOL && haskey(s.bindings, t.name)
        return s.bindings[t.name]
    elseif t isa Func_FOL
        new_args = [apply_substitution(arg, s) for arg in t.args]
        return Func_FOL(t.name, new_args)
    else
        return t
    end
end

# Aplicar sustitución a un predicado
function apply_substitution(p::Predicate_FOL, s::Substitution)
    new_args = [apply_substitution(arg, s) for arg in p.args]
    return Predicate_FOL(p.name, new_args)
end

# Aplicar sustitución a un literal (usado en resolución)
function apply_substitution(l::Literal, s::Substitution)
    return Literal(apply_substitution(l.predicate, s), l.negated)
end

# Aplicar sustitución a fórmulas FOL completas (despacha según tipo de fórmula)
function apply_substitution(f::FOLFormula, s::Substitution)
    if f isa Predicate_FOL
        return apply_substitution(f, s)  # Ya definido arriba
    elseif f isa NotFOL
        return NotFOL(apply_substitution(f.operand, s))
    elseif f isa AndFOL
        return AndFOL(apply_substitution(f.left, s), apply_substitution(f.right, s))
    elseif f isa OrFOL
        return OrFOL(apply_substitution(f.left, s), apply_substitution(f.right, s))
    elseif f isa ImpliesFOL
        return ImpliesFOL(apply_substitution(f.left, s), apply_substitution(f.right, s))
    elseif f isa IffFOL
        return IffFOL(apply_substitution(f.left, s), apply_substitution(f.right, s))
    elseif f isa Forall
        # No sustituir la variable ligada
        if haskey(s.bindings, f.var.name)
            # Crear nueva sustitución sin la variable ligada
            new_bindings = copy(s.bindings)
            delete!(new_bindings, f.var.name)
            new_s = Substitution(new_bindings)
            return Forall(f.var, apply_substitution(f.body, new_s))
        else
            return Forall(f.var, apply_substitution(f.body, s))
        end
    elseif f isa Exists
        # No sustituir la variable ligada
        if haskey(s.bindings, f.var.name)
            new_bindings = copy(s.bindings)
            delete!(new_bindings, f.var.name)
            new_s = Substitution(new_bindings)
            return Exists(f.var, apply_substitution(f.body, new_s))
        else
            return Exists(f.var, apply_substitution(f.body, s))
        end
    else
        return f
    end
end

# ════════════════════════════════════════════════════════════════════════════
# COMPOSICIÓN DE SUSTITUCIONES
# ════════════════════════════════════════════════════════════════════════════

"""
    compose_substitutions(s1::Substitution, s2::Substitution)

Compone dos sustituciones: (s1 ∘ s2)(t) = s2(s1(t))

La composición σ₁ ∘ σ₂ se define como:
- Para cada X → t en σ₁, incluir X → σ₂(t)
- Para cada Y → s en σ₂ que no esté en σ₁, incluir Y → s

# Argumentos
- `s1::Substitution` - Primera sustitución
- `s2::Substitution` - Segunda sustitución

# Retorna
- `Substitution` - Composición s1 ∘ s2

# Ejemplo
```julia
s1 = Substitution(Dict("x" => var("y")))
s2 = Substitution(Dict("y" => const_("a")))
s3 = compose_substitutions(s1, s2)  # {x → a, y → a}
```

# Propiedades
- **NO conmutativa:** s1 ∘ s2 ≠ s2 ∘ s1 en general
- **Asociativa:** (s1 ∘ s2) ∘ s3 = s1 ∘ (s2 ∘ s3)
"""
function compose_substitutions(s1::Substitution, s2::Substitution)
    new_bindings = Dict{String, Term}()
    
    # Aplicar s2 a los valores de s1
    for (var, term) in s1.bindings
        new_bindings[var] = apply_substitution(term, s2)
    end
    
    # Añadir bindings de s2 que no están en s1
    for (var, term) in s2.bindings
        if !haskey(new_bindings, var)
            new_bindings[var] = term
        end
    end
    
    return Substitution(new_bindings)
end

# ════════════════════════════════════════════════════════════════════════════
# ALGORITMO DE UNIFICACIÓN (UMG)
# ════════════════════════════════════════════════════════════════════════════

"""
    UMG(t1::Term, t2::Term)
    UMG(p1::Predicate_FOL, p2::Predicate_FOL)

Calcula el **Unificador Más General (UMG)** de dos términos o predicados.

El UMG es la sustitución más general σ tal que σ(t1) = σ(t2). Si no existe
tal sustitución (los términos no son unificables), retorna `nothing`.

# Algoritmo de Robinson (1965)
1. Si t₁ = t₂, retornar sustitución vacía {}
2. Si t₁ es variable X:
   - Si X ocurre en t₂, fallar (occurs check)
   - Sino, retornar {X → t₂}
3. Si t₂ es variable Y:
   - Si Y ocurre en t₁, fallar (occurs check)
   - Sino, retornar {Y → t₁}
4. Si t₁ = f(s₁,...,sₙ) y t₂ = f(r₁,...,rₙ):
   - Unificar recursivamente cada par (sᵢ, rᵢ)
5. Sino, fallar (símbolos de función diferentes o aridades distintas)

# Occurs Check
Antes de crear {X → t}, verificamos que X no ocurra en t para evitar
términos infinitos como {X → f(X)}.

# Argumentos
- `t1`, `t2` - Términos o predicados a unificar

# Retorna
- `Substitution` - El UMG si existe
- `nothing` - Si los términos no son unificables

# Ejemplos
```julia
# Unificación simple
UMG(var("X"), const_("a"))  # {X → a}

# Unificación de funciones
t1 = func("f", var("X"), const_("b"))
t2 = func("f", const_("a"), var("Y"))
UMG(t1, t2)  # {X → a, Y → b}

# Unificación de predicados
p1 = pred("P", var("X"), var("Y"))
p2 = pred("P", const_("a"), func("f", var("Z")))
UMG(p1, p2)  # {X → a, Y → f(Z)}

# Falla por occurs check
UMG(var("X"), func("f", var("X")))  # nothing

# Falla por símbolos diferentes
UMG(func("f", var("X")), func("g", var("X")))  # nothing
```

# Propiedades del UMG
- **Corrección:** Si σ = UMG(t₁, t₂), entonces σ(t₁) = σ(t₂)
- **Completitud:** Si t₁ y t₂ son unificables, UMG encuentra un unificador
- **Minimalidad:** Cualquier otro unificador θ se puede obtener como θ = UMG ∘ δ

# Ver también
- [`apply_substitution`](@ref) - Aplica una sustitución
- [`compose_substitutions`](@ref) - Compone sustituciones
"""
function UMG(t1::Term, t2::Term)
    return UMG_terms(t1, t2, Substitution())
end

"""
    UMG_terms(t1::Term, t2::Term, s::Substitution)

Función auxiliar recursiva para el algoritmo de unificación.
Calcula el UMG acumulando la sustitución `s`.

# Argumentos
- `t1`, `t2` - Términos a unificar
- `s` - Sustitución acumulada hasta el momento

# Retorna
- `Substitution` - UMG extendido con nuevos bindings
- `nothing` - Si no son unificables

Esta función es interna y no debería llamarse directamente.
Use [`UMG`](@ref) en su lugar.
"""
function UMG_terms(t1::Term, t2::Term, s::Substitution)
    # Aplicar sustitución actual
    t1 = apply_substitution(t1, s)
    t2 = apply_substitution(t2, s)
    
    if t1 == t2
        return s
    elseif t1 isa Var_FOL
        return occurs_check(t1, t2) ? nothing : compose_substitutions(s, Substitution(Dict(t1.name => t2)))
    elseif t2 isa Var_FOL
        return occurs_check(t2, t1) ? nothing : compose_substitutions(s, Substitution(Dict(t2.name => t1)))
    elseif t1 isa Func_FOL && t2 isa Func_FOL && t1.name == t2.name && length(t1.args) == length(t2.args)
        current_s = s
        for (arg1, arg2) in zip(t1.args, t2.args)
            current_s = UMG_terms(arg1, arg2, current_s)
            if current_s === nothing
                return nothing
            end
        end
        return current_s
    else
        return nothing
    end
end

"""
    occurs_check(var::Var_FOL, term::Term)

Verifica si una variable ocurre en un término.

El **occurs check** es esencial para evitar sustituciones que crearían
términos infinitos. Por ejemplo, la sustitución {X → f(X)} crearía un
término infinito f(f(f(...))).

# Argumentos
- `var::Var_FOL` - Variable a buscar
- `term::Term` - Término donde buscar

# Retorna
- `true` - Si `var` ocurre en `term`
- `false` - Si `var` NO ocurre en `term`

# Ejemplos
```julia
x = var("x")

# Variable ocurre en sí misma
occurs_check(x, x)  # true

# Variable ocurre en función
occurs_check(x, func("f", x))  # true

# Variable NO ocurre
occurs_check(x, const_("a"))  # false
occurs_check(x, var("y"))     # false
```

# Complejidad
O(n) donde n es el tamaño del término.
"""
function occurs_check(var::Var_FOL, term::Term)
    if term isa Var_FOL
        return var == term
    elseif term isa Func_FOL
        return any(occurs_check(var, arg) for arg in term.args)
    else
        return false
    end
end

"""
    UMG(p1::Predicate_FOL, p2::Predicate_FOL)

Calcula el UMG de dos predicados.

Los predicados son unificables si tienen el mismo nombre, la misma aridad,
y sus argumentos son unificables par a par.

# Argumentos
- `p1`, `p2` - Predicados a unificar

# Retorna
- `Substitution` - El UMG si existe
- `nothing` - Si los predicados no son unificables

# Ejemplos
```julia
# Unificación exitosa
p1 = pred("Loves", var("X"), var("Y"))
p2 = pred("Loves", const_("John"), const_("Mary"))
UMG(p1, p2)  # {X → John, Y → Mary}

# Falla por nombre diferente
p1 = pred("P", var("X"))
p2 = pred("Q", var("X"))
UMG(p1, p2)  # nothing

# Falla por aridad diferente
p1 = pred("P", var("X"))
p2 = pred("P", var("X"), var("Y"))
UMG(p1, p2)  # nothing
```
"""
function UMG(p1::Predicate_FOL, p2::Predicate_FOL)
    if p1.name != p2.name || length(p1.args) != length(p2.args)
        return nothing
    end
    
    current_s = Substitution()
    for (arg1, arg2) in zip(p1.args, p2.args)
        current_s = UMG_terms(arg1, arg2, current_s)
        if current_s === nothing
            return nothing
        end
    end
    return current_s
end


end

