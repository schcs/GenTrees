
#= 
    The following function decides if the tree represented by the level sequence ls has a 
    central involution. The function assumes that the level sequence is in canonical form.

    A central involution of a tree is an automorphism of order two with no fixed points. 

    Note that if a graph has central involution, then it must have two centers (that is, vertices that 
    are in the middle of the longest paths).

    If the level sequence is in canonical form, then the two centers of the tree are vertices 1 and 2. 
    One needs only to check if the subtree stemming from 2 and the subtree stemming from one 
    with the subtree stemming from 2 removed have identical level sequences. 
=#

function has_central_involution( ls )

    l = length( ls )
    
    # the tree is split into a "left tree" and a "right tree". The left tree is simply the 
    # subtree stemming from two.

    # we find the end of the left tree. It is the vertex before the first vertex with 
    # level 2.
    
    end_left = 0
    for i in 3:l
        if ls[i] == 2
            end_left = i
            break
        end 
    end 

    # if end_left is still zero, then the graph has unique vertex at level two and has no central involution
    if end_left == 0 return false end 


    # tree left if the tree between 2 and end_left-1
    tree_left = ls[2:end_left-1]

    # tree right is the tree [1] cat [end_left..end]. 
    # One has to be added to the levels to compare with tree_left
    tree_right = [ ls[i] + 1 for i in vcat( [1], end_left:l )]

    # has central ivolution if and only if the two graphs are the same
    has_ci = tree_left == tree_right
    #set_prop!( t, :has_ci, has_ci )
    return has_ci
end    