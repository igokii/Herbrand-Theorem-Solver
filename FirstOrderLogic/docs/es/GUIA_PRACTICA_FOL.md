# Guía Práctica: Lógica de Primer Orden con Julia

## Introducción

Esta guía práctica acompaña a los temas de **Lógica de Primer Orden** que has estudiado en clase. Aquí aprenderás a utilizar la librería `FirstOrderLogic.jl` para:

- Construir fórmulas de primer orden.
- Trabajar con cuantificadores y variables.
- Parsear expresiones matemáticas.
- Crear L-estructuras y verificar modelos.
- Construir tableros semánticos.
- Transformar fórmulas a formas normales.
- Trabajar con unificación y resolución.

## 1. Primeros pasos: Instalación y carga

```julia
include("FirstOrderLogic/src/FirstOrderLogic.jl")
using .FirstOrderLogic
```

## 2. Construcción básica de fórmulas

### 2.1 Definiendo el Lenguaje de Primer Orden: variables, constantes, predicados y funciones

La librería proporciona funciones cómodas para crear los elementos básicos de un LPO:

#### Variables
```julia
x, y, z = vars("x", "y", "z")
v, w = vars("v", "w")
```

#### Constantes
```julia
juan, maria, cero = constants("Juan", "Maria", "0")
a, b, c = constants("a", "b", "c")
```

#### Funciones
```julia
padre, suma, hijo_de = functions("padre", "+", "hijo_de")
suc, f, g, h = functions("succ", "f", "g", "h")
```

#### Predicados
```julia
humano, ama, mayor, par = predicates("Humano", "Ama", "Mayor", "Par")
P, Q, R, S, T = predicates("P", "Q", "R", "S", "T")
```

### 2.2 Términos

Los términos se construyen como aplicaciones de funciones y predicados:

```julia
padre(juan)              # término cerrado
suma(x, y)               # término con variables
humano(x)                # predicado con variable
mayor(juan, maria)       # predicado con constantes
hijo_de(x, juan)         # mezcla de variable y constante
f(g(a))                  # composición de funciones
```

## 3. Fórmulas

### 3.1 Operadores lógicos

Una vez construidos los términos (predicados), podemos combinarlos con operadores lógicos:

```julia
# Conjunción (∧)
humano(x) & ama(x,y)

# Disyunción (∨)
mayor(x,y) | par(x)

# Negación (¬)
!humano(x)           # o también -humano(x)

# Implicación (→)
humano(x) > ama(x,y)

# Bicondicional (↔)
humano(x) ~ mayor(x,y)
```
Esto es útil para verificar que la fórmula se ha construido correctamente de acuerdo a la precedencia de operadores.

## 3. Cuantificadores

Los cuantificadores universales (∀) y existenciales (∃) son fundamentales en lógica de primer orden.

### 3.1 Constructores explícitos

```julia
Forall(x, humano(x))           # ∀x. Humano(x)
Exists(y, ama(x,y))            # ∃y. Ama(x,y)
```

### 3.2 Operadores Unicode (recomendado)

La librería proporciona operadores Unicode más legibles. En Julia, escribe `\forall` + TAB para ∀ y `\exists` + TAB para ∃:

```julia
∀(x, humano(x) > mayor(x,y))    # Para todo x: si humano(x) entonces mayor(x,y)
∃(y, ama(x,y) & humano(y))      # Existe y tal que ama(x,y) y humano(y)
```

## 5. Parsing de fórmulas

Si prefieres escribir las fórmulas en notación matemática, puedes usar la función `parse_formula`:

```julia
f1 = parse_formula("∀x.(P(x) → T(x))")
f2 = parse_formula("∃x (P(x) ∧ ∀y (Q(y) → R(x,y)))")
```

**Nota:** Observa el punto (.) después de la variable del cuantificador. Este punto sirve también como separador espacial entre el cuantificador y la fórmula.


## 6. Análisis de fórmulas

### 6.1 Árboles de formación

Para entender la estructura sintáctica de una fórmula, puedes visualizar su árbol de formación:

```julia
formation_tree(humano(x) > ama(x,y))
#  →
#  ├── Humano(x)
#  └── Ama(x, y)
```

