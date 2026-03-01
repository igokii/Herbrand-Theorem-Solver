module Parser

# ──────────────────────────────────────────────────────────────────────────
# 3.5 PARSING - Parseador de fórmulas matemáticas
# ──────────────────────────────────────────────────────────────────────────
using ..Types
export parse_formula, @parse

# -------------------------------------------------------------------
# 1.11 Parsing: Strings a fórmulas y Macros
# -------------------------------------------------------------------

"""
    parse_formula(s::String)::FOLFormula

Parsea una fórmula en formato matemático y la convierte a tipos formales.

**Función más flexible**: Acepta múltiples sintaxis equivalentes, incluyendo
espacios, puntos, y diferentes notaciones para cuantificadores.

# Sintaxis Soportadas

## Cuantificadores (todas válidas):
- `∀x.P(x)` - Universal con punto
- `∀x (P(x))` - Universal con espacio
- `∀(x, P(x))` - Universal con coma  
- `forall x. P(x)` - Palabra con punto
- Similar para `∃`, `exists`

## Conectivas:
- `∧` o `&` - Conjunción
- `∨` o `|` - Disyunción  
- `¬` o `!` - Negación
- `→` o `>` - Implicación
- `↔` o `~` - Bicondicional

## Términos:
- Variables: `x, y, z, x1, var_name` (minúsculas)
- Constantes: `a, b, c, 0, 1, ABC` (mayúsculas/números)
- Funciones: `f(x), g(a,b), h(x,f(y))`
- Predicados: `P(x), Q(a,b), R(x,y,z)`

# Ejemplos
```julia
# Diferentes sintaxis de cuantificadores (todas válidas)
parse_formula("∀x.P(x)")                    # Con punto
parse_formula("∀x (P(x))")                  # Con espacio
parse_formula("∀(x, P(x))")                 # Con coma
parse_formula("forall x. P(x)")             # Palabra inglesa

# Fórmulas complejas
parse_formula("∀x.(P(x) ∧ Q(x))")
parse_formula("∃x (P(x) & ∀y (Q(y) > R(x,y)))")
parse_formula("forall x. P(x) | exists y. Q(x,y)")

# Con funciones
parse_formula("∀x.P(f(x))")
parse_formula("∃x.∃y.(P(x,y) & Q(f(x), g(y)))")
```

# Comparación con @parse
- **parse_formula("")**: Sintaxis flexible, acepta espacios y puntos
- **@parse**: Sintaxis estricta de Julia, requiere `∀(x, ...)` sin espacios

Ver documentación de `@parse` para más detalles.
"""
function parse_formula(s::String)::FOLFormula
    # Limpiar espacios y normalizar
    s = strip(s)
    s = replace(s, r"\s+" => " ")  # Espacios múltiples → uno
    
    # Normalizar símbolos
    s = replace(s, "↔" => "~")
    s = replace(s, "→" => ">")
    s = replace(s, "¬" => "!")
    s = replace(s, "∧" => "&")
    s = replace(s, "∨" => "|")
    s = replace(s, "∀" => "forall ")
    s = replace(s, "∃" => "exists ")
    
    # Tokenizar
    tokens = tokenize(s)
    
    # Parsear
    result, pos = parse_expr(tokens, 1)
    
    if pos <= length(tokens)
        error("Tokens no consumidos: $(tokens[pos:end])")
    end
    
    return result
end

"""
    tokenize(s::String) -> Vector{String}

Convierte una cadena de texto en una lista de tokens para el parser.

# Proceso
1. Elimina caracteres de control
2. Inserta espacios alrededor de paréntesis, comas y puntos
3. Divide por espacios
4. Filtra tokens vacíos

# Ejemplos
```julia
tokenize("∀x.P(x)")          # ["forall", "x", ".", "P", "(", "x", ")"]
tokenize("P(a,b) & Q(c)")    # ["P", "(", "a", ",", "b", ")", "&", "Q", "(", "c", ")"]
tokenize("forall x (P(x))")  # ["forall", "x", "(", "P", "(", "x", ")", ")"]
```

# Detalles
- Los símbolos especiales (paréntesis, comas, puntos) se separan como tokens individuales
- Múltiples espacios se normalizan
- Se eliminan caracteres de control (\x00-\x1f)
"""
function tokenize(s::String)::Vector{String}
    # Limpiar caracteres especiales
    s = replace(s, r"[\x00-\x1f]" => " ")  # Eliminar caracteres de control
    
    # Reemplazar símbolos especiales con espacios
    # NOTA: Usar replace con String, no con \1 (backreference)
    s = replace(s, "(" => " ( ")
    s = replace(s, ")" => " ) ")
    s = replace(s, "," => " , ")
    s = replace(s, "." => " . ")
    
    # Separar en tokens
    tokens = split(s)
    
    # Filtrar espacios vacíos
    tokens = filter(t -> !isempty(t) && t != " ", tokens)
    
    return tokens
