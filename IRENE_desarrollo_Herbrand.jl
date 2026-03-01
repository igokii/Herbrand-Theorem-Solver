# ==============================================================================
# Irene González Quirós
# Proyecto de LITI - Esqueleto Proposicional Herbrand - proceso sobre ejemplos sencillos
# Curso 2025-2026
# Fecha: 14 de enero de 2026
# ==============================================================================

# Haciendo uso de las dos librerías de Julia (PL y LPO) probar la idea del esqueleto proposicional
# que proporciona el Teorema de Herbrand. Es decir, para resolver la satisfactibilidad de un conjunto de fórmulas LPO, S:

# A) Haciendo uso de LPO:
#   1.- Se pasa a forma Prenex+Skolem.
#   2.- Se pasa a forma cerrada con el universo de Herbrand (ya no quedan variables).
#   3.- Los predicados atómicos se consideran variables proposicionales.
# B) Haciendo uso de PL:
#   4.- Se construyen las variables proposicionales que representan cada uno de los predicados atómicos.
#   5.- Se consideran las fórmulas proposicionales que traducen las de S usando las variables.
#   6.- Se aplican métodos de PL para resolver el problema.

# La idea sería que primero lo hicieras sobre ejemplos sencillos (de los problemas que tenemos de clase) con las librerías,
# y después vieras si puedes (con mi ayuda) crear una función de Julia que agrupe todo el camino...

# ==============================================================================

# EJECUTAR SOLO UNA VEZ
include("PropositionalLogic/src/PropositionalLogic.jl")
import .PropositionalLogic as PL
include("FirstOrderLogic/src/FirstOrderLogic.jl")
import .FirstOrderLogic as FOL
include("IRENE_funcion_herbrand.jl")

# PARTE A)

#### 1. Pasar a forma Prenex + Skolem
# En primer lugar, definimos una serie de conjuntos de fórmulas con los que trabajaremos.
# Es importante que estos no generen un conjunto de términos cerrados infinito (al menos para
# el planteamiento inicial).

a, b, c = FOL.constants("a", "b", "c")
x, y, z, u = FOL.vars("x", "y", "z", "u")
P, Q, R, S, T = FOL.predicates("P", "Q", "R", "S", "T")

# conjunto de prueba (problema del barbero)
S0 = [
    FOL.∀(x, P(x) > FOL.∀(y, !Q(y, y) ~ Q(x, y))),
    P(a)
]

# No es necesario pasar cada fórmula a prenex y skolem ya que H_Ex incluye ese proceso
                                                                                    
#### 2. Pasar a forma cerrada con el universo de Herbrand

herbrand = FOL.H_Ex(S0)

# Este código lo he copiado y pegado de TestFOL.jl para hacer una comprobación, se puede omitir:
println("Universo: {", join(herbrand.constants, ","), "}")
println("Predicados generados: {", join(herbrand.interpretations, ","), "}")
println("Fórmulas instanciadas: {", join(herbrand.ground_formulas, ", "),"}")
FOL.show_H_ex(herbrand)

# ===========================================================

# PARTE B)

##### Ahora hacemos uso de PL. La librería ya se ha cargado al principio

# en primer lugar, debemos construir las variables proposicionales que
# representan cada uno de los predicados atómicos. Para ello, tomamos los predicados generados

predicados_atomicos = herbrand.interpretations

# Creo un diccionario que asocia cada predicado atómico a su equivalente en LPO,
# para así simplemente hacer una sustitución sobre las fórmulas (como Strings)

# el método .interpretations devuelve un diccionario cuya clave es nombre del predicado y el valor es
# una lista de los átomos que lo componen. Lo tengo en cuenta a la hora de crear el diccionario para 
# parsear (clave: predicado atómico, valor: equivalente en PL)

# ejemplo: "P(a,a)" -> "P_a_a"

parseo = Dict()
for (nombre_pred, lista_atomos) in predicados_atomicos
    for atomo in lista_atomos
        nombre_PL = replace(string(atomo), "(" => "_", ")" => "", "," => "_", " " => "") # sustituyo para que quede del formato X_atom1_atom2_..._atomN 
        parseo[atomo] = nombre_PL
    end
