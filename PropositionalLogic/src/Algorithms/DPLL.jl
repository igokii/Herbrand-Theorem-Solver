"""
# Algorithms.DPLL - Algoritmo Davis-Putnam-Logemann-Loveland

Este submódulo implementa el algoritmo DPLL completo para la verificación
de satisfactibilidad de fórmulas en forma normal conjuntiva (CNF).

## Descripción del algoritmo:
El DPLL es un procedimiento completo y eficiente para el problema SAT
que utiliza técnicas de poda y propagación para evitar búsqueda exhaustiva.

## Técnicas implementadas:
- Propagación unitaria (Unit Propagation)
- Eliminación de literales puros (Pure Literal Elimination)
- Backtracking sistemático con poda
- Detección temprana de insatisfactibilidad

## Aplicaciones:
- Verificación de satisfactibilidad (SAT)
- Búsqueda de modelos
- Verificación de consecuencia lógica
- Análisis de argumentos lógicos

## Autor: Fernando Sancho Caparrini
## Curso: Lógica Informática 2025-2026
"""
module DPLL_module

using ..Types
using ..Evaluation
using ..NormalForms
using ..Properties
import Base: show

export to_CF, clean_CF, apply_val, unit_clauses, pure_literals,
       DPLL, DPLL_SAT, DPLL_solve, DPLL_LC

# ==================== CONVERSIÓN A FORMA CLAUSAL ====================

"""
    to_CF(f::FormulaPL) -> Vector{Clause}

Convierte una fórmula proposicional a Forma Clausal (CF), que es la
representación requerida para el algoritmo DPLL.

# Proceso de conversión:
1. Convierte la fórmula a CNF usando `to_CNF`
2. Extrae las cláusulas individuales
3. Maneja casos especiales (tautologías y contradicciones)

# Retorna
Vector de cláusulas donde cada cláusula es una disyunción de literales.

# Casos especiales:
- Tautología: Vector vacío (automáticamente satisfecho)
- Contradicción: Vector con cláusula vacía (inmediatamente insatisfactible)

# Ejemplos
```julia
p, q = vars("p", "q")
formula = (p | q) & (!p | q)
clauses = to_CF(formula)  # Vector con dos cláusulas
```
"""
function to_CF(f::FormulaPL)
    f_cnf = to_CNF(f)
    if f_cnf === nothing
        return Clause[]  # Fórmula tautológica
    elseif f_cnf == ⊥
        return [Clause(Set{Literal}())]  # Cláusula vacía para contradicción
    elseif f_cnf == ⊤
        return Clause[]  # Sin cláusulas para tautología
    end
    
    # Usar las funciones de NormalForms
    clauses = extract_clauses_from_CNF(f_cnf)
    return collect(clauses)
end

"""
    vars_of(Cs::Vector{Clause}) -> Vector{Var_PL}

Extrae todas las variables que aparecen en un conjunto de cláusulas.
Utilizada internamente por DPLL para determinar qué variables necesitan asignación.

# Argumentos
- `Cs`: Vector de cláusulas

# Retorna
Vector de variables proposicionales (puede contener duplicados).

# Uso en DPLL
Esta función ayuda a identificar:
- Variables no asignadas que requieren decisión de ramificación
- El universo de variables sobre el cual buscar literales puros
"""
function vars_of(Cs::Vector{Clause})
    return [L.variable for C in Cs for L in C.literals]
end