end

"""
    parse_expr(tokens::Vector{String}, pos::Int) -> Tuple{FOLFormula, Int}

Parsea una fórmula completa desde una lista de tokens usando análisis recursivo descendente.

Esta es la función de nivel más alto del parser recursivo. Procesa disyunciones (|)
y delega a niveles inferiores para otros operadores.

# Argumentos
- `tokens`: Lista de tokens a parsear
- `pos`: Posición actual en la lista de tokens (1-indexado)

# Retorna
- Tupla `(fórmula, nueva_posición)` donde:
  - `fórmula`: FOLFormula parseada
  - `nueva_posición`: Siguiente posición no consumida

# Jerarquía de Precedencia (menor a mayor)
1. Disyunción (|, ∨) - Este nivel
2. Conjunción (&, ∧) - parse_and
3. Implicación/Bicondicional (>, →, ~, ↔) - parse_implies
4. Negación (!, ¬) - parse_not
5. Cuantificadores (∀, ∃) - parse_quantifier
6. Términos atómicos - parse_primary

# Ejemplos
```julia
tokens = ["P", "(", "x", ")", "|", "Q", "(", "y", ")"]
parse_expr(tokens, 1)  # (P(x) ∨ Q(y), 9)

tokens = ["P", "(", "a", ")", "&", "Q", "(", "b", ")"]
parse_expr(tokens, 1)  # (P(a) ∧ Q(b), 9)
```
"""
function parse_expr(tokens::Vector{String}, pos::Int)
    # Parsear nivel más bajo: disyunción
    left, pos = parse_and(tokens, pos)
    
    while pos <= length(tokens) && tokens[pos] in ["|", "∨"]
        pos += 1
        right, pos = parse_and(tokens, pos)
        left = OrFOL(left, right)
    end
    
    return left, pos
end

"""
    parse_and(tokens::Vector{String}, pos::Int) -> Tuple{FOLFormula, Int}

Parsea conjunciones (&, ∧) en el análisis recursivo descendente.

Procesa expresiones de la forma `A ∧ B ∧ C ...` con asociatividad izquierda.

# Argumentos
- `tokens`: Lista de tokens
- `pos`: Posición actual en tokens

# Retorna
- `(fórmula, nueva_posición)`: Fórmula parseada y siguiente posición

# Asociatividad
`A ∧ B ∧ C` se parsea como `(A ∧ B) ∧ C` (asocia a izquierda)

# Ejemplos
```julia
# P(x) & Q(y) & R(z)  →  ((P(x) ∧ Q(y)) ∧ R(z))
tokens = ["P", "(", "x", ")", "&", "Q", "(", "y", ")", "&", "R", "(", "z", ")"]
parse_and(tokens, 1)
```
"""
function parse_and(tokens::Vector{String}, pos::Int)
    # Parsear conjunción
    left, pos = parse_implies(tokens, pos)
    
    while pos <= length(tokens) && tokens[pos] in ["&", "∧"]
        pos += 1
        right, pos = parse_implies(tokens, pos)
        left = AndFOL(left, right)
    end
    
    return left, pos
end

