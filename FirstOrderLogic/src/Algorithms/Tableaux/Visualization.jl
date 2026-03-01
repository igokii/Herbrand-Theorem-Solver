# ════════════════════════════════════════════════════════════════════════════
# Visualización de Tableaux Semánticos
# ════════════════════════════════════════════════════════════════════════════

"""
    print_TS_FOL(node::TSNodeFOL, io::IO = stdout)

Imprime el tablero semántico de FOL de forma legible con numeración de fórmulas.
"""
function print_TS_FOL(node::TSNodeFOL, io::IO = stdout)
    root = node
    while root.parent !== nothing
        root = root.parent
    end
    formula_map = root.formula_map
    
    indent = "  " ^ node.depth
    
    println(io, "$(indent)Rama $(node.branch_id):")
    
    if node.parent === nothing
        for F in node.formulas
            formula_key = string(F)
            num = get(formula_map, formula_key, 0)
            if num > 0
                println(io, "$(indent)  $num: ⊢ $F 〚HIP.〛")
            else
                println(io, "$(indent)  ⊢ $F 〚HIP.〛")
            end
        end
    end
    
    for (idx, df) in enumerate(node.derived_formulas)
        formula_key = string(df)
        num = get(formula_map, formula_key, 0)
        if num > 0
            procedencia = ""
            if idx == 1 && !isempty(node.derivation_rule)
                if !isempty(node.parent_formula_numbers)
                    procedencia = "〚$(join(node.parent_formula_numbers, ", ")) + $(node.derivation_rule)〛"
                else
                    procedencia = "[$(node.derivation_rule)]"
                end
            end
            
            println(io, "$(indent)  $num: $df $procedencia")
        else
            println(io, "$(indent)  $df")
        end
    end
    
    if !isempty(node.used_terms)
        ground_terms = get_ground_terms(node.used_terms)
        if !isempty(ground_terms)
            terms_str = join([string(t) for t in ground_terms], ", ")
            println(io, "$(indent)  ⦃ Términos: $(terms_str) ⦄")
        end
    end
    
    if node.is_closed
        println(io, "$(indent)  ⊗ CERRADA: $(node.closure_reason)")
    elseif isempty(node.children)
        println(io, "$(indent)  ✓ ABIERTA")
    end
    
    for child in node.children
        print_TS_FOL(child, io)
    end
end

"""
    print_TS_FOL_verbose(node::TSNodeFOL, io::IO = stdout)

Imprime el tablero semántico mostrando TODAS las fórmulas acumuladas en cada nodo.
"""
function print_TS_FOL_verbose(node::TSNodeFOL, io::IO = stdout)
    indent = "  " ^ node.depth
    
    println(io, "$(indent)Rama $(node.branch_id):")
    
    for (i, F) in enumerate(node.formulas)
        println(io, "$(indent)  $i: $F")
    end
    
    if !isempty(node.used_terms)
        terms_str = join([string(t) for t in node.used_terms], ", ")
        println(io, "$(indent)  [Términos: $terms_str]")
    end
    
    if node.is_closed
        println(io, "$(indent)  ⊗ CERRADA: $(node.closure_reason)")
    elseif isempty(node.children)
        println(io, "$(indent)  ✓ ABIERTA")
    end
    
    for child in node.children
        print_TS_FOL_verbose(child, io)
    end
end

