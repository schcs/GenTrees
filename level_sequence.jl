#= 
    This file contains functions that deal with level sequences of trees.
=#

# This function can perhaps be improved by replacing current root with an array
# storing the current roots at each level.

function level_sequence_to_graph( seq::Vector{Int64} )
    ```Transforms level sequence into graph.```

    edges::Dict{Int64,Int64} = Dict{Int64,Int64}()
    n::Int64 = length( seq )
    current_root::Int64 = 1

    for i in 2:n
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
    
    parents::Vector{Int64} = vcat( [0], [ edges[i] for i in 2:n ] )
    g::MetaGraph = MetaGraph( SimpleGraph( Edge.( [ (i,edges[i] ) for i in keys( edges )])))
    rev_dfs = reverse_dfs( g )
    set_prop!( g, :reverse_dfs, rev_dfs )
    set_prop!( g, :level_sequence, seq )
    set_prop!( g, :parents, parents )
    set_prop!( g, :has_ci, has_central_involution( ls ))
    set_prop!( g, :ends_of_subgraphs_rev, [ end_of_subgraph( ls, rev_dfs, x ) for x in 1:n ])
    set_prop!( g, :ends_of_subgraphs, [ end_of_subgraph( ls, x ) for x in 1:n ])
    set_prop!( g, :left_siblings, [ root_of_left_sibling_subtree( ls, x ) for x in 1:n ])
    return g
end

# the following function writes the vertices of g in reverse depth first search order 

function reverse_dfs( g::AbstractGraph )::Vector{Int64}

    stack::Vector{Int64} = [1]
    vertices::Vector{Int64} = []
    v::Int64 = 0
    while length(stack) > 0 
        v = pop!( stack )
        push!( vertices, v ) 
        append!( stack, filter( x->x > v, neighbors( g, v )))
    end 

    return vertices
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

# returns the end of the subtree stemming from vertex v in level_sequence ls
# it is the vertex before the first vertex with the same or smaller level as v
# or the end of the tree in case there is no more vertex with the same level

function end_of_subgraph( ls::Vector{Int64}, v::Int64 )

    # find the first vertex whose level is not grater then the level of v
    end_ver::Union{Int64,Nothing} = findfirst( k -> k <= ls[v], ls[v+1:end] )

    # if found nothing, then return the length of ls
    # otherwise return end_ver+v-1
    return end_ver isa Nothing ? length(ls) : v+end_ver-1
end 

function end_of_subgraph_rev( ls::Vector{Int64}, r_dfs::Vector{Int64}, v::Int64 )::Int64

    # position of v in r_dfs 
    ps = findfirst( x -> r_dfs[x] == v, 1:length( ls ))
    end_ver::Union{Nothing,Int64} = findfirst( k -> ls[k] <= ls[v], r_dfs[ps+1:end] )

    # if found nothing, then return the length of ls
    # otherwise return end_ver+v-1
    return end_ver isa Nothing ? r_dfs[end] : r_dfs[ps+end_ver-1]
end 


# Returns the level sequence of the subtree stemming from vertex v in level sequence ls

function level_sequence_of_subgraph( ls::Vector{Int64}, v::Int64 )::Vector{Int64}

    return ls[v:end_of_subgraph( ls, v )]
end 

# Returns the root of the left_sibling subtree of vertex v in level sequence ls 
# The left sibling is the subtree stemming from a vertex i with the same parent as v
# with i < v
# needs to find the first vertex with the level as v from starting from v-1 backwards

function root_of_left_sibling_subtree( ls::Vector{Int64}, v::Int64  )::Int64
    
    p::Int64 = parent_vertex( ls, v )
    if p == -1
        return -1
    end 
    desc::Vector{Int64} = [ x for x in children_vertices( ls, p ) if x < v ]
    if length( desc ) == 0
        return -1
    end 

    return maximum( desc )
end 

#=
function root_of_left_sibling_subtree( ls::Vector{Int64}, v::Int64  )::Int64

    root_st::Int64, level_root_st::Int64 = v, ls[v]
    
    # inspect vertices from v-1 to 1 backwards
    for i in v-1:-1:1
        # if i is higher up in the tree, then there is no left sibling 
        if ls[i] < level_root_st
            root_st, level_root_st = i, ls[i]  
        elseif ls[i] == level_root_st
            # i is the root of the left sibling 
            return i
        end 
    end 

    # no sibling found
    return -1
end 
=#


# returns the parent of the vertex v in level sequence ls
function parent_vertex( ls::Vector{Int64}, v::Int64 )::Int64

    if v == 1 return -1 end 
    return v - findfirst( x -> ls[x] == ls[v]-1, v-1:-1:1 )
end 

# the descendents of a vertex v in the level sequence v 

function children_vertices( ls::Vector{Int64}, v::Int64 )::Vector{Int64}
    
    neigh::Vector{Int64} = []
    level_v::Int64 = ls[v]
    for i in v+1:length(ls)
        if ls[i] == level_v + 1
            push!( neigh, i )
        elseif ls[i] <= level_v 
            break
        end 
    end 

    return neigh
end 