"""
    parse_implies(tokens::Vector{String}, pos::Int) -> Tuple{FOLFormula, Int}

Parsea implicaciones (>, →) y bicondicionales (~, ↔) en el análisis recursivo descendente.

Procesa expresiones con implicación y equivalencia, ambas con asociatividad derecha.

# Argumentos
- `tokens`: Lista de tokens
- `pos`: Posición actual en tokens

# Retorna
- `(fórmula, nueva_posición)`: Fórmula parseada y siguiente posición

# Operadores
- `>` o `→`: Implicación (A → B)
- `~` o `↔`: Bicondicional (A ↔ B)

# Asociatividad
`A → B → C` se parsea como `A → (B → C)` (asocia a derecha)

# Ejemplos
```julia
# P(x) > Q(y)  →  P(x) → Q(y)
tokens = ["P", "(", "x", ")", ">", "Q", "(", "y", ")"]
parse_implies(tokens, 1)

# P(x) ~ Q(y)  →  P(x) ↔ Q(y)
tokens = ["P", "(", "x", ")", "~", "Q", "(", "y", ")"]
parse_implies(tokens, 1)
```
"""
function parse_implies(tokens::Vector{String}, pos::Int)
    # Parsear implicación y bicondicional
    left, pos = parse_not(tokens, pos)
    
    if pos <= length(tokens) && tokens[pos] in [">", "→"]
        pos += 1
        right, pos = parse_implies(tokens, pos)  # Asocia a derecha
        left = ImpliesFOL(left, right)
    elseif pos <= length(tokens) && tokens[pos] in ["~", "↔"]
        pos += 1
        right, pos = parse_implies(tokens, pos)
        left = IffFOL(left, right)
    end
    
    return left, pos
end

"""
    parse_not(tokens::Vector{String}, pos::Int) -> Tuple{FOLFormula, Int}

Parsea negaciones (!, ¬) en el análisis recursivo descendente.

Procesa el operador de negación, permitiendo negaciones anidadas.

# Argumentos
- `tokens`: Lista de tokens
- `pos`: Posición actual en tokens

# Retorna
- `(fórmula, nueva_posición)`: Fórmula parseada y siguiente posición

# Operadores aceptados
- `!`: Negación (notación programática)
- `¬`: Negación (notación lógica)
- `-`: Negación (alternativa)

# Recursión
La función es recursiva para manejar dobles negaciones: `!!P(x)` → `¬¬P(x)`

# Ejemplos
```julia
# !P(x)  →  ¬P(x)
tokens = ["!", "P", "(", "x", ")"]
parse_not(tokens, 1)

# !!P(x)  →  ¬¬P(x)
tokens = ["!", "!", "P", "(", "x", ")"]
parse_not(tokens, 1)
```
"""
function parse_not(tokens::Vector{String}, pos::Int)
    # Parsear negación
    if pos <= length(tokens) && tokens[pos] in ["!", "¬", "-"]
        pos += 1
        operand, pos = parse_not(tokens, pos)  # Recursivo para !!p
        return NotFOL(operand), pos
    end
    
    return parse_quantifier(tokens, pos)
end