### 6.2 Subfórmulas

Para obtener todas las subfórmulas de una fórmula dada:

```julia
f = (∀(x, humano(x) > mortal(x)) & humano(socrates)) > mortal(socrates)
subformulas(f)
#   (Humano(x) → Mortal(x))
#   (∀x.(Humano(x) → Mortal(x)) ∧ Humano(Socrates))
#   Mortal(Socrates)
#   ... (y más)
```

### 6.3 Variables libres

Las variables que no están ligadas por un cuantificador son **variables libres**:

```julia
w = var("w")
f1 = P(x) & ∀(y, Q(x,y) > ∃(z, R(z,w)))

vars_libres = free_vars(f1)  # {x, w}
```

### 6.4 Sustituciones de variables

Puedes reemplazar variables en una fórmula. La sustitución solo afecta a las **variables libres**:

```julia
juan = const_("Juan")
t2 = s(w)  # s es una función, w es una variable

substitute_var(f1, w, juan)    # Reemplaza w por Juan
substitute_var(f1, w, t2)      # Reemplaza w por s(w)
substitute_var(f1, x, t2)      # Reemplaza x por s(w) (x es libre)
substitute_var(f1, y, t2)      # No tiene efecto (y está ligada)
substitute_var(f1, z, t2)      # No tiene efecto (z está ligada)
```

## 7. L-estructuras y modelos

Una **L-estructura** (o modelo) es un universo junto con interpretaciones de los símbolos del lenguaje.

### 7.1 Definición de una L-estructura

Una L-estructura M = (|M|, I) consta de:

- **|M|**: Un universo no vacío de elementos
- **I_P**: Para cada predicado P de aridad n, un conjunto de n-tuplas de |M|
- **I_f**: Para cada función f de aridad n, una función de |M|^n → |M|
- **I_c**: Para cada constante c, un elemento de |M|

### 7.2 Ejemplo: Definiendo una L-estructura

```julia
# Lenguaje: {P, Q, f}
P, Q = predicates("P", "Q")
f = function_("f")

# Universo: {0, 1, 2, 3}
universo = Set([0, 1, 2, 3])

# Predicados: P = {0, 1}, Q = {(0, 1), (1, 1), (2, 1)}
predicados = Dict(
    "P" => Set([(0,), (1,)]),
    "Q" => Set([(0, 1), (1, 1), (2, 1)])
)

# Funciones: f(0) = 1, f(1) = 1, f(2) = 0, f(3) = 2
funciones = Dict(
    "f" => Dict((0,) => 1, (1,) => 1, (2,) => 0, (3,) => 2)
)

# Constantes: ninguna
constantes = Dict()

# Crear la estructura
M = LStructure(universo, predicados, funciones, constantes)

# Mostrar la estructura de forma legible
show_LS(M)
```

### 7.3 Verificando si un modelo satisface una fórmula

```julia
is_model_of(M, ∀(x, P(x) > ∃(y, Q(y,x))))     # ¿Es M modelo de esta fórmula?
is_model_of(M, ∀(x, Q(f(x), x)))              # ¿Y de esta otra?
```

Esta función te permite verificar si una estructura satisface todas las instancias de una fórmula en su universo.

### 7.4 Ejemplo completo: Decisión sobre modelos

```julia
# Lenguaje: {A, F, P, c}
x, y = vars("x", "y")
A, F, P = predicates("A", "F", "P")
c, = constants("c")

# Universo: {0, 1, 2, 3}
universe = Set([0, 1, 2, 3])

# Interpretaciones
predicates_dict = Dict(
    "A" => Set([(0,), (1,), (2,)]),
    "F" => Set([(0,), (1,), (3,)]),
    "P" => Set([(0,3), (1,0), (1,2), (2,3)])
)

funciones = Dict()
constantes = Dict("c" => 0)

M = LStructure(universe, predicates_dict, funciones, constantes)
show_LS(M)

# Verificar cada fórmula
is_model_of(M, A(c) > ∃(y, A(y) & P(y,c)))           # ¿Verdadera?
is_model_of(M, ∀(x, F(x) > -∃(y, A(y) & P(x,y))))   # ¿Verdadera?
is_model_of(M, F(c))                                  # ¿Verdadera?
```

