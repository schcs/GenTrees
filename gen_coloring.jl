#= 
    This function contains code to generate colorings of trees in canonical form up to isomorphism.
    Each coloring generated will be in canonical form in the following sense. 
    
    If v is a vertex with descendants w1 and w2 with w1 < w2 and if the subgraphs stemming from w1 and w2 are 
    isomorphic, then the coloring of w1 is not smaller than the coloring of w2 in the lexicographic order.
    
    The colorings are generated in lexicographic order starting from the smallest one.
=#

# To check if a certain array defines coloring of the graph t

function is_coloring( t, colors )

    for e in edges( t )
        # check if the source of e has the same color as the target
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

greedy_coloring in the package Graphs
  
=#

#= 
    Generates the minimal coloring of a tree graph given with level sequence ls using colors in colors.
    The optional arguments are:

    parent_color: if the graph levelseq is a subtree in a larger tree, then its root cannot have the 
                  same color as its parent. parent_color is used to specify the color to be avioided 
                  for the root. No color is avoided if it is set to false.
                    
    root_color: one can specify what the root color should be. 
=#

function minimal_coloring( levelseq, colors; parent_color = false, root_color = false )
    
    # choose the root color
    if !(root_color isa Bool )
        root_color = root_color
    elseif parent_color isa Bool 
        root_color = colors[1]
    else
        root_color = findfirst( x -> x != parent_color, colors )
    end 

    # there will be two colors used, one for the evel levels and one for the odd levels
    col_even = findfirst( x -> x != root_color, colors )
    col_odd = findfirst( x-> x != col_even, colors )

    # if level sequence starts from an even number then swap the even and odd level colors
    if levelseq[1] % 2 == 0 
        col_even, col_odd = col_odd, col_even
    end

    #  for each vertex its color is col_even or col_odd depending on the parity of the level
    return vcat( [root_color], 
        [ levelseq[i] % 2 == 0 ? col_even : col_odd for i in 2:length(levelseq)])
end

#= The recursive function to calculate the next coloring in the lexicographic order

   IS INCORRECT IF GRAPH HAS CENTRAL INVOLUTION.

   Is to be deleted after thorough testing of the itaritive function.
=#  

function next_coloring_rec( level_seq, col, colors; parent_color = colors[1]-1 )

    coloring = copy(col)
    nv = length( level_seq )

    if nv == 1
        next_col_pos = findfirst( x-> x > coloring[1] && x != parent_color, colors )
        if next_col_pos isa Nothing
            return nothing
        else
            return [colors[next_col_pos]]
        end 
    end 

    first_level = level_seq[1]

    children = [ x for x in 1:nv if level_seq[x] == first_level+1 ]
    nr_children = length( children )
    subgraphs = [ level_sequence_of_subgraph( level_seq, c ) for c in children ]
    children_ends = [ end_of_subgraph( level_seq, c ) for c in children ]
    col_children = [ coloring[children[i]:children_ends[i]] for i in 1:nr_children]
    k = nr_children

    while  k>= 0
        c = children[k]

        if k == 1 
            new_cols = next_coloring_rec( subgraphs[k], col_children[k], colors, 
                                        parent_color = coloring[1] )
            if new_cols != nothing 
                coloring[children[k]:children_ends[k]] = new_cols; 
                return coloring
            else 
                if coloring[1] != colors[end]
                    coloring[1] += 1
                    if coloring[1] == parent_color 
                        coloring[1] += 1
                    end 
                    if coloring[1] > colors[end] return nothing end 
                    for i in 1:nr_children
                        cols = minimal_coloring( subgraphs[i], colors, parent_color = coloring[1] )
                        coloring[children[i]:children_ends[i]] = cols  
                    end
                    return coloring
                else
                    return nothing
                end 
            end 
        elseif k != 1 && subgraphs[k] != subgraphs[k-1]
            new_cols = next_coloring_rec( subgraphs[k], col_children[k], colors,parent_color = coloring[1] )
            if new_cols != nothing 
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
            new_cols = next_coloring_rec( subgraphs[k], col_children[k], colors, 
                                        parent_color = coloring[1])
            if new_cols != nothing 
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
    return nothing
end
 

#= 
    The iterative function to calculate the next coloring of the graph represented by level sequence 
    in the lexicographic order.

    Input: level sequence, current coloring (list of vertex colors), the list of all colors.

    The function assumes that the level sequence is in canonical form. 
=#

