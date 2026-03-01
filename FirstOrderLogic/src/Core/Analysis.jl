module Analysis

# ════════════════════════════════════════════════════════════════════════════
# PARTE 2: ANÁLISIS Y MANIPULACIÓN DE FÓRMULAS
# ════════════════════════════════════════════════════════════════════════════
using ..Types
export free_vars, subformulas, formation_tree

# ──────────────────────────────────────────────────────────────────────────
# 2.1 Subfórmulas y árbol de formación
# ──────────────────────────────────────────────────────────────────────────

"""
    subformulas(f::FOLFormula) -> Set{FOLFormula}

Obtiene todas las subfórmulas de una fórmula FOL dada.

# Definición
Una subfórmula de φ es cualquier fórmula que aparece como componente de φ,
incluyendo la propia φ.

# Ejemplos
```julia
x = var("x")
P, Q = predicates("P", "Q")
formula = P(x) & Q(x)
subs = subformulas(formula)  # {P(x), Q(x), P(x) ∧ Q(x)}
```

# Funcionamiento
- Predicados son subfórmulas de sí mismos
- Para operadores unarios: subfórmulas del operando + la fórmula completa
- Para operadores binarios: subfórmulas de ambos operandos + la fórmula completa
- Para cuantificadores: subfórmulas del cuerpo + la fórmula completa

# Nota
El resultado incluye siempre la fórmula original como subfórmula de sí misma.
"""
function subformulas(f::FOLFormula)
    if isa(f, Predicate_FOL)
        return Set([f])
    elseif isa(f, NotFOL)
        return union(subformulas(f.operand), Set([f]))
    elseif isa(f, Union{AndFOL, OrFOL, ImpliesFOL, IffFOL})
        return union(subformulas(f.left), subformulas(f.right), Set([f]))
    elseif isa(f, Union{Forall, Exists})
        return union(subformulas(f.body), Set([f]))
    else
        return Set{FOLFormula}()
    end
end 

"""
    formation_tree(f::FOLFormula, prefix::String, is_last::Bool) -> String

Genera una representación visual del árbol de formación de una fórmula FOL.
Muestra la estructura jerárquica de la fórmula con formato de árbol ASCII.

# Ejemplos de salida
```
Para P(x) ∧ Q(x):
∧
├── P(x)
└── Q(x)

Para (P(x) ∧ Q(x)) ∨ R(y):
∨
├── ∧
│   ├── P(x)
│   └── Q(x)
└── R(y)

Para ∀x.P(x):
∀x
└── P(x)
```

# Argumentos
- `f`: Fórmula a visualizar
- `prefix`: Prefijo para la indentación (uso interno)
- `is_last`: Si es el último hijo en el nivel actual (uso interno)

# Funcionamiento
- Operadores aparecen como nodos internos
- Predicados aparecen como hojas
- Cuantificadores muestran la variable cuantificada
- Usa caracteres Unicode para dibujar las conexiones del árbol
"""
function formation_tree(f::FOLFormula, prefix::String, is_last::Bool)
    if isa(f, Predicate_FOL)
        return string(f)
    elseif isa(f, NotFOL)
        # Para negaciones simples, mostrar en una línea
        if isa(f.operand, Predicate_FOL)
            return "¬ $(f.operand)"
        else
            # Para negaciones complejas, crear subárbol
            operand_tree = formation_tree(f.operand, prefix * "    ", true)
            return "¬\n$(prefix)└── $operand_tree"
        end
    elseif isa(f, Forall)
        # Para cuantificadores universales
        body_tree = formation_tree(f.body, prefix * "    ", true)
        return "∀$(f.var)\n$(prefix)└── $body_tree"
    elseif isa(f, Exists)
        # Para cuantificadores existenciales
        body_tree = formation_tree(f.body, prefix * "    ", true)
        return "∃$(f.var)\n$(prefix)└── $body_tree"
    else
        # Para operadores binarios
        operator = if isa(f, AndFOL)
            "∧"
        elseif isa(f, OrFOL)
            "∨"
        elseif isa(f, ImpliesFOL)
            "→"
        elseif isa(f, IffFOL)
            "↔"
        end
        
        # Construir prefijos para los hijos (manejo de indentación)
        left_prefix  = prefix * "│   "   # Continúa la línea vertical
        right_prefix = prefix * "    "   # Espacio en blanco (último hijo)
        
        # Construir árboles para los operandos recursivamente
        left_tree = formation_tree(f.left, left_prefix, false)
        right_tree = formation_tree(f.right, right_prefix, true)
        
        # Formatear la salida con caracteres de conexión
        left_part  = "├── $left_tree"   
        # Rama izquierda (no es la última)
        right_part = "└── $right_tree"  # Rama derecha (es la última)
        
        return "$operator\n$prefix$left_part\n$prefix$right_part"
    end
end

"""
    formation_tree(f::FOLFormula)

Versión de conveniencia que imprime directamente el árbol de formación de una fórmula FOL.
Llama a la versión completa con parámetros por defecto y muestra el resultado.

# Ejemplos
```julia
x, y = vars("x", "y")
P, Q, R = predicates("P", "Q", "R")

# Fórmula simple
formation_tree(P(x) & Q(x))

# Fórmula con cuantificadores
formation_tree(∀(x, P(x) > Q(x)))

# Fórmula compleja
formula = ∀(x, P(x) > ∃(y, Q(x, y)))
formation_tree(formula)
```

# Descripción
Esta función es útil para:
- Visualizar la estructura sintáctica de fórmulas FOL
- Entender la precedencia de operadores
- Analizar el alcance de cuantificadores
- Depurar fórmulas complejas
"""
function formation_tree(f::FOLFormula)
    println(formation_tree(f, "", true))