## 8. Tableros Semánticos

Los **tableros semánticos** son un método de demostración sintáctico para determinar satisfacibilidad y validez de fórmulas.

### 8.1 Construcción y visualización

```julia
x, y = vars("x", "y")
P, Q, R = predicates("P", "Q", "R")
a, b = constants("a", "b")

# Construir un tablero del conjunto de fórmulas
t = TS_FOL([∃(x, Q(x)), ∀(x, Q(x) > R(x)), ∀(x, !R(x))])

# Mostrar el tablero en modo texto
print_TS_FOL(t)

# Mostrar como árbol con colores
#   • Azul: fórmulas iniciales
#   • Blanco: nodos intermedios
#   • Verde: ramas abiertas (satisfactibles)
#   • Rojo: ramas cerradas (insatisfactibles)
to_dot(t)
```

### 8.2 Satisfacibilidad

```julia
# ¿La fórmula es satisfacible?
TS_SAT(P(a))                              # Sí
TS_SAT(P(a) & !P(a))                      # No (contradictoria)
TS_SAT(∀(x, P(x)))                        # Sí
TS_SAT(∃(x, P(x) & Q(x)))                 # Sí
```

### 8.3 Validez

```julia
# ¿La fórmula es válida (tautología)?
TS_VALID(∀(x, P(x) | !P(x)))                  # Sí (ley del tercio excluso)
TS_VALID(∀(x, P(x)) > P(a))                   # Sí (instanciación universal)
TS_VALID((∀(x, P(x))) > (∃(y, P(y))))         # Sí
TS_VALID((∃(x, P(x))) > (∀(y, P(y))))         # No (contraejemplo posible)
TS_VALID((P(a) & (P(a) > Q(a))) > Q(a))       # Sí (Modus Ponens)
TS_VALID((!∀(x, P(x)) ~ ∃(x, !P(x))))         # Sí (leyes de De Morgan)
```

### 8.4 Análisis

```julia
# Obtener ambos resultados en una sola llamada
sat, valid = TS_solve(∀(x, P(x) | !P(x)))      # Satisfactible y válida
sat, valid = TS_solve(P(a) & !P(a))            # Insatisfactible (ambos false)
sat, valid = TS_solve(P(a))                    # Satisfactible pero no válida
```

### 8.5 Extracción de modelos

Una característica potente de los tableros es que permiten extraer **modelos concretos** (cuando la fórmula es satisfactible, claro):

```julia
f = P(a) & Q(b) & ∀(x, P(x) > Q(x))
t = TS_FOL([f])
to_dot(t)

# Extraer UN modelo del tablero y mostrarlo formateado
one_model(t) |> to_LS |> show_LS

# Extraer TODOS los modelos posibles
models = all_models(t)
for (i, m) in enumerate(models)
    println("\nModelo $i:")
    m |> to_LS |> show_LS
end
```

**Nota**: "TODOS" los modelos posibles que se deducen directamente del tablero.

## 9. Formas Normales

### 9.1 Forma Prenex

Una fórmula en **forma prenex** tiene TODOS los cuantificadores en el prefijo:

$$\mathbb{Q}_1 x_1 \ldots \mathbb{Q}_n x_n . \phi$$

donde cada $\mathbb{Q}_i$ es ∀ o ∃, y $\phi$ no contiene cuantificadores (es abierta).

```julia
f = (∀(x, P(x)) & ∃(y, Q(y))) > ∃(z, R(z))

# Obtener una forma prenex
to_Px(f)

# Obtener todas las posibles formas prenex
prenex_forms_sorted(f)

# La librería maneja automáticamente el renombramiento de variables
f_rep = (∀(x, P(x)) & ∃(y, Q(y))) > ∃(x, R(x))
to_Px(f_rep)  # Renombra automáticamente
```

**Nota**: `to_Px` devuelve una forma prenex que minimiza la complejidad (aridad) de los símbolos de Skolem .

### 9.2 Forma de Skolem

Tras obtener una forma prenex, la **forma de Skolem** elimina los cuantificadores existenciales reemplazándolos por constantes/funciones de Skolem:

$$\forall x_1 \ldots \forall x_n . \phi$$

```julia
x, y = vars("x", "y")
P, Q = predicates("P", "Q")

# Fórmula original
formula = ∃(x, ∀(y, P(x, y) > Q(y)))

# Aplicar Skolemización
skolemized = to_Sk(formula)

# Verificar que no tiene existenciales
has_∃(skolemized)      # false
is_Sk_form(skolemized) # true

# Extraer la matriz (sin cuantificadores universales)
matrix = remove_∀_prefix(skolemized)

# Resetear el contador de símbolos de Skolem
reset_skolem_counter!()
```

**Nota importante:** La Skolemización preserva la **consistencia** pero no la equivalencia lógica (porque el lenguaje LPO que se usa ha cambiado). Se usa principalmente en métodos como Herbrand y resolución.

### 9.3 Forma Clausal / Conjuntiva Normal (CNF)

La **forma clausal** es una conjunción de disyunciones (claúsulas) de una fórmula abierta:

$$(L_1 \vee \ldots \vee L_k) \wedge (M_1 \vee \ldots \vee M_m) \wedge \ldots$$

```julia
P, Q, R = predicates("P", "Q", "R")
x = var("x")

# Convertir a CNF
formula = (P(x) | Q(x)) & (!P(x) | R(x))
cnf = to_cnf(formula)

# Extraer claúsulas (lista de claúsulas)
clauses = to_clauses(formula)

# Para fórmulas con cuantificadores, primero Prenex + Skolem
f = ∃(x, P(x) & ∀(y, Q(y) > ∃(z, R(x, y, z))))
f_processed = f |> to_Px |> to_Sk
to_cnf(f_processed)
to_clauses(f_processed)
```

## 10. Universo y Extensión de Herbrand

El **universo de Herbrand** es el conjunto de todos los términos cerrados que se pueden construir con las constantes y funciones del lenguaje.

### 10.1 Cálculo del Universo de Herbrand

```julia
x, y = vars("x", "y")
P, Q, R = predicates("P", "Q", "R")
f, g = functions("f", "g")
a, b, c = constants("a", "b", "c")

# Calcular hasta cierto nivel de profundidad
formula = ∃(x, P(x)) & ∀(y, P(y) > Q(y))

hu_level0 = H_Un(formula; max_depth=0)  # {a, b, c}
hu_level1 = H_Un(formula; max_depth=1)  # {a, b, c, f(a), f(b), f(c), g(a), g(b), g(c)}

# Por niveles
formulas = [∀(x, P(x) | Q(f(x))), ∀(x, P(g(x)) | Q(f(b)))]
for formula in formulas
   println("Fórmula: $formula")
   for j in 0:2
      universe = H_Un(formula; max_depth=j)
      println("   Nivel $j: {", join(universe, ", "), "}")
   end
end

# También funciona para conjuntos de fórmulas
conjunto = Set([
    ∀(x, P(x) > Q(f(x))),
    P(a),
    P(b)
])
universe = H_Un(conjunto; max_depth=2)
```
**Nota**: En cuanto un lenguaje tiene una constante y un símbolo de función, el universo de Herbrand es infinito. 

### 10.2 Extensión de Herbrand

La **extensión de Herbrand** de un conjunto de funciones consiste en todas las instanciaciones de las fórmulas del conjunto con términos del universo de Herbrand:

```julia
KB = Set([
    ∀(x, P(x) > Q(x, c)),
    P(a),
    P(b)
])

# Calcular la extensión de Herbrand
herbrand = H_Ex(KB; max_depth=2)
show_H_ex(herbrand)

# Acceder a componentes específicas
println("Universo: {", join(herbrand.constants, ", "), "}")
println("Predicados generados: {", join(herbrand.interpretations, ", "), "}")
println("Fórmulas instanciadas: {", join(herbrand.ground_formulas, ", "), "}")
```

**Nota**: Como el universo de Herbrand puede ser infinito, la extensión de Herbrand también.

## 11. Unificación

La **unificación** es el proceso de encontrar una sustitución que haga que dos términos (o predicados) sean idénticos. La librería implementa el algoritmo de **Unificación de Máxima Generalidad** (**UMG**).