"""
    apply_val(Cs::Vector{Clause}, var::Var_PL, value::Bool) -> Vector{Clause}

Aplica una asignación de variable a un conjunto de cláusulas, simplificando el problema.

# Funcionamiento:
1. **Cláusulas satisfechas**: Si una cláusula contiene un literal que se hace verdadero,
   la cláusula completa se satisface y se elimina del conjunto.

2. **Literales falsos**: Si un literal se hace falso, se elimina de su cláusula
   (pero la cláusula permanece si tiene otros literales).

3. **Literales inalterados**: Los literales de otras variables se mantienen intactos.

# Argumentos
- `Cs`: Conjunto de cláusulas actual
- `var`: Variable a la que se asigna un valor
- `value`: Valor booleano asignado a la variable

# Retorna
Nuevo conjunto de cláusulas simplificado.

# Ejemplos
```julia
# Cláusulas: {p, q}, {¬p, r}, {p, ¬r}
# Asignación: p = true
# Resultado: {r} (las cláusulas {p,q} y {p,¬r} se satisfacen y eliminan)
```

# Importancia en DPLL
Esta función es crucial para la eficiencia del algoritmo, ya que reduce
progresivamente el tamaño del problema después de cada asignación.
"""
function apply_val(Cs::Vector{Clause}, var::Var_PL, value::Bool)
    new_Cs = Clause[]
    
    for C in Cs
        new_Ls = Set{Literal}()
        C_sat = false  # Flag para indicar si la cláusula se satisface completamente
        
        for L in C.literals
            if L.variable == var
                # Si el literal coincide con la asignación, la cláusula se satisface
                if L.positive == value
                    C_sat = true
                    break  # No necesitamos procesar más literales de esta cláusula
                end
                # Si no coincide, el literal se hace falso y se elimina (no se añade a new_Ls)
            else
                # Mantener literales de otras variables
                push!(new_Ls, L)
            end
        end
        
        # Si la cláusula no se satisfizo completamente, agregar la versión simplificada
        if !C_sat
            push!(new_Cs, Clause(new_Ls))
        end
        # Nota: Si C_sat es true, la cláusula se omite (está satisfecha)
    end
    
    return new_Cs
end

"""
    clean_CF(Cs::Vector{Clause}) -> Vector{Clause}

Elimina cláusulas tautológicas de un conjunto de cláusulas.

# Función
Las cláusulas tautológicas (que contienen un literal y su complemento)
son siempre verdaderas y pueden eliminarse sin afectar la satisfactibilidad.

# Ejemplos
```julia
# Cláusula {p, ¬p, q} es tautológica y se elimina
# Cláusula {p, q} se mantiene
```

# Optimización
Esta función mejora la eficiencia del DPLL al reducir el número de
cláusulas que deben procesarse.
"""
function clean_CF(Cs::Vector{Clause})
    return [C for C in Cs if !is_tautological(C)]
end

"""
    unit_clauses(Cs::Vector{Clause}) -> Vector{Literal}

Encuentra todos los literales unitarios en un conjunto de cláusulas.

# Definición
Una cláusula unitaria contiene exactamente un literal. Estos literales
deben ser asignados como verdaderos para satisfacer la cláusula.

# Propagación unitaria
Esta función es fundamental para la regla de propagación unitaria del DPLL:
- Si una cláusula es unitaria, su único literal debe ser verdadero
- Esta asignación se propaga automáticamente (no requiere decisión)

# Retorna
Vector de literales que aparecen como únicos en sus respectivas cláusulas.

# Ejemplos
```julia
# Cláusulas: {p}, {¬q, r}, {s}
# Literales unitarios: [p, s]
```
"""
function unit_clauses(Cs::Vector{Clause})
    return [first(C.literals) for C in Cs if length(C.literals) == 1]
end

"""
    pure_literals(Cs::Vector{Clause}) -> Vector{Literal}

Encuentra literales puros en un conjunto de cláusulas.

# Definición
Un literal puro es aquel que aparece siempre con la misma polaridad
(solo positivo o solo negativo) en todas las cláusulas.

# Eliminación de literales puros
Los literales puros pueden asignarse como verdaderos sin riesgo:
- Si p es puro positivo, asignar p = true satisface todas las cláusulas que lo contienen
- Si p es puro negativo, asignar p = false satisface todas las cláusulas que lo contienen

# Algoritmo
1. Recopila todas las variables en polaridad positiva y negativa
2. Identifica variables que aparecen solo en una polaridad
3. Crea literales puros correspondientes

# Retorna
Vector de literales puros que pueden ser eliminados del problema.

# Ejemplos
```julia
# Cláusulas: {p, q}, {p, ¬r}, {¬q, s}
# Variables: p (solo positivo), r (solo negativo)
# Literales puros: [p, ¬r]
```
"""
function pure_literals(Cs::Vector{Clause})
    pos_vars = Set{Var_PL}()  # Variables que aparecen positivamente
    neg_vars = Set{Var_PL}()  # Variables que aparecen negativamente
    
    # Recopilar variables por polaridad
    for C in Cs
        for L in C.literals
            if L.positive
                push!(pos_vars, L.variable)
            else
                push!(neg_vars, L.variable)
            end
        end
    end
    
    pure_Ls = Literal[]
    vars = union(pos_vars, neg_vars)
    
    # Literales positivos puros: pos_vars - neg_vars
    # Literales negativos puros: neg_vars - pos_vars
    for var in vars
        if var in pos_vars && !(var in neg_vars)
            push!(pure_Ls, Literal(var, true))
        elseif var in neg_vars && !(var in pos_vars)
            push!(pure_Ls, Literal(var, false))
        end
    end
    
    return pure_Ls