"""
    parse_quantifier(tokens::Vector{String}, pos::Int) -> Tuple{FOLFormula, Int}

Parsea cuantificadores universales (∀, forall) y existenciales (∃, exists).

Maneja múltiples sintaxis para cuantificadores:
- Con paréntesis: `forall(x, P(x))`
- Con punto: `forall x. P(x)`
- Con espacio: `forall x (P(x))`
- Con coma: `forall x, P(x)`

# Argumentos
- `tokens`: Lista de tokens
- `pos`: Posición actual en tokens

# Retorna
- `(fórmula, nueva_posición)`: Fórmula cuantificada y siguiente posición

# Cuantificadores reconocidos
- `∀` o `forall`: Universal
- `∃` o `exists`: Existencial

# Sintaxis soportadas
```julia
# Todas estas son equivalentes:
"∀x.P(x)"           # Con punto
"∀x (P(x))"         # Con espacio
"∀(x, P(x))"        # Con paréntesis y coma
"forall x. P(x)"    # Palabra con punto
```

# Ejemplos
```julia
tokens = ["forall", "x", ".", "P", "(", "x", ")"]
parse_quantifier(tokens, 1)  # ∀x.P(x)

tokens = ["exists", "y", ",", "Q", "(", "y", ")"]
parse_quantifier(tokens, 1)  # ∃y.Q(y)
```
"""
function parse_quantifier(tokens::Vector{String}, pos::Int)
    # Parsear cuantificadores
    if pos <= length(tokens)
        token = tokens[pos]
        
        if token in ["forall", "∀"]
            pos += 1
            
            # Verificar si usa sintaxis con paréntesis: forall(x, ...)
            has_opening_paren = false
            if pos <= length(tokens) && tokens[pos] == "("
                has_opening_paren = true
                pos += 1
            end
            
            # Extraer variable
            if pos > length(tokens)
                error("Se esperaba variable después de forall")
            end
            var_name = tokens[pos]
            pos += 1
            
            # Ignorar punto o coma después de la variable
            if pos <= length(tokens) && tokens[pos] in [".", ","]
                pos += 1
            end
            
            # Parsear cuerpo
            body, pos = parse_expr(tokens, pos)
            
            # Solo consumir paréntesis de cierre si se abrió uno para el cuantificador
            if has_opening_paren && pos <= length(tokens) && tokens[pos] == ")"
                pos += 1
            end
            
            return Forall(Var_FOL(var_name), body), pos
            
        elseif token in ["exists", "∃"]
            pos += 1
            
            # Verificar si usa sintaxis con paréntesis: exists(x, ...)
            has_opening_paren = false
            if pos <= length(tokens) && tokens[pos] == "("
                has_opening_paren = true
                pos += 1
            end
            
            # Extraer variable
            if pos > length(tokens)
                error("Se esperaba variable después de exists")
            end
            var_name = tokens[pos]
            pos += 1
            
            # Ignorar punto o coma después de la variable
            if pos <= length(tokens) && tokens[pos] in [".", ","]
                pos += 1
            end
            
            # Parsear cuerpo
            body, pos = parse_expr(tokens, pos)
            
            # Solo consumir paréntesis de cierre si se abrió uno para el cuantificador
            if has_opening_paren && pos <= length(tokens) && tokens[pos] == ")"
                pos += 1
            end
            
            return Exists(Var_FOL(var_name), body), pos
        end
    end
    
    return parse_primary(tokens, pos)
end

"""
    parse_primary(tokens::Vector{String}, pos::Int) -> Tuple{FOLFormula, Int}

Parsea expresiones primarias: predicados, variables, constantes y expresiones entre paréntesis.

Este es el nivel más bajo del parser recursivo descendente. Maneja:
- Paréntesis: `(P(x) & Q(y))`
- Predicados: `P(x, y, z)`
- Variables: `x, y, var1`
- Constantes: `a, b, CONST, 0, 1`

# Argumentos
- `tokens`: Lista de tokens
- `pos`: Posición actual en tokens

# Retorna
- `(fórmula, nueva_posición)`: Expresión parseada y siguiente posición

# Heurística de identificación
- **Predicado**: Token seguido de `(`
- **Variable**: Empieza con minúscula
- **Constante**: Empieza con mayúscula o dígito
- **Paréntesis**: `(`, `[`, o `{`

# Ejemplos
```julia
# Predicado
tokens = ["P", "(", "x", ",", "y", ")"]
parse_primary(tokens, 1)  # P(x, y)

# Variable
tokens = ["x"]
parse_primary(tokens, 1)  # Var_FOL("x")

# Constante
tokens = ["a"]
parse_primary(tokens, 1)  # Const_FOL("a")

# Expresión entre paréntesis
tokens = ["(", "P", "(", "x", ")", ")"]
parse_primary(tokens, 1)  # P(x)
```
"""
function parse_primary(tokens::Vector{String}, pos::Int)
    # Parsear términos y átomos
    if pos > length(tokens)
        error("Token inesperado: fin de entrada")
    end
    
    token = tokens[pos]
    
    # Paréntesis
    if token in ["(", "[", "{"]
        pos += 1
        expr, pos = parse_expr(tokens, pos)
        if pos > length(tokens) || tokens[pos] ∉ [")", "]", "}"]
            error("Se esperaba paréntesis de cierre")
        end
        pos += 1
        return expr, pos
    end
    
    # Predicado o función
    if pos < length(tokens) && tokens[pos + 1] == "("
        name = token  # Mantener como string
        pos += 2  # Saltar nombre y "("
        
        # Parsear argumentos
        args = []
        if pos <= length(tokens) && tokens[pos] != ")"
            while true
                arg, pos = parse_term(tokens, pos)
                push!(args, arg)
                
                if pos > length(tokens)
                    error("Se esperaba , o )")
                end
                
                if tokens[pos] == ","
                    pos += 1
                elseif tokens[pos] == ")"
                    break
                else
                    error("Se esperaba , o ) en argumentos, encontré: $(tokens[pos])")
                end
            end
        end
        
        if pos > length(tokens) || tokens[pos] != ")"
            error("Se esperaba )")
        end
        pos += 1
        
        # ¿Es predicado o función?
        # Heurística: si aparece solo sin conectivas después, es predicado
        # Parsearemos como Predicado
        return Predicate_FOL(name, args), pos
    end
    
    # Variable o constante sin argumentos
    name = token
    pos += 1
    
    if is_variable_name(name)
        return Var_FOL(name), pos
    else
        return Const_FOL(name), pos
    end