end

# ──────────────────────────────────────────────────────────────────────────
# 2.2 Variables Libres
# ──────────────────────────────────────────────────────────────────────────

"""
    free_vars(f::FOLFormula, bound::Set{String} = Set{String}())::Set{String}

Calcula el conjunto de **variables libres** en una fórmula de lógica de primer orden.

Una variable es **libre** si aparece en la fórmula pero NO está ligada por un cuantificador.

# Parámetros
- `f::FOLFormula`: La fórmula lógica a analizar
- `bound::Set{String}`: Conjunto de variables que ya están ligadas (por cuantificadores exteriores)
  Por defecto es vacío (se asume que no hay variables ligadas al inicio)

# Devoluciones
- `Set{String}`: Conjunto con los nombres de todas las variables libres encontradas

# Ejemplos
```julia
# Fórmula: P(x, y)
# Ambas variables son libres (sin cuantificadores)
formula = P(x,y)
free_vars(formula)  # Set(["x", "y"])

# Fórmula: ∀x. P(x, y)
# Solo y es libre (x está ligada por ∀)
formula = ∀(x, P(x, y))
free_vars(formula)  # Set(["y"])

# Fórmula: ∀x. P(x, y) ∧ Q(z)
# y y z son libres
formula = ∀(x, P(x, y) & Q(z))
free_vars(formula)  # Set(["y", "z"])
```

# Detalles de Implementación
- Para **predicados**: extrae variables libres de todos sus argumentos
- Para **negación**: busca libres en el operando
- Para **conectivas binarias** (∧,∨,→,↔): combina libres de izquierda y derecha
- Para **cuantificadores** (∀,∃): añade la variable cuantificada a `bound` y busca en el cuerpo
  
# Casos Base
- Predicado sin variables: devuelve `Set{String}()`
- Variable en contexto ligado: no se incluye en libres
- Constante: devuelve `Set{String}()`
"""
function free_vars(f::FOLFormula, bound::Set{String} = Set{String}())
    if f isa Predicate_FOL
        vars = Set{String}()
        for arg in f.args
            union!(vars, free_vars_term(arg, bound))
        end
        return vars
    elseif f isa NotFOL
        return free_vars(f.operand, bound)
    elseif f isa AndFOL || f isa OrFOL || f isa ImpliesFOL || f isa IffFOL
        left_vars = free_vars(f.left, bound)
        right_vars = free_vars(f.right, bound)
        return union(left_vars, right_vars)
    elseif f isa Forall || f isa Exists
        new_bound = union(bound, Set([f.var.name]))
        return free_vars(f.body, new_bound)
    else
        return Set{String}()
    end
end

"""
    free_vars_term(t::Term, bound::Set{String} = Set{String}())::Set{String}

Calcula el conjunto de **variables libres** en un término lógico.

Un término puede ser una **variable**, una **constante**, o una **función aplicada a términos**.

# Parámetros
- `t::Term`: El término a analizar (puede ser `Var_FOL`, `Const_FOL` o `Func_FOL`)
- `bound::Set{String}`: Conjunto de variables ligadas por cuantificadores exteriores
  Por defecto es vacío

# Devoluciones
- `Set{String}`: Conjunto con los nombres de todas las variables libres en el término

# Ejemplos
```julia
# Término: x (variable)
term = x
free_vars_term(term)  # Set(["x"])

# Término: a (constante)
term = a
free_vars_term(term)  # Set()

# Término: f(x, y) (función con dos variables)
term = f(x, y)
free_vars_term(term)  # Set(["x", "y"])

# Término: f(g(x), c) (composición de funciones)
term = f(g(x), c)
free_vars_term(term)  # Set(["x"])

# Término: x con x ligada por cuantificador externo
term = x
bound = Set(["x"])
free_vars_term(term, bound)  # Set() - x NO es libre (está ligada)
```

# Detalles de Implementación
- **Variable** (`Var_FOL`):
  - Si está en `bound`: no es libre → devuelve `Set()`
  - Si no está en `bound`: es libre → devuelve `Set([nombre])`
  
- **Función** (`Func_FOL`): 
  - Busca recursivamente variables libres en todos sus argumentos
  - Combina resultados con `union!`
  
- **Constante** (`Const_FOL`): 
  - No contiene variables → devuelve `Set()`

# Casos de Uso
- Verificar si una fórmula es **cerrada** (sin variables libres)
- Identificar qué variables deben ser **universalmente cuantificadas**
- Detectar **variables frescas** para renombramiento
- Validar **sustituciones** (solo se sustituyen variables libres)
- Análisis de **alcance de variables**

# Relación con `free_vars`
Esta función es utilizada internamente por `free_vars` para procesar los argumentos
de predicados y funciones dentro de fórmulas lógicas.
"""
function free_vars_term(t::Term, bound::Set{String} = Set{String}())
    if t isa Var_FOL
        return t.name in bound ? Set{String}() : Set([t.name])
    elseif t isa Func_FOL
        vars = Set{String}()
        for arg in t.args
            union!(vars, free_vars_term(arg, bound))
        end
        return vars
    else  # Const
        return Set{String}()
    end
end

end