end

# ==================== ALGORITMO DPLL PRINCIPAL ====================

"""
    DPLL(Cs::Vector{Clause}, val::Valuation = Valuation(); verbose::Bool = false, depth::Int = 0) -> (Bool, Valuation)

Implementación principal del algoritmo DPLL para verificación de satisfactibilidad.

# Algoritmo
1. **Casos base**:
   - Sin cláusulas: satisfactible con valoración actual
   - Cláusula vacía: insatisfactible

2. **Propagación unitaria**: Asignación automática de literales unitarios

3. **Eliminación de literales puros**: Asignación de literales puros

4. **Backtracking**: División en dos ramas para variable no asignada

# Argumentos
- `Cs`: Vector de cláusulas en forma clausal
- `val`: Valoración parcial actual (por defecto vacía)
- `verbose`: Activar salida detallada del proceso
- `depth`: Profundidad de recursión (para formato de salida)

# Retorna
Tupla (satisfactible, modelo) donde:
- `satisfactible`: true si la fórmula es satisfactible
- `modelo`: valoración que satisface la fórmula (vacía si insatisfactible)

# Características
- **Completitud**: Siempre termina con la respuesta correcta
- **Eficiencia**: Usa poda para evitar búsqueda exhaustiva
- **Trazado**: Modo verbose para análisis educativo

# Ejemplos
```julia
p, q = vars("p", "q")
formula = (p | q) & (!p | q) & (p | !q)
clauses = to_CF(formula)
satisfactible, modelo = DPLL(clauses, verbose=true)
```
"""
function DPLL(Cs::Vector{Clause}, val::Valuation = Valuation(); verbose::Bool = false, depth::Int = 0)
    # Indentación para mostrar la profundidad de recursión
    indent = "  " ^ depth
    
    if verbose
        println("$(indent)🔍 DPLL - Profundidad $depth")
        println("$(indent)📋 Cláusulas actuales ($(length(Cs))):")
        for (i, C) in enumerate(Cs)
            println("$(indent)  C$i: $C")
        end
        println("$(indent)💾 Valoración actual: $(isempty(val) ? "∅" : val)")
        println()
    end
    
    # Caso base: si no hay cláusulas, la fórmula es satisfactible con la valoración actual
    if isempty(Cs)
        if verbose
            println("$(indent)✅ CASO BASE: No hay cláusulas → SATISFACTIBLE")
            println("$(indent)🎯 Modelo encontrado: $val")
        end
        return true, val
    end
    
    # Si hay una cláusula vacía, la fórmula es insatisfactible.
    for (i, C) in enumerate(Cs)
        if isempty(C.literals)
            if verbose
                println("$(indent)❌ CLÁUSULA VACÍA DETECTADA: C$i → INSATISFACTIBLE")
                println("$(indent)⬅️  Retrocediendo...")
            end
            return false, Valuation()
        end
    end
    
    # Propagación de literales unitarios
    unit_lits = unit_clauses(Cs)
    if !isempty(unit_lits)
        L = first(unit_lits)
        if verbose
            println("$(indent)🔄 PROPAGACIÓN UNITARIA detectada:")
            println("$(indent)  📌 Literal unitario: $L")
            println("$(indent)  ⚡ Asignando $(L.variable) = $(L.positive ? "1" : "0")")
        end
        
        new_val = copy(val)
        new_val[L.variable] = L.positive
        new_Cs = apply_val(Cs, L.variable, L.positive)
        
        if verbose
            println("$(indent)  📝 Nueva valoración: $new_val")
            println("$(indent)  ↪️  Aplicando y continuando recursión...")
            println()
        end
        
        return DPLL(new_Cs, new_val, verbose=verbose, depth=depth+1)
    end
    
    # Eliminación de literales puros
    pure_Ls = pure_literals(Cs)
    if !isempty(pure_Ls)
        L = first(pure_Ls)
        if verbose
            println("$(indent)🧹 ELIMINACIÓN DE LITERAL PURO:")
            println("$(indent)  🎯 Literal puro: $L")
            println("$(indent)  ⚡ Asignando $(L.variable) = $(L.positive ? "1" : "0")")
        end
        
        new_val = copy(val)
        new_val[L.variable] = L.positive
        new_Cs = apply_val(Cs, L.variable, L.positive)
        
        if verbose
            println("$(indent)  📝 Nueva valoración: $new_val")
            println("$(indent)  ↪️  Aplicando y continuando recursión...")
            println()
        end
        
        return DPLL(new_Cs, new_val, verbose=verbose, depth=depth+1)
    end

    # Si no hay literales unitarios ni puros, procedemos a la división
    
    # Backtracking: elegir una variable y probar ambos valores
    vars = vars_of(Cs)
    unassigned_vars = setdiff(vars, keys(val))
    
    if isempty(unassigned_vars)
        if verbose
            println("$(indent)✅ TODAS LAS VARIABLES ASIGNADAS → SATISFACTIBLE")
            println("$(indent)🎯 Modelo final: $val")
        end
        return true, val
    end
    
    # Elegir una variable no asignada (puede ser aleatoria o la primera)
    #  Aquí se puede implementar una heurística más avanzada si se desea
    chosen_var = first(unassigned_vars)
    
    if verbose
        println("$(indent)🔀 DIVISIÓN (BACKTRACKING):")
        println("$(indent)  🎲 Variable elegida: $chosen_var")
        println("$(indent)  📊 Variables no asignadas: $(length(unassigned_vars))")
        println("$(indent)  ⚖️  Probando ambos valores...")
        println()
    end
    
    # Probar con valor true
    if verbose
        println("$(indent)🔵 RAMA IZQUIERDA: $chosen_var = 1")
    end
    
    new_val_true = copy(val)
    new_val_true[chosen_var] = true
    new_Cs_true = apply_val(Cs, chosen_var, true)
    
    if verbose
        println("$(indent)  📝 Valoración temporal: $new_val_true")
        println("$(indent)  ↪️  Explorando rama...")
        println()
    end
    
    satisfiable_true, result_val = DPLL(new_Cs_true, new_val_true, verbose=verbose, depth=depth+1)
    
    if satisfiable_true
        if verbose
            println("$(indent)✅ RAMA IZQUIERDA EXITOSA → Modelo encontrado")
        end
        return true, result_val
    end
    
    if verbose
        println("$(indent)❌ RAMA IZQUIERDA FALLÓ")
        println("$(indent)🔴 RAMA DERECHA: $chosen_var = 0")
    end
    
    # Probar con valor false
    new_val_false = copy(val)
    new_val_false[chosen_var] = false
    new_Cs_false = apply_val(Cs, chosen_var, false)
    
    if verbose
        println("$(indent)  📝 Valoración temporal: $new_val_false")
        println("$(indent)  ↪️  Explorando rama...")
        println()
    end
    
    satisfiable_false, result_val_false = DPLL(new_Cs_false, new_val_false, verbose=verbose, depth=depth+1)
    
    if verbose
        if satisfiable_false
            println("$(indent)✅ RAMA DERECHA EXITOSA → Modelo encontrado")
        else
            println("$(indent)❌ RAMA DERECHA FALLÓ")
            println("$(indent)💥 AMBAS RAMAS FALLARON → INSATISFACTIBLE en este nivel")
        end
    end
    
    return satisfiable_false, result_val_false