end

# Aquí, siguiendo la estructura utilizada en problemas de PL, pensé que era necesario inicializar las variables
# en PL. Sin embargo, me dí cuenta de que no era necesario, ya que la función parseo incluye 
# este proceso. Código eliminado:

#### aquí he llegado a una barrera. no puedo inicializar las variables porque la forma estandar de inicializarlas es
#### escribiendo por un lado el texto para julia y en otro lado el nombre de la variable con "". 
#### La IA ofrece dos soluciones:
    # 1. crear las variables con un bucle a parseo y "@eval $(Symbol(prop)) = Var_PL($prop)"
    # 2. crear un diccionario de variables: PL.vars[prop] = Var_PL(prop)
#### Usaremos el segundo método ya el primero crea las variables de manera global:
#### for (fol, lp) in parseo
####    vars[lp] = PL.Var_PL(lp)
#### end

# 5. Creamos una lista para aguardar las fórmulas proposicionales finales (obtenidas de herbrand.ground_formulas)

# Utilizamos la función parse_pl 

S_proposicional = PL.FormulaPL[]
for f in herbrand.ground_formulas
    f_str = string(f)
    for (fol, prop) in parseo
        f_str = replace(f_str, string(fol) => parseo[fol])
    end
    push!(S_proposicional, parse_pl(f_str))
end

# Comprobación:
println(S_proposicional)

# Y ya podemos trabajar con ellas:
cl = PL.⋀(S_proposicional) |> PL.to_CF
PL.DPLL(cl; verbose=true)

# Con todo esto, podemos crear la funcion to_PL en un archivo aparte, para aplicarlo a ejemplos sencillos

# ==============================================================================
# FINAL: Uso de to_PL sobre ejemplos
# ==============================================================================

# FINITOS:

S0 = [
    FOL.∀(x, P(x) > FOL.∀(y, !Q(y, y) ~ Q(x, y))),
    P(a)
]

cl = PL.⋀(to_PL(S0)) |> PL.to_CF
PL.DPLL(cl; verbose=true)

S1 = [
    FOL.∀(x, P(x) > Q(x)),              
    FOL.∀(y, (Q(a) | R(y)) > S(a)),     
    !(FOL.∀(x, P(x) > S(a)))
    ]

cl = PL.⋀(to_PL(S1)) |> PL.to_CF
PL.DPLL(cl; verbose=true)    

S2 = [
    Q(a, b),                        
    P(a),                           
    !FOL.∃(x, R(x) & P(x)),             
    FOL.∀(x, FOL.∀(y, (S(x) & Q(y, x)) > R(y))),
    !S(b),                          
    !!S(b)                          
]

cl = PL.⋀(to_PL(S2)) |> PL.to_CF
PL.DPLL(cl; verbose=true)

S3 = FOL.parse_formula("∃x ∀y ( p(x,y) ↔ ¬ ∃z (p(y,z) ∧ p(z,y)))") 

cl = PL.⋀(to_PL(S3)) |> PL.to_CF
PL.DPLL(cl; verbose=true)

# INFINITOS:

S4 = FOL.FOLFormula[
    FOL.parse_formula("∀x.P(x)"),
    FOL.parse_formula("∀x.¬Q(f(x))"),
    FOL.parse_formula("∀x.(P(f(x)) → Q(x))")
]

cl = PL.⋀(to_PL(S4)) |> PL.to_CF
PL.DPLL(cl; verbose=true)

S5 = FOL.parse_formula("∀x (p(c) ∧ ¬p(f(c)) ∧ ¬p(f(f(f(f(c))))) ∧ (¬p(x) ∨ p(f(f(x)))))")

cl = PL.⋀(to_PL(S5)) |> PL.to_CF
PL.DPLL(cl; verbose=true)

S6 = FOL.FOLFormula[
    FOL.parse_formula("∀x P(x)")
    FOL.parse_formula("∀x ¬P(f(x))")
]
# con profundidad 8:
cl = PL.⋀(to_PL(S6, 8)) |> PL.to_CF
PL.DPLL(cl; verbose=true)