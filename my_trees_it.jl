# This is an implementation of the algorithm to generate all trees on n vertices up to 
# isomorphism. The algorithm is described in the paper 
# CONSTANT TIME GENERATION OF FREE TREES*
# ROBERT ALAN WRIGHTS’, BRUCE RICHMONDT, ANDREW ODLYZKO AND BRENDAN D. MCKAY
#
# written by Csaba Schneider, contribution from Giosuè Muratore

using Graphs

struct TreeIt
    n_vert::Int64
end

function Base.eltype(::Type{TreeIt})
    SimpleGraph{Int64}
end
Base.@propagate_inbounds function Base.length(TI::TreeIt)::Int64

    TI.n_vert < 4 && return 1
    a = Vector{Int64}(undef, TI.n_vert) #OEIS A000081
    a[1] = 1; a[2] = 1; a[3] = 2; a[4] = 4;
    local first::Int64
    local second::Int64
    local len::Int64

    for n in 5:TI.n_vert
        first = a[n-1]
        for k in 2:(n-1)
            second = k*a[k] + 1
            for d in 2:(k-1)
                k % d > 0 && continue
                second += d*a[d]
            end
            first += second*a[n-k]
        end
        a[n] = first÷(n-1)
    end
    
    len = a[TI.n_vert] - sum(i->a[i]*a[TI.n_vert-i],1:(TI.n_vert >>> 1))

    if TI.n_vert % 2 == 0
        a_n = a[TI.n_vert >>> 1]
        len += ((a_n + 1)*a_n) >>> 1
    end

    return len
    
end

function Base.iterate( TI::TreeIt, ggd::Dict{Any,Any} = Dict() )::Union{Nothing, Tuple{SimpleGraph{Int64}, Dict{Any,Any}}}

    if isempty(ggd) #first iteration
        
        if TI.n_vert < 4
            return StarGraph(TI.n_vert), Dict('q' => 0)
        end

        n = TI.n_vert
        k = n÷2 + 1
        L = [ 1:k; 2:n-k+1 ];
        W = [ 0:k-1; 1:n-1]
        p, q, h1, h2, r =  n, n-1, k, n, k
        
        if isodd( n ) 
            c = Inf
        else 
            c = Float64(n+1)
        end 

        return LevelSequenceToGraph( L ), Dict( 'L' => L, 'W' => W, 'n' => n, 'p' => p, 'q' => q, "h1" => h1, "h2" => h2, 'c' => c, 'r' => r )
    end

    if ggd['q'] == 0 #last iteration
        return nothing
    end

    # next
    L = ggd['L']; W = ggd['W']; n = ggd['n']; p = ggd['p']; q = ggd['q'] 
    h1 = ggd["h1"]; h2 = ggd["h2"]; c = ggd['c']; r = ggd['r']

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

    return LevelSequenceToGraph( l ), Dict( 'L' => L, 'W' => W, 'n' => n, 'p' => p, 'q' => q, "h1" => h1, "h2" => h2, 'c' => c, 'r' => r )
end

function LevelSequenceToGraph( seq::Vector{Int64} )::SimpleGraph{Int64}

    edges = Dict{Int64,Int64}()
    # root = 1
    # current_level = 2
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

function a(n::Int64)::Int64
    # a(n) = (1/(n-1)) * Sum_{k=1..n-1} ( Sum_{d|k} d*a(d) ) * a(n-k)
    n < 3 && return 1;

    local first::Int64 = 0
    local second::Int64
    
    # first = 0

    for k in 1:(n-1)
        second = 0
        for d in 1:k
            k % d > 0 && continue
            second += d*a(d)
        end
        first += second * a(n-k)
    end

    return first ÷ (n-1)
end

println(raw"This is an implementation of the algorithm to generate
all trees on n vertices up to isomorphism.
The algorithm is described in the paper:
    CONSTANT TIME GENERATION OF FREE TREES
by ROBERT ALAN WRIGHTS’, BRUCE RICHMONDT, ANDREW ODLYZKO AND BRENDAN D. MCKAY 
written by Csaba Schneider, contribution from Giosuè Muratore.");
