# This is an implementation of the algorithm to generate all trees on n vertices up to 
# isomorphism. The algorithm is described in the paper 
# CONSTANT TIME GENERATION OF FREE TREES*
# ROBERT ALAN WRIGHTS’, BRUCE RICHMONDT, ANDREW ODLYZKO AND BRENDAN D. MCKAY
#
# written by Csaba Schneider 

using Graphs, MetaGraphs

mutable struct TreeIterator
    current_graph::MetaGraph
    num_vert::Int64
end

function TreeIterator( n::Integer )
    return TreeIterator( path_params( n ), n )
end 


function next_tree( G )

    ggd = get_prop( G, :graph_gen_data )
    L = ggd['L']; W = ggd['W']; n = ggd['n']; p = ggd['p']; q = ggd['q'] 
    h1 = ggd["h1"]; h2 = ggd["h2"]; c = ggd['c']; r = ggd['r']

    if q == 0 
        return false
    end

    l = L; w = W

    fixit = false

    if c == n+1 || p == h2 && (l[h1] == l[h2]+1 && n-h2>r-h1 ||
            l[h1] == l[h2] && n-h2+1 < r - h1)  
        if l[r] > 3 
            p = r;  q = w[r]
            if h1 == r 
                h1 = h1 - 1
            end 
            fixit = true
        else 
            p = r; r = r-1; q = 2
        end
    end
    
    needr = false; needc = false; needh2 = false
    if p <= h1 h1 = p - 1; end
    if p <= r 
        needr = true
    elseif p <= h2 
        needh2 = true 
    elseif l[h2] == l[h1] - 1 && n - h2 == r - h1 
        if p <= c needc = true end
    else 
        c = Inf
    end

    oldp = p; δ = q - p; oldlq = l[q]; oldwq = w[q]; p = Inf
    
    for i in oldp:n
        l[i] = l[i+δ]
        if l[i] == 2 
            w[i] = 1
        else
            p = i
            if l[i] == oldlq 
                q = oldwq
            else 
                q = w[i+δ] - δ
            end
            w[i] = q
        end
    
        if needr && l[i] == 2 
            needr = false; needh2 = true; r = i - 1
        end
        
        if needh2 && l[i] <= l[i-1] && i > r + 1 
            needh2 = false; h2 = i - 1
            if l[h2] == l[h1] - 1 && n - h2 == r - h1 
                needc = true
            else 
                c = Inf
            end
        end
        
        if needc 
            if l[i] != l[h1-h2+i] - 1
                needc = false; c = i
            else 
                c = i+1
            end
        end
    end

    if fixit 
        r = n-h1+1
        for i in (r+1):n 
            l[i] = i-r+1; w[i] = i-1
        end
        w[r+1] = 1; h2 = n; p = n; q = p-1; c = Inf
    else
        if p == Inf 
            if l[oldp-1] != 2 
                p = oldp - 1
            else 
                p = oldp - 2
            end
            q = w[p]
        end

        if needh2 
            h2 = n
            if l[h2] == l[h1] - 1 && h1 == r 
                c = n + 1
            else 
                c = Inf
            end
        end
    end

    G = MetaGraph( LevelSequenceToLightGraph( l ))
    set_prop!( G, :graph_gen_data, 
            Dict( 'L' => l, 'W' => w, 'n' => n, 'p' => p, 'q' => q, 
                  "h1" => h1, "h2" => h2, 'c' => c, 'r' => r ))

    return G
end

function path_params( n )

    k = n÷2 + 1
    L = [ 1:k; 2:n-k+1 ]
    W = [ 0:k-1; 1:n-1]
    p, q, h1, h2, r =  n, n-1, k, n, k
    
    if isodd( n ) 
        c = Inf
    else 
        c = Float64(n+1)
    end 

    G = MetaGraph( LevelSequenceToLightGraph( L ))
    set_prop!( G, :graph_gen_data, 
            Dict( 'L' => L, 'W' => W, 'n' => n, 'p' => p, 'q' => q, 
                  "h1" => h1, "h2" => h2, 'c' => c, 'r' => r ))
                  
    return G
end 

function all_trees( n )

    p = path_params( n )
    list = [ p ]

    while true 
        p = next_tree( p )
        if typeof( p ) == Bool break; end 
        push!( list, p )
    end

    return list
end

LevelSequenceToLightGraph = function( seq )

    edges = Dict{Int64,Int64}()
    root = 1
    current_level = 2
    current_root = 1
    for i in 2:length( seq )
        if seq[i] == seq[i-1]+1 
            push!( edges, i => current_root )
            current_root = i
        else 
            for i in 1:seq[i-1]-seq[i]+1
                current_root = edges[current_root]
            end 
            push!( edges, i => current_root )
            current_root = i
        end
    end

    return SimpleGraph( Edge.( [ (i,edges[i] ) for i in keys( edges )]))
end


function Base.iterate( TI::TreeIterator, c=0 )
    newgraph = next_tree( TI.current_graph )
    if newgraph == false return nothing; end
    TI.current_graph = newgraph
    return newgraph, 0
end 


