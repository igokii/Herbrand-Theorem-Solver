"""
    Help

Sistema de ayuda interactiva para FirstOrderLogic.jl

Proporciona tres niveles de asistencia:
- **Ayuda rápida**: `help()`, `help(:topic)`, `examples(:function)`
- **Tutoriales**: `tutorial(:topic)` - paso a paso interactivo
- **Demos**: `demo(:topic)` - ejemplos ejecutables

# Ejemplos de uso

```julia
using FirstOrderLogic

# Nivel 1: Ayuda rápida
help()                    # Cheatsheet general
help(:cnf)                # Ayuda específica sobre CNF
examples(:tableaux)       # Ejemplos de uso de tableaux

# Nivel 2: Tutoriales interactivos
tutorial(:cnf)            # Tutorial paso a paso de CNF
tutorial(:tableaux)       # Tutorial de tableaux semánticos
demo(:resolution)         # Demo con ejemplos de resolución
```
"""
module Help

using ..Types
using ..Parser
using ..NormalForms
using ..Tableaux
using ..Resolution
using ..Unification
using ..Herbrand

export help, tutorial, demo, examples, cheatsheet

include("cheatsheets.jl")
include("examples_db.jl")
include("tutorials.jl")
include("demos.jl")

"""
    help(topic::Symbol = :general)

Muestra ayuda sobre un tema específico o cheatsheet general.

# Temas disponibles
- `:general` - Resumen de toda la librería
- `:syntax` - Sintaxis para crear fórmulas
- `:normalforms` - Formas normales (NNF, Prenex, Skolem, CNF, DNF)
- `:algorithms` - Algoritmos de decisión (Tableaux, Resolution, Herbrand)
- `:unification` - Unificación y UMG
- `:models` - L-estructuras y modelos
- `:visualization` - Visualización con Graphviz

# Ejemplos
```julia
help()              # Muestra cheatsheet general
help(:syntax)       # Sintaxis de fórmulas
help(:cnf)          # Información sobre CNF
```
"""
function help(topic::Symbol = :general)
    if topic == :general
        show_general_help()
    elseif topic == :syntax
        show_syntax_help()
    elseif topic == :normalforms
        show_normalforms_help()
    elseif topic == :algorithms
        show_algorithms_help()
    elseif topic == :unification
        show_unification_help()
    elseif topic == :models
        show_models_help()
    elseif topic == :visualization
        show_visualization_help()
    # Topics específicos
    elseif topic == :cnf
        show_cnf_help()
    elseif topic == :tableaux
        show_tableaux_help()
    elseif topic == :resolution
        show_resolution_help()
    elseif topic == :herbrand
        show_herbrand_help()
    else
        println("⚠️  Tema desconocido: $topic")
        println("\n📚 Temas disponibles:")
        println("  :general, :syntax, :normalforms, :algorithms")
        println("  :unification, :models, :visualization")
        println("  :cnf, :tableaux, :resolution, :herbrand")
    end
end

"""
    examples(func::Symbol)

Muestra ejemplos de uso para una función específica.

# Funciones con ejemplos disponibles
- `:to_cnf` - Conversión a CNF
- `:to_Px` - Forma Prenex
- `:to_Sk` - Skolemización
- `:tableaux` - Tableaux semánticos
- `:resolution` - Método de resolución
- `:UMG` - Unificación
- `:herbrand` - Base y universo de Herbrand
- `:models` - Modelos y L-estructuras

# Ejemplo
```julia
examples(:to_cnf)
examples(:tableaux)
```
"""
function examples(func::Symbol)
    show_examples(func)
end

"""
    cheatsheet(category::Symbol = :all)

Muestra cheatsheet de referencia rápida.

# Categorías
- `:all` - Todas las categorías
- `:syntax` - Sintaxis de fórmulas
- `:normalforms` - Formas normales
- `:algorithms` - Algoritmos de decisión

# Ejemplo
```julia
cheatsheet()           # Todo
cheatsheet(:syntax)    # Solo sintaxis
```
"""
function cheatsheet(category::Symbol = :all)
    show_cheatsheet(category)
end

end # module Help