end

# ==================== FUNCIONES DE INTERFAZ ====================

"""
    DPLL(f::FormulaPL; verbose::Bool = false) -> Bool

Verifica si una fórmula es satisfactible usando el algoritmo DPLL.

# Argumentos
- `f`: Fórmula proposicional a verificar
- `verbose`: Mostrar proceso detallado del algoritmo

# Retorna
`true` si la fórmula es satisfactible, `false` en caso contrario.

# Ejemplos
```julia
p, q = vars("p", "q")
formula = (p & q) | (!p & !q)
result = DPLL_SAT(formula, verbose=true)
```
"""
function DPLL(f::FormulaPL; verbose::Bool = false)
    try
        if verbose
            println("=== APLICACIÓN DE DPLL A FORMULAS ===")
            println("Fórmula: $f")
            println("=" ^ 50)
        end
        
        Cs = to_CF(f)
        
        if verbose
            println("Forma clausal generada:")
            for (i, C) in enumerate(Cs)
                println("  C$i: $C")
            end
            println()
            println("Iniciando algoritmo DPLL...")
            println()
        end
        
        satisfiable, model = DPLL(Cs, verbose=verbose)
        
        if verbose
            println()
            println("=== RESULTADO FINAL ===")
            println("Fórmula: $f")
            println("Satisfactible: $(satisfiable ? "✅ SÍ" : "❌ NO")")
            if satisfiable
                println("Modelo encontrado: $model")
            end
            println("=" ^ 50)
        end
        
        return satisfiable, model
    catch e
        println("Error al convertir a FNC o aplicar DPLL: $e")
        return false, Valuation()
    end
