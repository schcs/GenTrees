function random_level_seq( n )
    seq = [1,2]
    for k in 3:n
        push!( seq, rand( 2:seq[end]+1 ))
    end
    return seq
end

function level_sequence( gr; s = 1 )

    pr = dfs_parents( gr, s )
    ls = [1]
    for i in vertices( gr )
        push!( ls, i == s ? 1 : ls[pr[i]]+1 )
    end 

    return ls 
end 