end

"""
    parse_term(tokens::Vector{String}, pos::Int) -> Tuple{Term, Int}

Parsea un término: variable, constante o función.

A diferencia de `parse_primary` que parsea fórmulas, esta función específicamente
parsea términos que pueden aparecer como argumentos de predicados o funciones.

# Argumentos
- `tokens`: Lista de tokens
- `pos`: Posición actual en tokens

# Retorna
- `(término, nueva_posición)`: Término parseado (Var_FOL, Const_FOL o Func_FOL) y siguiente posición

# Tipos de términos
1. **Variable**: `x, y, var1` (empieza con minúscula)
2. **Constante**: `a, A, 0, 1` (empieza con mayúscula o dígito)
3. **Función**: `f(x), g(a,b), h(x,f(y))` (nombre seguido de paréntesis)

# Ejemplos
```julia
# Variable
tokens = ["x"]
parse_term(tokens, 1)  # Var_FOL("x")

# Constante
tokens = ["a"]
parse_term(tokens, 1)  # Const_FOL("a")

# Función simple
tokens = ["f", "(", "x", ")"]
parse_term(tokens, 1)  # Func_FOL("f", [Var_FOL("x")])

# Función anidada
tokens = ["g", "(", "x", ",", "f", "(", "y", ")", ")"]
parse_term(tokens, 1)  # Func_FOL("g", [Var_FOL("x"), Func_FOL("f", [Var_FOL("y")])])
```

# Recursión
La función es recursiva para manejar funciones anidadas: `f(g(h(x)))`
"""
function parse_term(tokens::Vector{String}, pos::Int)::Tuple{Term, Int}
    # Parsear un término (variable, constante o función)
    if pos > length(tokens)
        error("Se esperaba término")
    end
    
    token = tokens[pos]
    
    # Paréntesis en término
    if token in ["(", "[", "{"]
        pos += 1
        term, pos = parse_term(tokens, pos)
        if pos > length(tokens) || tokens[pos] ∉ [")", "]", "}"]
            error("Se esperaba paréntesis de cierre en término")
        end
        pos += 1
        return term, pos
    end
    
    # Función
    if pos < length(tokens) && tokens[pos + 1] == "("
        name = token  # Mantener como string
        pos += 2
        
        args = []
        if pos <= length(tokens) && tokens[pos] != ")"
            while true
                arg, pos = parse_term(tokens, pos)
                push!(args, arg)
                
                if pos > length(tokens)
                    error("Se esperaba , o )")
                end
                
                if tokens[pos] == ","
                    pos += 1
                elseif tokens[pos] == ")"
                    break
                else
                    error("Se esperaba , o ) en argumentos de función")
                end
            end
        end
        
        if pos > length(tokens) || tokens[pos] != ")"
            error("Se esperaba )")
        end
        pos += 1
        
        return Func_FOL(name, args), pos
    end
    
    # Variable o constante
    name = token
    pos += 1
    
    if is_variable_name(name)
        return Var_FOL(name), pos
    else
        return Const_FOL(name), pos
    end
end