end

"""
    DPLL(Γ::Vector{FormulaPL}) -> (Bool, valuation)

Verifica si un conjunto de fórmulas es satisfactible usando el algoritmo DPLL.

# Argumentos
- `Γ`: Conjunto de fórmulas proposicionales a verificar

# Retorna
`true` si la fórmula es satisfactible, `false` en caso contrario.

# Ejemplos
```julia
Γ= [p & q, !p & !q]
sat, sol = DPLL(Γ)
```
"""
function DPLL(Γ::Vector{FormulaPL})
   Cs = reduce(vcat, map(to_CF,Γ))        
   satisfiable, model = DPLL(Cs)        
   return satisfiable, model
end

# ==================== CONSECUENCIA LÓGICA CON DPLL ====================

function DPLL_LC(Γ::Vector{FormulaPL}, φ::FormulaPL; verbose::Bool = false)
    if verbose
        println("=== VERIFICACIÓN DE CONSECUENCIA LÓGICA CON DPLL ===")
        println("Premisas:")
        for (i, F) in enumerate(Γ)
            println("  F$i: $F")
        end
        println("Conclusión: $φ")
        println("Verificando si Γ ∪ {¬φ} es insatisfactible...")
        println()
    end
    
    # Crear Γ ∧ ¬φ
    test_formula = ⋀(Γ) & !(φ)
    
    if verbose
        println("Fórmula de prueba: $test_formula")
        println()
    end
    
    try
        Cs = to_CF(test_formula)
        satisfiable, val = DPLL(Cs, verbose=verbose)
        
        is_consequence = !satisfiable
        
        if verbose
            println()
            println("=== RESULTADO CONSECUENCIA LÓGICA ===")
            println("Γ ∪ {¬φ} es $(satisfiable ? "SATISFACTIBLE" : "INSATISFACTIBLE")")
            println("Por tanto, Γ ⊨ φ es $(is_consequence ? "✅ VERDADERO" : "❌ FALSO")")
            if satisfiable
                println("Contraejemplo encontrado: $val")
            end
        end
        
        return is_consequence        
    catch e
        println("Error al procesar con DPLL: $e")
        # Fallback a método directo usando Properties
        return LC_RA(Γ, φ)
    end
end

"""
    DPLL_LC(F::FormulaPL, φ::FormulaPL; verbose::Bool = false) -> Bool

Función auxiliar para verificar consecuencia lógica con una sola premisa.

# Ejemplos
```julia
p, q = vars("p", "q")
premisa = p > q
conclusion = (!q) > (!p)  # Contrapositiva
es_consecuencia = DPLL_LC(premisa, conclusion)
```
"""
function DPLL_LC(F::FormulaPL, φ::FormulaPL; verbose::Bool = false)
    return DPLL_LC([F], φ, verbose=verbose)
end

end # module DPLL