"""
    to_dot(node::TSNodeFOL) -> GVL.digraph

Genera representación Graphviz del árbol de tableau semántico.
"""
function to_dot(node::TSNodeFOL)
    root = node
    while root.parent !== nothing
        root = root.parent
    end
    formula_map = root.formula_map
    
    counter = Ref(0)
    node_ids = Dict{Tuple{String, Int}, String}()
    node_data = Dict{String, NamedTuple}()
    edges_data = Vector{NamedTuple}()
    
    function collect_and_assign_ids(n::TSNodeFOL)
        key = (n.branch_id, n.depth)
        if !haskey(node_ids, key)
            counter[] += 1
            node_ids[key] = "node_$(counter[])"
        end
        for child in n.children
            collect_and_assign_ids(child)
        end
    end
    
    collect_and_assign_ids(node)
    
    function generate_recursive(n::TSNodeFOL)
        key = (n.branch_id, n.depth)
        node_id = node_ids[key]
        
        label = ""
        if n.parent === nothing
            for F in n.formulas
                formula_key = string(F)
                num = get(formula_map, formula_key, 0)
                if num > 0
                    label *= "$num: $F\n"
                end
            end
            label = strip(label)
            if isempty(label)
                label = "[Iniciales]"
            end
        else
            if !isempty(n.derived_formulas)
                parts = String[]
                for df in n.derived_formulas
                    formula_key = string(df)
                    num = get(formula_map, formula_key, 0)
                    if num > 0
                        push!(parts, "$num: $df")
                    else
                        push!(parts, string(df))
                    end
                end
                label = join(parts, "\n")
            else
                label = "[Sin derivación]"
            end
        end
        
        is_leaf = isempty(n.children)
        is_root = n.parent === nothing
        
        fillcolor = ""
        style = ""
        
        if is_root
            fillcolor = "cyan"
            style = "filled"
        elseif is_leaf
            if n.is_closed
                fillcolor = "red"
                style = "filled"
                label = "⊗\n$label"
            else
                fillcolor = "lightgreen"
                style = "filled"
            end
        else
            fillcolor = "white"
            style = ""
        end
        
        node_data[node_id] = (id=string(node_id), label=string(label), fillcolor=string(fillcolor), style=string(style))
        
        for child in n.children
            child_key = (child.branch_id, child.depth)
            child_id = node_ids[child_key]
            
            edge_label = ""
            if !isempty(child.derivation_rule)
                edge_label = child.derivation_rule
                if !isempty(child.parent_formula_numbers)
                    parent_nums = join(child.parent_formula_numbers, ", ")
                    edge_label = "[$parent_nums + $edge_label]"
                end
            end
            
            push!(edges_data, (from=string(node_id), to=string(child_id), label=edge_label))
            generate_recursive(child)
        end
    end
    
    generate_recursive(node)
    
    g = GVL.digraph(rankdir="TB")
    font = "sans-serif"
    g = g |> GVL.attr(:graph; splines="true", nodesep="0.5", ranksep="0.70", fontname=font)
    g = g |> GVL.attr(:node; shape="box", fontname=font)
    g = g |> GVL.attr(:edge; fontname=font)
    
    for (node_id, data) in node_data
        if data.style == "filled"
            g = g |> GVL.node(node_id; label=data.label, fillcolor=data.fillcolor, style="filled")
        else
            g = g |> GVL.node(node_id; label=data.label)
        end
    end
    
    for edge_info in edges_data
        if !isempty(edge_info.label)
            g = g |> GVL.edge(edge_info.from, edge_info.to; label=edge_info.label)
        else
            g = g |> GVL.edge(edge_info.from, edge_info.to)
        end
    end
    
    return g
end

"""
    to_file(node::TSNodeFOL; save_path::Union{String, Nothing} = nothing, format::String = "svg")

Visualiza el árbol de tableau y opcionalmente lo guarda en archivo.
"""
function to_file(node::TSNodeFOL; save_path::Union{String, Nothing} = nothing, format::String = "svg")
    result = to_dot(node)
    
    if !isnothing(save_path)
        save_dir = dirname(save_path)
        if !isempty(save_dir) && !isdir(save_dir)
            mkpath(save_dir)
        end
        
        try
            if !isa(result, String)
                output_path = save_path * "." * format
                save(output_path, result, format=format)
                println("✓ Visualización guardada en: $output_path")
            else
                dot_path = save_path * ".dot"
                open(dot_path, "w") do io
                    write(io, result)
                end
                
                try
                    output_path = save_path * "." * format
                    run(`dot -T$format $dot_path -o $output_path`)
                    println("✓ Visualización guardada en: $output_path")
                catch
                    println("✓ DOT guardado en: $dot_path")
                    println("  Convierte manualmente: dot -T$format $dot_path -o $save_path.$format")
                end
            end
        catch e
            println("⚠ Error al guardar: $(e)")
        end
    end
    
    return result
end
