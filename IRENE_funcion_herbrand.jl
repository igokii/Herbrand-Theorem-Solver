# ==============================================================================
# Irene González Quirós
# Proyecto de LITI - Esqueleto Proposicional Herbrand - FUNCIÓN FINAL
# Curso 2025-2026
# Fecha: 14 de enero de 2026
# ==============================================================================

include("PropositionalLogic/src/PropositionalLogic.jl")
import .PropositionalLogic as PL
include("FirstOrderLogic/src/FirstOrderLogic.jl")
import .FirstOrderLogic as FOL

# ==============================================================================
# FUNCIÓN: parse_pl, generado por Gemini Flash y adaptado 
# ==============================================================================

"""
    parse_pl(s::String) -> FormulaPL
Parsea una fórmula en formato matemático y la convierte a tipos formales.
"""
function parse_pl(s::String)
    # 1. Limpieza y Normalización
    s = replace(s, r"\s+" => "") 
    s = replace(s, "↔"=>"~", "<>"=>"~", "→"=>">", "->"=>">", "¬"=>"!", "∧"=>"&", "∨"=>"|", "-"=>"!")

    # 2. Tokenización
    tokens = split(replace(s, 
        "("=>" ( ", ")"=>" ) ", "!"=>" ! ", "&"=>" & ", 
        "|"=>" | ", ">"=>" > ", "~"=>" ~ "), r"\s+")
    tokens = filter(!isempty, tokens)

    pos = 1

    # 3. Parser Recursivo usando PL.Types
    function parse_expr()
        left = parse_and()
        while pos <= length(tokens) && tokens[pos] == "|"
            pos += 1
            left = PL.Or_PL(left, parse_and())
        end
        return left
    end

    function parse_and()
        left = parse_implies()
        while pos <= length(tokens) && tokens[pos] == "&"
            pos += 1
            left = PL.And_PL(left, parse_implies())
        end
        return left
    end

    function parse_implies()
        left = parse_not()
        if pos <= length(tokens) && tokens[pos] == ">"
            pos += 1
            left = PL.Types.Imp_PL(left, parse_implies()) 
        elseif pos <= length(tokens) && tokens[pos] == "~"
            pos += 1
            left = PL.Iff_PL(left, parse_implies())
        end
        return left
    end

    function parse_not()
        if pos <= length(tokens) && tokens[pos] == "!"
            pos += 1
            return PL.Neg_PL(parse_not()) 
        end
        return parse_primary()
    end

    function parse_primary()
        token = tokens[pos]
        pos += 1
        if token == "("
            expr = parse_expr()
            pos += 1 # Saltar ")"
            return expr
        else
            return PL.Var_PL(token)
        end
    end

    return parse_expr()
end

# ==============================================================================
# FUNCIÓN: to_PL
# ==============================================================================

"""
    to_PL(f::FOLFormula, max_depth::Int = 3) -> FormulaPL

Pasa a fórmula PL a partir de fórmula FOL, utilizando Herbrand con la profundidad indicada

- `f::FOLFormula`: Fórmula FOL 
- `max_depth::Int`: Profundidad máxima del universo de Herbrand

# Funcionamiento
1- Aplica H_Ex.
2- Crea un diccionario que asocia cada predicado atómico a su equivalente en PL.
3- Sustituye los predicados atómicos de la fórmula FOL por sus equivalentes en PL.
4- Parsea la fórmula final con la función parse_pl

"""
function to_PL(f::FOL.FOLFormula, max_depth::Int = 3)
    
    # 1. Se aplica H_Ex.
    herbrand = FOL.H_Ex(f, max_depth = max_depth)

    # 2. Creación de un diccionario que asocia cada predicado atómico a su equivalente en PL.

    # Ejemplo: P(a,b) -> "P_a_b"
    parseo = Dict()
    for (_, lista_atomos) in herbrand.interpretations
        for atomo in lista_atomos
            nombre_PL = replace(string(atomo), "(" => "_", ")" => "", "," => "_", " " => "", "." => "_")
            parseo[atomo] = nombre_PL
        end
    end

    # 3. Sustitución de los predicados atómicos de la fórmula FOL por sus equivalentes en PL.

    # Lista para guardar las fórmulas finales
    S_proposicional = PL.FormulaPL[]

for f in herbrand.ground_formulas
    f_str = string(f)
    for (fol, _) in parseo
        f_str = replace(f_str, string(fol) => parseo[fol])
    end
    push!(S_proposicional, parse_pl(f_str))
end
    return S_proposicional
end

# ==============================================================================
# FUNCIÓN: to_PL a partir de un vector{FOLFormula}
# ==============================================================================

"""
    to_PL(f::Vector{FOLFormula}, max_depth::Int = 3) -> FormulaPL

Pasa a fórmula PL a partir de un vector de fórmulas FOL, utilizando Herbrand con la profundidad indicada

- `f::Vector{FOLFormula}`: vector de fórmulas FOL 
- `max_depth::Int`: Profundidad máxima del universo de Herbrand

# Funcionamiento
1- Aplica H_Ex al vector de fórmulas unido mediante reduce(&, f).
2- Crea un diccionario que asocia cada predicado atómico a su equivalente en PL.
3- Sustituye los predicados atómicos de la fórmula FOL por sus equivalentes en PL.
4- Parsea la fórmula final con la función parse_pl

"""
function to_PL(f::Vector{FOL.FOLFormula}, max_depth::Int = 3)
    # 1. Se aplica H_Ex.
    herbrand = FOL.H_Ex(reduce(&,f), max_depth = max_depth)

    # 2. Creación de un diccionario que asocia cada predicado atómico a su equivalente en PL.

    # Ejemplo: P(a,b) -> "P_a_b"
    parseo = Dict()
    for (_, lista_atomos) in herbrand.interpretations
        for atomo in lista_atomos
            nombre_PL = replace(string(atomo), "(" => "_", ")" => "", "," => "_", " " => "", "." => "_")
            parseo[atomo] = nombre_PL
        end
    end

    # 3. Sustitución de los predicados atómicos de la fórmula FOL por sus equivalentes en PL.

    # Lista para guardar las fórmulas finales
    S_proposicional = PL.FormulaPL[]

for f in herbrand.ground_formulas
    f_str = string(f)
    for (fol, _) in parseo
        f_str = replace(f_str, string(fol) => parseo[fol])
    end
    push!(S_proposicional, parse_pl(f_str))
end
    return S_proposicional
end