```julia
x, y, z, u, v, w = vars("x", "y", "z", "u", "v", "w")
f, g = functions("f", "g")
a, b = constants("a", "b")

# Unificar dos términos
t1 = f(x, a)
t2 = f(b, y)
mgu = UMG(t1, t2)  # {x/b, y/a}

# Unificar predicados
Loves = predicate("Loves")
mother = function_("mother")
John = const_("John")
p1 = Loves(x, mother(x))
p2 = Loves(John, y)
mgu2 = UMG(p1, p2)  # {x/John, y/mother(John)}

# Ejemplos adicionales
P, = predicates("P")
UMG(P(x, y), P(y, f(z)))           # {x/y, y/f(z)} o no unificable
UMG(P(x, g(x), y), P(z, u, g(u)))  # Busca sustitución común
UMG(P(c, y, f(y)), P(z, z, u))     # Puede fallar (occur check)
UMG(P(x, g(x)), P(y, y))           # No unificable
```


## 12. Resolución

**Resolución** es un método completo de refutación que determina si un conjunto de fórmulas es insatisfacible calculando resolventes y comprobando si se puede alcanzar la cláusula vacía (que indicaría una contradicción).

### 12.1 Satisfactibilidad

```julia
P, Q = predicates("P", "Q")
a, b = constants("a", "b")

# Fórmula satisfacible
f1 = P(a) & Q(b)
RES_SAT(f1)  # true

# Fórmula insatisfacible
f2 = P(a) & !P(a)
RES_SAT(f2)  # false
```

### 12.2 Validez

Para probar que una fórmula es **válida** (tautología), se prueba que su negación es **insatisfactible**:

```julia
P, Q = predicates("P", "Q")
a = const_("a")

# Ley del tercio excluso: P ∨ ¬P
f1 = P(a) | !P(a)
RES_VALID(f1)  # true

# Modus Ponens: ((P → Q) ∧ P) → Q
f2 = ((P(a) > Q(a)) & P(a)) > Q(a)
RES_VALID(f2)  # true

# No válida: (∃x P(x)) → (∀y P(y))
f3 = (∃(x, P(x))) > (∀(y, P(y)))
RES_VALID(f3)  # false
```

### 12.2 Consecuencia Lógica

Para probar que una fórmula se decude de un conjunto de fórmulas (que es un problema expresable en términos de SAT y TAUT) la librería ofrece una función directa que permite evaluar esta condición:

```julia
x, y = vars("x", "y")
P, Q = predicates("P", "Q")
a = const_("a")

KB = [
    ∀(x, P(x) > Q(x)),
    P(a)
]
conclusion = Q(a)
RES_LC(KB, conclusion)
```

### 12.3 Visualización de pruebas de resolución

La librería permite visualizar el árbol de resolución de forma gráfica o textual:

```julia
f = ∀(x, P(x) > Q(x)) & P(a) & !Q(a)

# Mostrar el árbol de resolución en formato gráfico
to_dot(f)

# Mostrar la prueba de insatisfacibilidad
proof_of_insat_graph(f)
proof_of_insat_text(f)
```

## 13. Ejemplos completos

### Ejemplo 1: Razonamiento sobre relaciones familiares

```julia
# Definir predicados y constantes
x, y, z = vars("x", "y", "z")
padre_de, progenitor_de, abuelo_de = predicates("Padre", "Progenitor", "Abuelo")
Juan, Pedro, Luis = constants("Juan", "Pedro", "Luis")

# Reglas
regla1 = ∀(x, ∀(y, padre_de(x, y) > progenitor_de(x, y)))
regla2 = ∀(x, ∀(y, abuelo_de(x, y) > ∃(z, padre_de(x, z) & progenitor_de(z, y))))

# Hechos
hecho1 = padre_de(Juan, Pedro)
hecho2 = padre_de(Pedro, Luis)

# Pregunta: ¿Es Juan abuelo de Luis?
pregunta = abuelo_de(Juan, Luis)

# Usar tableros semánticos
es_valido = TS_VALID((regla1 & regla2 & hecho1 & hecho2) > pregunta)
```