function level_sequence( g::AbstractGraph )

    if has_prop( g, :level_sequence )
        return get_prop( g, :level_sequence )
    end

    vert_list = [(1,1)]
    visited = []
    level_seq = []

    while length( vert_list ) > 0
        (ver, current_level) = pop!( vert_list )
        push!( visited, ver )
        push!( level_seq, current_level )
        append!( vert_list, 
            reverse( [ (x,current_level+1) for x in neighbors( g, ver ) if !(x in visited) ]))
    end 

    set_prop!( g, :level_sequence, level_seq )
    return level_seq
end

function end_of_subgraph( ls, v )
    end_ver = findfirst( k -> k <= ls[v], ls[v+1:end] )
    return typeof( end_ver ) == Nothing ? length( ls )-v+1 : end_ver
end 

function level_sequence_of_subgraph( ls, v )
    
    return ls[v:end_of_subgraph( ls, v )+v-1]
end 

function is_coloring( t, colors )

    for e in edges( t )
        if colors[src(e)] == colors[dst(e)]
            return false
        end 
    end
    return true
end 

#=

function swap_coloring( t, coloring, v, w )

    ev = end_of_subgraph( t, v )
    ew = end_of_subgraph( t, w )
    temp = coloring[v:ev]
    coloring[v:ev] = coloring[e:ew]
    coloring[w:ew] = temp
end 


function canonical_coloring( t, coloring )

    ls = level_sequence( t )
    last_ver_levels = []
    for i in 1:length(ls)
        
    
end
  
=#

function minimal_coloring( levelseq, colors; parent_color = false )
    
    if parent_color isa Bool 
        root_color = colors[1]
    else 
        root_color = findfirst( x -> x != parent_color, colors )
    end 

    col_even = findfirst( x -> x != root_color, colors )
    col_odd = findfirst( x-> x != col_even, colors )

    if levelseq[1] % 2 == 0 
        col_even, col_odd = col_odd, col_even
    end

    return vcat( [root_color], 
        [ levelseq[i] % 2 == 0 ? col_even : col_odd for i in 2:length(levelseq)])
end

function next_coloring( level_seq, coloring, colors; parent_color = colors[1]-1 )

    nv = length( level_seq )
    if nv == 1
        next_col_pos = findfirst( x-> x > coloring[1] && x != parent_color, colors )
        if next_col_pos isa Nothing
            return Nothing
        else
            return [colors[next_col_pos]]
        end 
    end 

    first_level = level_seq[1]

    children = [ x for x in 1:nv if level_seq[x] == first_level+1 ]
    nr_children = length( children )
    subgraphs = [ level_sequence_of_subgraph( level_seq, c ) for c in children ]
    children_ends = [ end_of_subgraph( level_seq, c ) + c-1 for c in children ]
    col_children = [ coloring[children[i]:children_ends[i]] for i in 1:nr_children]
    k = nr_children

    while  k>= 0
        c = children[k]

        if k == 1 
            new_cols = next_coloring( subgraphs[k], col_children[k], colors, 
                                        parent_color = coloring[1] )
            if new_cols != Nothing 
                coloring[children[k]:children_ends[k]] = new_cols; 
                return coloring
            else 
                if coloring[1] != colors[end]
                    coloring[1] += 1
                    if coloring[1] == parent_color 
                        coloring[1] += 1
                    end 
                    if coloring[1] > colors[end] return Nothing end 
                    for i in 1:nr_children
                        cols = minimal_coloring( subgraphs[i], colors, parent_color = coloring[1] )
                        coloring[children[i]:children_ends[i]] = cols  
                    end; 
                    return coloring
                else
                    return Nothing
                end 
            end 
        elseif k != 1 && subgraphs[k] != subgraphs[k-1]
            new_cols = next_coloring( subgraphs[k], col_children[k], colors,parent_color = coloring[1] )
            if new_cols != Nothing 
                coloring[children[k]:children_ends[k]] = new_cols; 
                return coloring
            else 
                for i in k:nr_children
                    cols = minimal_coloring( subgraphs[i], colors, parent_color = coloring[1] )
                    coloring[children[i]:children_ends[i]] = cols  
                end 
                k -= 1
            end
        elseif k >= 2 && subgraphs[k] == subgraphs[k-1] && col_children[k] != col_children[k-1] 
            new_cols = next_coloring( subgraphs[k], col_children[k], colors, 
                                        parent_color = coloring[1])
            if new_cols != Nothing 
                coloring[children[k]:children_ends[k]] = new_cols; 
                return coloring
            else 
                for i in k:nr_children
                    cols = minimal_coloring( subgraphs[i], colors, parent_color = coloring[1] )
                    coloring[children[i]:children_ends[i]] = cols 
                end 
                k = nr_children
            end
        else 
            for i in k:nr_children
                cols = minimal_coloring( subgraphs[i], colors, parent_color = coloring[1] )
                coloring[children[i]:children_ends[i]] = cols 
            end 
            k -= 1 
        end 
    end
    return Nothing
end
 
function all_colors( ls, colors )

    colorings = [ minimal_coloring( ls, colors )]
    while true
        new_col = next_coloring( ls, colorings[end], colors )
        if new_col != Nothing 
            push!( colorings, new_col )
        else 
            return colorings 
        end 
    end 
end 

function nr_colors( ls, colors )

    colorings = [ minimal_coloring( ls, colors )]
    k = 1
    while true
        new_col = next_coloring( ls, colorings[end], colors )
        if new_col == Nothing 
            return k
        else 
            k += 1
        end 
    end 
end 
