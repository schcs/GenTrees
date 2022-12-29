#= 
    This file contains a function to compute the number of colorations (modulo isomorphism) of a 
    tree g of level sequence ls with n colors.
    Author: Giosuè Muratore
=#

using Graphs
using Combinatorics

function n_colorations(g::Graph, n::Int64)::Int64
    ls = 1 .+ bellman_ford_shortest_paths(g,1).dists
    return n_colorations(ls, n)
end


function n_colorations(ls::Vector{Int64}, n::Int64)::Int64

    if length(ls) < 3
        return ls[1] == 1 ? binomial(n, length(ls)) : (n-1)^length(ls) # ls[1] == 1 is equivalent to be a starting-point graph
    end

    my_child = findall(i -> i>length(ls) || ls[i]==ls[1]+ 1, 1:length(ls)+1)  # find all the children of the root, plus length(ls)+1
    

    if ls[1] == 1  # ls[1] == 1 is equivalent to be a starting-point graph
        if iseven(length(ls))  # necessary condition to have the bad involution
            if view(ls,my_child[1]+1:my_child[2]-1) == 1 .+ view(ls,my_child[2]:length(ls))  # check if it has the bad involution
                c = n_colorations(ls[my_child[1]:my_child[2]-1], n)   # compute the number of colorations of the main subgraph
                return div(n*(c^2),2*(n-1))  # return the number of coloration computing only the number of colorations of the main subtree
            end
        end
        ans = n  # in the starting-point graph, the root can assume n values since it has no parent
    else
        ans = n - 1 # we are not in the starting-point graph, so the root has a parent to deal with
    end

# here we compute the number of colorations of each subgraph
    last_sub = ls[my_child[1]:my_child[2]-1]  # this is the subgraph
    m = 1                                     # this is its multiplicity

    for x in 3:length(my_child)
        if last_sub == view(ls, my_child[x-1]:my_child[x]-1)  # we run up to find a different subgraph
            m += 1
        else
            c = n_colorations(last_sub, n)   # number of colorations of this subgraph...
            ans *= binomial(c+m-1,m)         # ...counted with multiplicity
            last_sub = ls[my_child[x-1]:my_child[x]-1]  # pass to the next subgraph
            m = 1
        end
    end

    c = n_colorations(last_sub, n)  # compute the number of colorations of the last subgraph
    ans *= binomial(c+m-1,m)        # with multiplicity

    return ans
end