### Ejemplo 2: Verificación de propiedades en lógica proposicional

```julia
P, Q, R = predicates("P", "Q", "R")

# Verificar algunas equivalencias lógicas
println("Ley de De Morgan: !(P ∧ Q) ↔ (¬P ∨ ¬Q)")
eq1 = !(P(a) & Q(a)) ~ (!P(a) | !Q(a))
println("¿Válida? $(TS_VALID(eq1))")

println("\nDistributividad: P ∧ (Q ∨ R) ↔ (P ∧ Q) ∨ (P ∧ R)")
eq2 = (P(a) & (Q(a) | R(a))) ~ ((P(a) & Q(a)) | (P(a) & R(a)))
println("¿Válida? $(TS_VALID(eq2))")

println("\nEliminación del bicondicional: (P ↔ Q) ↔ ((P → Q) ∧ (Q → P))")
eq3 = (P(a) ~ Q(a)) ~ ((P(a) > Q(a)) & (Q(a) > P(a)))
println("¿Válida? $(TS_VALID(eq3))")
```

### Ejemplo 3: Análisis de modelos

```julia
# Problema: Determinar si una estructura es modelo de un conjunto de axiomas

# Lenguaje: {P, Q, R, f}
P, Q, R = predicates("P", "Q", "R")
f = function_("f")
x, y, z = vars("x", "y", "z")

# Estructura M
universo = Set([0, 1, 2])
predicados = Dict(
    "P" => Set([(0,), (1,)]),
    "Q" => Set([(0,), (1,), (2,)]),
    "R" => Set([(0,1), (1,2), (2,0)])
)
funciones = Dict(
    "f" => Dict((0,) => 1, (1,) => 2, (2,) => 0)
)
constantes = Dict()

M = LStructure(universo, predicados, funciones, constantes)

# Axiomas
axioma1 = ∀(x, P(x) > Q(x))
axioma2 = ∀(x, ∃(y, R(x, y)))
axioma3 = ∀(x, ∀(y, R(x, y) > Q(y)))

# Verificar
println("¿M ⊨ axioma1? $(is_model_of(M, axioma1))")
println("¿M ⊨ axioma2? $(is_model_of(M, axioma2))")
println("¿M ⊨ axioma3? $(is_model_of(M, axioma3))")
```

## 14. Tips y buenas prácticas

1. **Usa Unicode:** Las operadores ∀, ∃, ¬, ∧, ∨, →, ↔ hacen el código más legible. En Julia, escribe `\forall` + TAB.

2. **Renombra variables en fórmulas complejas:** Si tienes múltiples cuantificadores anidados, usa nombres descriptivos.

3. **Construye paso a paso:** Primero construye los componentes básicos (variables, constantes, predicados), luego combínalos.

4. **Visualiza estructuras:** Usa `formation_tree()` para verificar que la estructura sintáctica es la esperada.

5. **Verifica modelos:** Antes de hacer pruebas de validez, verifica que tu L-estructura satisface los axiomas usando `is_model_of()`.

6. **Usa Prenex + Skolem:** Antes de resolver, asegúrate de que las fórmulas estén en forma de Skolem.

7. **Resetea contadores:** Si trabajas con Skolemización repetidamente en distintos problemas, usa `reset_skolem_counter!()` para evitar colisiones de nombres.

## 15. Referencias a los tópicos vistos en clase

| Tópico              | Contenido                      | Secciones |
|---------------------|--------------------------------|:---------:|
| **Instalación**     | Instalación y carga            | 1         |
| **Sintaxis**        | Elementos de un LPO            | 2-5       |
| **Análisis**        | Manipulación Sintáctica        | 6         |
| **Semántica**       | L-estructuras y modelos        | 7         |
| **Tableros**        | Tableros Semánticos            | 8         |
| **Formas Normales** | Prenex, Skolem, CNF, Clausal   | 9         |
| **Herbrand**        | Universo/extensión de Herbrand | 10        |
| **Unificación**     | UMG                            | 11        |
| **Resolución**      | Resolución en FOL              | 12        |
| **Ejemplos**        | Ejemplos completos             | 13        |
| **Tips**            | Consejos y buenas prácticas    | 14        |