function next_coloring_iter( ls, col0, cols  )

    col = copy(col0)
    
    # check if it has central involution
    has_ci = has_central_involution( ls )
    
    # set up the maximum color, number of vertices, and the parents for the vertices 
    max_col = cols[end]
    n = length( ls )
    parents = vcat( [-1], [ parent_vertex( ls, v ) for v in 2:n] )
    
    # we run through the vertices of the graph using a stack 
    # initially the stack contains the root (1) and its children

    stack = vcat( [1], children_vertices( ls, 1 ))

    # we keep record of which vertices are visited
    visited = vcat( [true], fill( false, n-1 ))

    #=
        A vertex is colorable if it hasn't reached its maximum possible color.
            
        The vertex 1 is colorable if either 
        1.) The graph has no central involution and the color is 1 is not the max color; or 
        2.) The graph has central involutiuon and its color is not the second largest color. 
    =#
    colorable_1 = has_ci ? col[1] < max_col - 1 : col[1] < max_col
    
    # this variable shows how far we need to look in the tree to find the vertex whose 
    # color is modified
    look_end = n

    # we set up the list colorable to keep track which vertices are colorable
    colorable = vcat( [ colorable_1 ], fill( false, n-1 ))

    # do a standard backwards depth first search on the graph and determine which vertices are colorable
    while length( stack ) >= 1

        # inspect the last vertex in the stack
        v = pop!(stack)
        #println( v )

        if !( visited[v] )

            # process vertex v
            visited[v] = true

            # compute end point of the subgraph T_v stemming at vertex v
            v_end = end_of_subgraph( ls, v )

            # compute the root left sibling of the subgraph T_v
            # (the subgraph stemming from a vertex with the same parent as v, left of v)
            _, left_s = root_of_left_sibling_subtree( ls, v )

            if !( left_s isa Bool )
                # the left sibling exists
                # we compute the range of indices that correspond to the left sibling
                left_sibling = left_s:(v-1)
            else 
                # the left sibling does not exists
                left_sibling = []
            end 

            # check if T_v is isomorphic to the left sibling and if it has the same coloring
            # If yes, then the coloring of T_v cannot be increased and hence this part of 
            # the tree can be ignored
            if ls[v:v_end] == ls[left_sibling] && col[v:v_end] == col[left_sibling]
                #println( "skipping search tree at $v")
                continue
            end 

            # we decide if the color of v can be increased
            #println( "v is $v")
            if col[v] < max_col - 1 
                colorable[v] = true
                if v_end < look_end look_end = v_end end  
            elseif col[v] == max_col - 1 && col[parents[v]] != max_col
                colorable[v] = true
                if v_end < look_end look_end = v_end end  
            end 
            #println( "look end: $(look_end)")

            if v == look_end && colorable[v]
                # this is how far we need to go
                break 
            elseif v == look_end
                # decrease the limit vertex until which nwe need to look
                look_end -= 1
            end 

            # we calculate the children of v and put them into the stack
            desc = children_vertices( ls, v )
            for w in desc  
                push!(stack, w)
            end 

        end 
    end 

    # we check which vertices are colorable (can increase color)
    colorables = [ x for x in 1:n if colorable[x]]

    # if there is no colorable vertex, then we go to the last color in the lexicographic order 
    # and quit
    if length( colorables ) == 0 
        return nothing
    end 

    # we color the largest colorable vertex 
    v = maximum( colorables )
    #println( "coloring $v" )

    # we increase the color of v
    if v != 1 && col[parents[v]] == col[v] + 1
        # the parent of v already has color col[v] + 1 and so we increase color by two
        col[v] += 2 
    else 
        # else we increase the color by one
        col[v] += 1
    end 

    # we reset the coloring of each subtree on the right side of v
    # starting from v+1
    j = v+1
    while j <= n
    
        # find the end of the subtreee T_j stemming from vertex j
        es = end_of_subgraph( ls, j )

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
        col[j:es] = minimal_coloring( ls[j:es], cols, 
                        parent_color = col[parents[j]], root_color = root_color )

        # the following subtree that needs to be dealt with stems from the end of T_j plus 1 
        j = es+1
    end 

    # return the coloring computed
    return col
end 
# computes all colorings for a tree represented by level sequence ls
# optional parameter rec is true/false to indicate if we want the recursive or the iterative 
# function for next color.

function all_colors( ls, colors; rec = false  )

    next_col_func = rec ? next_coloring_rec : next_coloring_iter


    colorings = [ minimal_coloring( ls, colors )]
    
    while true
        new_col = next_col_func( ls, copy(colorings[end]), colors )
        if new_col != nothing 
            push!( colorings, new_col )
        else 
            return colorings 
        end 
    end 
end 


# computes the number of colorings by computing all colorings.
# TO DO: try to compute it using a formula
function nr_colors( ls, colors )

    colorings = [ minimal_coloring( ls, colors )]
    k = 1
    while true
        new_col = next_coloring_iter( ls, colorings[end], colors )
        if new_col == nothing 
            return k
        else 
            k += 1
        end 
    end 
end 
