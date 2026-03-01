# Arquitectura Modular - PropositionalLogic.jl

## Resumen Ejecutivo

Este documento describe la arquitectura modular completa del sistema PropositionalLogic.jl, desarrollado principalmente para los cursos de Lógica Informática y de Inteligencia Artificial. El proyecto ha evolucionado desde un monolito de 3,221 líneas a una arquitectura modular educativa con 9 módulos especializados.

**Autor:** Fernando Sancho Caparrini / Victor Ramos González 
**Cursos:** Lógica Informática / Inteligencia Artificial
**Estado:** Completo y funcional  

---

## 📋 Índice

1. [Visión General](#visión-general)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Módulos del Sistema](#módulos-del-sistema)
4. [Documentación Técnica](#documentación-técnica)
5. [Funcionalidades Principales](#funcionalidades-principales)
6. [Guía de Uso](#guía-de-uso)
7. [Ejemplos Prácticos](#ejemplos-prácticos)
8. [Análisis y Comparación](#análisis-y-comparación)

---

## 🎯 Visión General

### Objetivos del Proyecto

- **Educativo**: Facilitar el aprendizaje de lógica proposicional con ejemplos claros.
- **Modular**: Separación clara de responsabilidades y funcionalidades.
- **Completo**: Implementación de todos los algoritmos fundamentales.
- **Documentado**: Rica documentación con ejemplos matemáticos y prácticos.

### Transformación Realizada

```
PL.jl (3,221 líneas)
    ↓ Modularización
PropositionalLogic/ (9 módulos)
    ├── Core/ (3 módulos fundamentales)
    ├── Analysis/ (3 módulos de análisis)
    └── Algorithms/ (3 algoritmos principales)
```

---

## 📁 Estructura del Proyecto

```
PropositionalLogic/
├── src/
│   ├── PropositionalLogic.jl          # Módulo principal unificador
│   ├── Core/                          # Componentes fundamentales
│   │   ├── Types.jl                   # Jerarquía de tipos y operadores
│   │   ├── Display.jl                 # Sistema de visualización
│   │   └── Evaluation.jl              # Sistema de evaluación
│   ├── Analysis/                      # Herramientas de análisis
│   │   ├── TruthTables.jl             # Tablas de verdad
│   │   ├── Properties.jl              # Propiedades semánticas
│   │   └── NormalForms.jl             # Formas normales CNF/DNF
│   └── Algorithms/                    # Algoritmos de decisión
│       ├── DPLL.jl                    # Algoritmo DPLL
│       ├── Tableaux.jl                # Tableaux semánticos
│       └── Resolution.jl              # Algoritmo de resolución
└── RESUMEN_ARQUITECTURA_MODULAR.md    # Este documento
```

---

## 🔧 Módulos del Sistema

### 🏗️ Core/ - Componentes Fundamentales

#### Types.jl - Jerarquía de Tipos
**Propósito**: Define la base del sistema de tipos para fórmulas proposicionales.

**Componentes principales**:
- `FormulaPL`: Tipo abstracto base.
- `Var_PL`: Variables proposicionales.
- `Neg_PL`, `And_PL`, `Or_PL`: Operadores básicos.
- `Imp_PL`, `Iff_PL`: Implicación y bicondicional.
- `Top_PL`, `Bottom_PL`: Constantes lógicas.

**Funcionalidades**:
- Sobrecarga de operadores (`!`, `&`, `|`, `>`, `~`).
- Constructores inteligentes.
- Sistema de precedencia de operadores.

#### Display.jl - Sistema de Visualización
**Propósito**: Formateo inteligente y visualización de fórmulas lógicas.

**Componentes principales**:
- Métodos `show()` especializados.
- Manejo de precedencia y paréntesis.
- Visualización de árboles de formación.
- Formateo matemático estándar.

**Funcionalidades**:
- `formation_tree()`: Árboles de análisis sintáctico.
- Paréntesis mínimos basados en precedencia.
- Símbolos matemáticos estándar (∧, ∨, →, ↔).

#### Evaluation.jl - Sistema de Evaluación
**Propósito**: Evaluación de fórmulas bajo valoraciones específicas.

**Componentes principales**:
- `Valuation`: Estructura para asignaciones de verdad.
- `evaluate()`: Evaluación principal.
- `vars_of()`: Extracción de variables.
- `subformulas()`: Análisis de subfórmulas.

**Funcionalidades**:
- Evaluación recursiva eficiente.
- Análisis estructural de fórmulas.
- Soporte para valoraciones parciales.
- Posibilidad de usar la asignación como función de evaluación `v(F)`.

### 📊 Analysis/ - Herramientas de Análisis

#### TruthTables.jl - Tablas de Verdad
**Propósito**: Generación sistemática de tablas de verdad y búsqueda de modelos.

**Componentes principales**:
- `truth_table()`: Generación completa de tablas.
- `models()` / `countermodels()`: Búsqueda de modelos.
- `print_table()`: Visualización formateada.

**Funcionalidades**:
- Generación automática de todas las valoraciones.
- Identificación de modelos y contramodelos.
- Tablas formateadas para análisis manual.

#### Properties.jl - Propiedades Semánticas
**Propósito**: Verificación de propiedades semánticas fundamentales.

**Componentes principales**:
- `TAUT()` / `SAT()` / `UNSAT()`: Validez / Satisfacibilidad.
- `LC_*()`: Consecuencia lógica (múltiples variantes).
- `EQUIV()`: Equivalencia lógica.
- `simplify_constants()`: Simplificación.

**Funcionalidades**:
- Verificación exhaustiva mediante tablas de verdad.
- Múltiples métodos de verificación de consecuencia.
- Simplificación automática de constantes.

#### NormalForms.jl - Formas Normales
**Propósito**: Transformaciones a formas normales CNF y DNF.

**Componentes principales**:
- `to_CNF()` / `to_DNF()`: Conversiones principales.
- `Literal`, `Clause`, `Cube`: Estructuras auxiliares.
- Funciones de transformación paso a paso.
- Extracción y reconstrucción de componentes.

**Funcionalidades**:
- Pipeline completo de transformación.
- Eliminación de implicaciones.
- Normalización de negaciones (NNF).
- Distribución de operadores.

### 🤖 Algorithms/ - Algoritmos de Decisión

#### DPLL.jl - Algoritmo DPLL
**Propósito**: Implementación completa del algoritmo Davis-Putnam-Logemann-Loveland.

**Componentes principales**:
- `DPLL()`: Algoritmo principal con backtracking.
- `unit_clauses()` / `pure_literals()`: Heurísticas.
- `apply_val()`: Aplicación de valoraciones.
- `DPLL_SAT()`: Interface simplificada.

**Funcionalidades**:
- Propagación de unidades.
- Eliminación de literales puros.
- Backtracking inteligente.
- Modos verbose para educación.

#### Tableaux.jl - Tableaux Semánticos
**Propósito**: Método de tableros para verificación de satisfacibilidad.

**Componentes principales**:
- `TableauNode`: Estructura de nodos.
- `build_TS()`: Construcción de tableaux.
- `apply_α()` / `apply_β()`: Reglas α y β.
- `TS_SAT()`: Verificación de satisfacibilidad.

**Funcionalidades**:
- Construcción sistemática de tableaux.
- Reglas α (no ramificantes) y β (ramificantes).
- Detección automática de cierres.
- Extracción de modelos de ramas abiertas.

#### Resolution.jl - Algoritmo de Resolución
**Propósito**: Implementación del método de resolución con optimizaciones.

**Componentes principales**:
- `ExtendedClause`: Cláusulas con metadatos.
- `resolve()`: Regla de resolución.
- `RES()`: Algoritmo principal.
- Sistema de trazado y optimización.

**Funcionalidades**:
- Resolución binaria eficiente.
- Detección de subsumción.
- Eliminación de tautologías.
- Trazado completo del proceso.

### 🎮 PropositionalLogic.jl - Módulo Principal

**Propósito**: Unificación de todos los submódulos con interface conveniente.

**Componentes principales**:
- Re-exportación de todas las funcionalidades.
- `analyze()`: Análisis completo de fórmulas.
- `compare_algorithms()`: Comparación de rendimiento.
- `verify_logical_consequence()`: Verificación multi-método.

**Funcionalidades**:
- Interface unificada para toda la funcionalidad.
- Herramientas de análisis educativo.
- Comparación automática de algoritmos.
- Verificación cruzada de resultados.

---

## 📚 Documentación Técnica

### Estándares de Documentación

Cada módulo incluye:

1. **Docstring del módulo**: Descripción general, contenido y componentes.
2. **Docstrings de funciones**: Sintaxis, ejemplos, complejidad.
3. **Comentarios inline**: Explicaciones de algoritmos complejos.
4. **Ejemplos prácticos**: Casos de uso educativos.

### Formato de Documentación

```julia
"""
    función(parámetros) -> TipoRetorno

Descripción breve de la función.

# Parámetros
- `param1::Tipo`: Descripción del parámetro

# Retorno
Descripción del valor retornado

# Ejemplos
\`\`\`julia
ejemplo_de_uso()
# resultado esperado
\`\`\`

# Complejidad
- Temporal: O(n)
- Espacial: O(1)
"""
```

---

## ⚡ Funcionalidades Principales

### 1. Construcción de Fórmulas

```julia
# Variables
p, q, r = vars("p", "q", "r")

# Fórmulas complejas
formula = (p & q) > (!p | r)

# Constantes lógicas
tautologia = ⊤
contradiccion = ⊥
```

### 2. Análisis Semántico

```julia
# Propiedades básicas
es_tautologia = TAUT(formula)
es_satisfacible = SAT(formula)

# Consecuencia lógica
consecuencia = LC_TT(premisas, conclusion)

# Equivalencia
equivalentes = EQUIV(formula1, formula2)
```

### 3. Transformaciones

```julia
# Formas normales
cnf = to_CNF(formula)
dnf = to_DNF(formula)
cf  = to_CF(formula)

# Simplificación
simplificada = simplify_constants(formula)
```

### 4. Algoritmos de Decisión

```julia
# DPLL
resultado_dpll = DPLL_SAT(formula)

# Tableaux
resultado_ts = TS_SAT(formula)

# Resolución
resultado_res = RES_SAT(formula)
```

### 5. Análisis Completo

```julia
# Análisis automático
analisis = analyze(formula)

# Comparación de algoritmos
comparacion = compare_algorithms(formula)

# Verificación multi-método
verificacion = verify_logical_consequence(premisas, conclusion)
```

---

## 🚀 Guía de Uso

### Instalación y Configuración

1. **Estructura de directorios**: Crear la estructura PropositionalLogic/src/
2. **Archivos del módulo**: Copiar todos los archivos .jl en sus ubicaciones
3. **Carga del módulo**:
   ```julia
   include("PropositionalLogic/src/PropositionalLogic.jl")
   using .PropositionalLogic
   ```

### Uso Básico

```julia
# 1. Crear variables
p, q, r = vars("p", "q", "r")

# 2. Construir fórmulas
formula = (p > q) & (q > r) > (p > r)

# 3. Analizar propiedades
println("¿Es tautología? ", TAUT(formula))
println("Modelos: ", models(formula))

# 4. Convertir a CNF
cnf = to_CNF(formula)
println("CNF: ", cnf)

# 5. Verificar con DPLL
resultado = DPLL_SAT(formula)
println("DPLL resultado: ", resultado)
```

### Uso Avanzado

```julia
# Análisis completo
resultados = analyze(formula)
println("Análisis completo:")
for (propiedad, valor) in resultados
    println("  $propiedad: $valor")
end

# Comparación de algoritmos
comparacion = compare_algorithms(formula)
println("Rendimiento comparativo:")
for (algoritmo, tiempo) in comparacion
    println("  $algoritmo: $tiempo ms")
end
```

---

## 💡 Ejemplos Prácticos

### Ejemplo 1: Verificación de Tautología

```julia
# Ley de tercio excluso
p = vars("p")[1]
tercio_excluso = p | !p

println("Fórmula: ", tercio_excluso)
println("¿Tautología? ", TAUT(tercio_excluso))

# Tabla de verdad
truth_table(tercio_excluso)
```

### Ejemplo 2: Silogismo Hipotético

```julia
p, q, r = vars("p", "q", "r")

# Premisas: p → q, q → r
premisa1 = p > q
premisa2 = q > r

# Conclusión: p → r
conclusion = p > r

# Verificación
resultado = LC_TT([premisa1, premisa2], conclusion)
println("¿Es consecuencia lógica? ", resultado)
```

### Ejemplo 3: Conversión a CNF

```julia
p, q, r = vars("p", "q", "r")

# Fórmula compleja
formula = (p & q) > (r | !p)

println("Original: ", formula)

# Paso a paso
sin_imp = remove_imp(formula)
println("Sin implicaciones: ", sin_imp)

nnf = move_negation_in(sin_imp)
println("NNF: ", nnf)

cnf = to_CNF(formula)
println("CNF final: ", cnf)
```

### Ejemplo 4: Comparación de Algoritmos

```julia
# Fórmula de prueba
formula = (vars("p")[1] & vars("q")[1]) | (!vars("p")[1] & !vars("q")[1])

# Comparar todos los métodos
println("Comparación de algoritmos:")
comparacion = compare_algorithms(formula)

for (metodo, tiempo) in comparacion
    println("$metodo: $tiempo ms")
end
```

---

## 📈 Análisis y Comparación

### Complejidad Computacional

| Algoritmo | Peor Caso | Caso Promedio | Espacio |
|-----------|-----------|---------------|---------|
| Tablas de Verdad | O(2^n) | O(2^n) | O(2^n) |
| DPLL | O(2^n) | O(1.3^n) | O(n) |
| Tableaux | O(2^n) | O(1.5^n) | O(n²) |
| Resolución | O(2^n) | O(1.7^n) | O(n²) |

### Ventajas por Método

**Tablas de Verdad**:
- ✅ Completitud garantizada.
- ✅ Fácil comprensión.
- ❌ Explosión exponencial.

**DPLL**:
- ✅ Muy eficiente en práctica.
- ✅ Optimizaciones efectivas.
- ✅ Backtracking inteligente.

**Tableaux**:
- ✅ Construcción sistemática.
- ✅ Visualización clara.
- ✅ Extracción de modelos.

**Resolución**:
- ✅ Base teórica sólida.
- ✅ Paralelizable.
- ✅ Optimizaciones avanzadas.

### Casos de Uso Recomendados

- **Educación**: Tablas de verdad y Tableaux.
- **Investigación**: DPLL y Resolución.
- **Verificación**: Múltiples métodos combinados.
- **Análisis**: Función `analyze()` integrada.

---

## 🎓 Valor Educativo

### Características Pedagógicas

1. **Progresión Natural**: De conceptos básicos a algoritmos avanzados.
2. **Ejemplos Abundantes**: Cada función incluye ejemplos prácticos.
3. **Visualización Clara**: Formateo matemático estándar.
4. **Modos Verbose**: Trazado paso a paso de algoritmos
5. **Comparación Directa**: Múltiples enfoques para el mismo problema.

### Aplicaciones en el Aula

- **Laboratorios**: Experimentación con fórmulas reales.
- **Demostraciones**: Visualización de algoritmos en acción.
- **Ejercicios**: Verificación automática de soluciones.
- **Proyectos**: Base para extensiones avanzadas.

---

## 🔧 Extensibilidad

### Puntos de Extensión

1. **Nuevos Operadores**: Ampliar la jerarquía de tipos.
2. **Algoritmos Adicionales**: Implementar BDD, SAT solvers modernos.
3. **Optimizaciones**: Mejoras en heurísticas existentes.
4. **Visualización**: Interfaces gráficas interactivas.

### Arquitectura Flexible

La separación modular permite:
- Modificar componentes independientemente.
- Agregar nuevas funcionalidades sin romper existentes.
- Intercambiar implementaciones de algoritmos.
- Extender capacidades de análisis.

---

## 📋 Estado del Proyecto

### ✅ Completado

- [x] Arquitectura modular completa (9 módulos).
- [x] Documentación exhaustiva con ejemplos.
- [x] Implementación de todos los algoritmos fundamentales.
- [x] Sistema de análisis y comparación integrado.
- [x] Funciones de conveniencia y utilidades educativas.

### 🔄 Posibles Mejoras Futuras

- [ ] Suite de tests unitarios completa.
- [ ] Notebooks Jupyter con ejemplos interactivos.
- [ ] Benchmark automático con datasets estándar.
- [ ] Interface web para uso en navegador.
- [ ] Integración con sistemas de proof checking.

---

## 📞 Contacto y Soporte

**Autor**: [Fernando Sancho Caparrini](https://www.cs.us.es/~fsancho/) / [Victor Ramos González](https://www.cs.us.es/perfiles/victor-ramos-gonzalez)
**email**: fsancho@us.es / vramos1@us.es
**Departamento**: [Ciencias de la Computación e Inteligencia Artificial](https://www.cs.us.es/)
**Institución**: [Universidad de Sevilla](https://www.us.es/)
**Cursos**: Lógica Informática / Inteligencia Artificial

Para consultas sobre el uso o extensión de este sistema, consultar la documentación inline o contactar con el autor de la librería.

---

*Documento generado automáticamente - Julio 2025*