"""
    is_variable_name(s::String) -> Bool

Determina si un nombre representa una variable o una constante usando heurísticas.

# Reglas de clasificación
1. **Variable**: Empieza con letra minúscula
2. **Constante**: Empieza con letra mayúscula o dígito

# Argumentos
- `s`: Nombre a clasificar

# Retorna
- `true` si es variable, `false` si es constante

# Ejemplos
```julia
is_variable_name("x")      # true  - minúscula → variable
is_variable_name("var1")   # true  - minúscula → variable
is_variable_name("A")      # false - mayúscula → constante
is_variable_name("abc")    # true  - minúscula → variable
is_variable_name("XYZ")    # false - mayúscula → constante
is_variable_name("0")      # false - dígito → constante
is_variable_name("123")    # false - dígito → constante
```

# Nota convencional
En lógica de primer orden:
- Variables: x, y, z, x₁, x₂, ... (minúsculas)
- Constantes: a, b, c, 0, 1, ... (letras minúsculas al inicio del alfabeto o números)
- Funciones/Predicados: f, g, P, Q, ... (puede variar)

Esta implementación usa la convención de que:
- **Minúsculas = variables** (más flexible que la convención estricta)
- **Mayúsculas/dígitos = constantes**
"""
function is_variable_name(s::String)::Bool
    # Variables: empiezan con minúscula (excepto constantes especiales)
    # Constantes: empiezan con mayúscula o números
    if isempty(s)
        return false
    end
    
    first_char = s[1]
    
    # Si empieza con dígito → constante
    if isdigit(first_char)
        return false
    end
    
    # Si empieza con minúscula → variable
    if islowercase(first_char)
        return true
    end
    
    # Si empieza con mayúscula → constante
    return false
end

"""
    @parse expr

Macro para parsear fórmulas lógicas sin usar strings.

Permite escribir fórmulas directamente con sintaxis cercana a la matemática,
sin necesidad de envolverlas en cadenas de texto. Internamente, convierte la
expresión a string y la parsea usando `parse_formula`.

# Sintaxis Requerida
**IMPORTANTE**: Los cuantificadores DEBEN usar sintaxis de función (sin espacios):
- ✅ `∀(x, ...)` o `∃(x, ...)`  
- ✅ `forall(x, ...)` o `exists(x, ...)`
- ❌ NO usar `∀ x (...)` o `∃ x (...)` (Julia no acepta espacios en expresiones)

# Ejemplos
```julia
# Fórmula con cuantificadores anidados
@parse ∃(x, P(x) & ∀(y, Q(y) > R(x,y)))

# Equivalente con palabras
@parse exists(x, P(x) & forall(y, Q(y) > R(x,y)))

# Predicados con múltiples argumentos
@parse ∀(x, ∀(y, P(x,y) > Q(x,y)))

# Fórmulas complejas anidadas
@parse ∃(x, P(x) & ∀(y, ∃(z, R(x,y,z))))

# Conectivas lógicas
@parse P(a) & Q(b) | !R(c)
@parse P(a) > Q(b)
@parse P(a) ~ Q(b)
```

# Operadores Soportados
- **Conjunción**: `&` (se convierte a ∧)
- **Disyunción**: `|` (se convierte a ∨)
- **Negación**: `!` (se convierte a ¬)
- **Implicación**: `>` (se convierte a →)
- **Bicondicional**: `~` (se convierte a ↔)
- **Cuantificadores**: `∀(x, ...)`, `∃(x, ...)`, `forall(x, ...)`, `exists(x, ...)`

# Limitaciones
- ⚠ Los cuantificadores deben usar sintaxis de función: `∀(x, body)` NO `∀ x body`
- Los símbolos deben ser válidos en Julia (variables, funciones, constantes)
- No se evalúan: deben ser literales sintácticos

# Ventajas vs parse_formula
- ✅ Sintaxis más cercana a la matemática
- ✅ No requiere strings
- ✅ Mejor autocompletar en IDE
- ✅ Verificación de sintaxis en tiempo de edición
- ✅ Mejor legibilidad

# Nota
Para fórmulas con sintaxis flexible (espacios, punto después de cuantificadores),
use `parse_formula("...")` directamente:
```julia
parse_formula("∀x. P(x)")           # Funciona
parse_formula("∃x (P(x) & Q(x))")   # Funciona
@parse ∀(x, P(x))                   # Equivalente en macro
```
"""
macro parse(expr)
    # Convertir expresión a string
    expr_str = string(expr)
    
    # Parsear en tiempo de macro expansion
    result = parse_formula(expr_str)
    
    # Retornar el resultado directamente
    return result
end

end