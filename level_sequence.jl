#= 
    This file contains functions that deal with level sequences of trees.
=#

# This function can perhaps be improved by replacing current root with an array
# storing the current roots at each level.

function level_sequence_to_graph( seq )
    ```Transforms level sequence into graph.```

    edges = Dict{Int64,Int64}()

    current_root = 1
    for i in 2:length( seq )
        if seq[i] == seq[i-1]+1
            # in this case, the vertex i originates from the previous vertex 
            push!( edges, i => current_root )
            current_root = i
        else 
            # in this case the vertex i originates from an earlier current root 
            # seq[i-1] - seq[i] + 1 levels uṕ
            for i in 1:seq[i-1]-seq[i]+1
                current_root = edges[current_root]
            end 
            push!( edges, i => current_root )
            current_root = i
        end
    end

    return SimpleGraph( Edge.( [ (i,edges[i] ) for i in keys( edges )]))
end

# Transforms graph into level sequence. We run a simple Depth First Search on the graph

function level_sequence( g::AbstractGraph )

    # if graph has level_sequence property, then just return it.

    if g isa MetaGraph && has_prop( g, :level_sequence )
        return get_prop( g, :level_sequence )
    end

    # start with vertex 1, it has level 1
    vert_list = [(1,1)]
    visited = []
    level_seq = []

    while length( vert_list ) > 0

        # process the last vertex in vert_list which is ver and remove it from vert_list
        (ver, current_level) = pop!( vert_list )
        push!( visited, ver )
        push!( level_seq, current_level )

        # append to vert_list the non-visited neighbours of ver with its levels
        append!( vert_list, 
            reverse( [ (x,current_level+1) for x in neighbors( g, ver ) if !(x in visited) ]))
    end 

    if g isa MetaGraph 
        set_prop!( g, :level_sequence, level_seq )
    end 

    return level_seq
end

# returns the end of the subtree stemming from vertex v in level_sequence ls
# it is the vertex before the first vertex with the same or smaller level as v
# or the end of the tree in case there is no more vertex with the same level

function end_of_subgraph( ls, v )

    # find the first vertex whose level is not grater then the level of v
    end_ver = findfirst( k -> k <= ls[v], ls[v+1:end] )

    # if found nothing, then return the length of ls
    # otherwise return end_ver+v-1
    return end_ver isa Nothing ? length(ls) : v+end_ver-1
end 


# Returns the level sequence of the subtree stemming from vertex v in level sequence ls

function level_sequence_of_subgraph( ls, v )

    #= 
    if has_dc && v == 1
        pos2 = findfirst( x->x==2, ls[3:end] )
        return vcat( [2], [ls[2:pos2+1] ]) 
    end 
    =#

    return ls[v:end_of_subgraph( ls, v )]
end 

# Returns the root of the left_sibling subtree of vertex v in level sequence ls 
# The left sibling is the subtree stemming from a vertex i with the same parent as v
# with i < v
# needs to find the first vertex with the level as v from starting from v-1 backwards

function root_of_left_sibling_subtree( ls, v  )

    # inspect vertices from v-1 to 1 backwards
    root_st, level_root_st = v, ls[v]

    for i in v-1:-1:1
        # if i is higher up in the tree, then there is no left sibling 
        if ls[i] < level_root_st
            root_st, level_root_st = i, ls[i]  
        elseif ls[i] == level_root_st
            # i is the root of the left sibling 
            return root_st, i
        end 
    end 

    # no sibling found
    return false, false
end 

# returns the parent of the vertex v in level sequence ls
function parent_vertex( ls, v ) 

    if v == 1 return nothing end 
    return v - findfirst( x -> ls[x] == ls[v]-1, v-1:-1:1 )
end 

# the descendents of a vertex v in the level sequence v 

function children_vertices( ls, v )
    
    neigh = []
    level_v = ls[v]
    for i in v+1:length(ls)
        if ls[i] == level_v + 1
            push!( neigh, i )
        elseif ls[i] <= level_v 
            break
        end 
    end 

    return neigh
end 