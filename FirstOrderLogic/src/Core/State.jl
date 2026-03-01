module State

# ════════════════════════════════════════════════════════════════════════════
# ESTADO GLOBAL - Sistema unificado para contadores
# ════════════════════════════════════════════════════════════════════════════

export FOLState, STATE
export reset_counters!, reset_var_rename_counter!, reset_skolem_counter!, reset_TS_constant_counter!
export next_var_rename_counter!, next_skolem_counter!, next_TS_constant_counter!

"""
    FOLState

Estado global del módulo FirstOrderLogic.
Mantiene contadores para generación de nombres únicos.

# Campos
- `var_rename_counter::Int` - Contador para renombramiento de variables
- `skolem_counter::Int` - Contador para funciones de Skolem
- `TS_constant_counter::Int` - Contador para constantes de tableau

# Uso
```julia
# Acceder al estado global
FirstOrderLogic.STATE

# Resetear todos los contadores
reset_counters!()

# Resetear contador específico
reset_var_rename_counter!()
```
"""
mutable struct FOLState
    var_rename_counter::Int
    skolem_counter::Int
    TS_constant_counter::Int
end

"""
Estado global del módulo.
⚠️ INTERNAL: No modificar directamente. Use las funciones reset_*_counter!()
"""
const STATE = FOLState(0, 0, 0)

# ──────────────────────────────────────────────────────────────────────────
# Funciones de Reset
# ──────────────────────────────────────────────────────────────────────────

"""
    reset_counters!()

Resetea todos los contadores globales a cero.

# Uso
```julia
reset_counters!()  # Resetear todo
```
"""
function reset_counters!()
    STATE.var_rename_counter = 0
    STATE.skolem_counter = 0
    STATE.TS_constant_counter = 0
    nothing
end

"""
    reset_var_rename_counter!()

Resetea el contador de renombramiento de variables.
Útil cuando se quiere reiniciar la numeración de variables frescas.
"""
function reset_var_rename_counter!()
    STATE.var_rename_counter = 0
    nothing
end

"""
    reset_skolem_counter!()

Resetea el contador de funciones de Skolem.
Útil para obtener nombres deterministas en tests.
"""
function reset_skolem_counter!()
    STATE.skolem_counter = 0
    nothing
end

"""
    reset_TS_constant_counter!()

Resetea el contador de constantes de TS.
Útil para γ-reglas en Tableros semánticos.
"""
function reset_TS_constant_counter!()
    STATE.TS_constant_counter = 0
    nothing
end

# ──────────────────────────────────────────────────────────────────────────
# Funciones de Acceso (Internal)
# ──────────────────────────────────────────────────────────────────────────

"""
⚠️ INTERNAL: Obtiene el siguiente contador de renombramiento.
"""
function next_var_rename_counter!()
    STATE.var_rename_counter += 1
    return STATE.var_rename_counter
end

"""
⚠️ INTERNAL: Obtiene el siguiente contador de Skolem.
"""
function next_skolem_counter!()
    STATE.skolem_counter += 1
    return STATE.skolem_counter
end

"""
⚠️ INTERNAL: Obtiene el siguiente contador de constantes de tableau.
"""
function next_TS_constant_counter!()
    STATE.TS_constant_counter += 1
    return STATE.TS_constant_counter
end

end # module State