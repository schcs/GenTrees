#= 
    This function contains code to generate colorings of trees in canonical form up to isomorphism.
    Each coloring generated will be in canonical form in the following sense. 
    
    If v is a vertex with descendants w1 and w2 with w1 < w2 and if the subgraphs stemming from w1 and w2 are 
    isomorphic, then the coloring of w1 is not smaller than the coloring of w2 in the lexicographic order.
    
    The colorings are generated in lexicographic order starting from the smallest one.
=#

# To check if a certain array defines coloring of the graph t

function is_coloring( t::AbstractGraph, colors::Vector{Int64} )::Bool


    for e in edges( t )
        # check if the source of e has the same color as the target
        if colors[src(e)] == colors[dst(e)]
            return false
        end 
    end

    return true
end 


#= 
    Generates the minimal coloring of a tree graph given with level sequence ls using colors in colors.
    The optional arguments are:

    parent_color: if the graph levelseq is a subtree in a larger tree, then its root cannot have the 
                  same color as its parent. parent_color is used to specify the color to be avioided 
                  for the root. No color is avoided if it is set to false.
                    
    root_color: one can specify what the root color should be. 
=#

function minimal_coloring( levelseq::Vector{Int64};  
                    parent_color::Integer = false, root_color::Integer = false )
    
    # choose the root color
    if root_color isa Bool && parent_color isa Bool 
        root_color = 1
    elseif root_color isa Bool
        root_color = parent_color == 1 ? 2 : 1 
    end 

    # there will be two colors used, one for the evel levels and one for the odd levels
    col_even::Int64 = root_color == 1 ? 2 : 1 
    col_odd::Int64 = col_even == 1 ? 2 : 1 

    # if level sequence starts from an even number then swap the even and odd level colors
    if levelseq[1] % 2 == 0 
        col_even, col_odd = col_odd, col_even
    end

    #  for each vertex its color is col_even or col_odd depending on the parity of the level
    return vcat( [root_color], 
        [ levelseq[i] % 2 == 0 ? col_even : col_odd for i in 2:length(levelseq)])
end 

#= 
    The iterative function to calculate the next coloring of the graph represented by level sequence 
    in the lexicographic order.

    Input: level sequence, current coloring (list of vertex colors), the list of all colors.

    The function assumes that the level sequence is in canonical form. 
=#

function next_coloring_iter( g::MetaGraph, col0::Vector{Int64}, max_col::Int64  )::Union{Nothing,Vector{Int64}}

    ls::Vector{Int64} = get_prop( g, :level_sequence )
    col::Vector{Int64} = copy(col0)
    
    # check if it has central involution
    has_ci::Bool = get_prop( g, :has_ci )
    
    # set up the maximum color, number of vertices, and the parents for the vertices
    n::Int64 = length( ls )
    parents::Vector{Int64} = get_prop( g, :parents )

    # set up the reverse dfs order for the vertices, the end of subgtrees originating from each vertex and 
    # the left siblings of each vertices
    rev_dfs::Vector{Int64} = get_prop( g, :reverse_dfs )
    subgraph_ends::Vector{Int64} = get_prop( g, :ends_of_subgraphs )
    subgraph_ends_rev::Vector{Int64} = get_prop( g, :ends_of_subgraphs_rev )
    left_siblings::Vector{Int64} = get_prop( g, :left_siblings )

    #=
        A vertex is colorable if it hasn't reached its maximum possible color.
            
        The vertex 1 is colorable if either 
        1.) The graph has no central involution and the color is 1 is not the max color; or 
        2.) The graph has central involutiuon and its color is not the second largest color. 
    =#
    
    # this variable shows how far we need to look in the tree to find the vertex whose 
    # color is modified
    look_end::Int64 = subgraph_ends[1]

    # in colorable we keep the index of the vertex that is to be colored
    colorable::Int64 = 0 #colorable_1 ? 1 : 0

    # we go through the vertices in reverse DFS order
    k::Int64 = 2

    while k <= n
        v::Int64 = rev_dfs[k]
        #println( k )

        # compute end point of the subgraph T_v stemming at vertex v
        v_end::Int64 = subgraph_ends[v]
        v_end_rev::Int64 = subgraph_ends_rev[v]
        # compute the root left sibling of the subgraph T_v
        # (the subgraph stemming from a vertex with the same parent as v, left of v)
        left_s::Int64 = left_siblings[v]
        left_sibling::Vector{Int64} = []

        if left_s != -1
            # the left sibling exists
            # we compute the range of indices that correspond to the left sibling
            left_sibling = left_s:(v-1)
        end 

        # check if T_v is isomorphic to the left sibling and if it has the same coloring
        # If yes, then the coloring of T_v cannot be increased and hence this part of 
        # the tree can be ignored

        if ls[v:v_end] == ls[left_sibling] && col[v:v_end] == col[left_sibling]
            #println( k )
            k = findfirst( x -> rev_dfs[x] == left_s, 1:n )
            #println( v, left_s )
            #println( "jumping to $k" )
            continue 
        end 

        # we decide if the color of v can be increased
        #println( "v is $v")
        if col[v] < max_col - 1 
            # we update colorable if necessary 
            if colorable < v colorable = v end 
            #we update look_end 
            look_end = v_end_rev 
        elseif col[v] == max_col - 1 && col[parents[v]] != max_col
            if colorable < v colorable = v end
            look_end = v_end_rev 
        end 
        
        if v == look_end && colorable != 0
            # we got the end of a branch that has colorable vertex
            # we need to look no further
            break 
        end  
        k += 1
    end 

    # check if one is colorable 
    colorable_1::Bool = has_ci ? col[1] < max_col - 1 : col[1] < max_col

    # if did not find colorable vertex then return nothing
    if colorable == 0 && !colorable_1 
        return nothing 
    elseif colorable == 0 
        colorable = 1
    end
    
    if colorable != 1 && col[parents[colorable]] == col[colorable] + 1
        # the parent of v already has color col[v] + 1 and so we increase color by two
        col[colorable] += 2 
    else 
        # else we increase the color by one
        col[colorable] += 1
    end 

    # we reset the coloring of each subtree on the right side of v
    # starting from v+1

    j::Int64 = colorable+1
    while j <= n
        root_color::Integer = false

        # find the end of the subtreee T_j stemming from vertex j
        es::Int64 = subgraph_ends[j]

        # determine the color for the root j of this subtree
        if has_ci && j == 2 
            # if has central involution and j is vertex two, then its color
            # is set to the color of vertex 1 plus 1 
            root_color = col[1]+1
        else 
            # else no constaint on root color
            root_color = false 
        end 

        # compute the minimal coloring for the subtree T_j
        # with parent color being the color of parent[j]
        col[j:es] = minimal_coloring( ls[j:es], parent_color = col[parents[j]], root_color = root_color )

        # the following subtree that needs to be dealt with stems from the end of T_j plus 1 
        j = es+1
    end 

    # return the coloring computed
    return col
end 

# computes all colorings for a tree represented by level sequence ls
# optional parameter rec is true/false to indicate if we want the recursive or the iterative 
# function for next color.

function all_colors( g, nr_colors; rec = false  )

    next_col_func = rec ? next_coloring_rec : next_coloring_iter
    ls = get_prop( g, :level_sequence )
    inp = rec ? ls : g 
    colorings = [ minimal_coloring( ls )]

    while true
        new_col = next_col_func( inp, colorings[end], nr_colors )
        if new_col != nothing 
            push!( colorings, new_col )
        else 
            return colorings 
        end 
    end 
end 
