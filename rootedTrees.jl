#=
rootedTrees:
- Julia version: 1
- Author: Jeane
- Date: 2022-06-22
=#
function random_seq2( n; n0 = 1 )

	s = [n0]
	for i in 2:n
		push!( s, rand( n0+1:s[end]+1 ))
	end
	return s
end

#"level = seq[1] + 1" generalize for root = n0
function splitSequence(seq, level = seq[1] + 1)
	#find all occurences of x = level and store it in a vector of vectors
	v_inLevel = findall(x -> x == level, seq)
    subtrees = [zeros(Int64, 0) for c in v_inLevel]
    k = 0
	#start searching from first occurence
    for vertex in v_inLevel[1]:length(seq)
		#new induced subtree
    	if seq[vertex] == level
			k += 1
       		push!(subtrees[k], seq[vertex])
		#childrent of kth vertex = level
       	elseif seq[vertex] > level
       		push!(subtrees[k], seq[vertex])
       	end
   end
   return subtrees
end


function canonical_sorting(seq)
	#base case: |sequences| < 3 => already in canonical order
	if length(seq) <= 3
		return seq
	end
	split = splitSequence(seq)
	#walks through subsequences
	for i in 1:length(split)
		split[i] = canonical_sorting(split[i])
	end
	#sort decreasing
	sort!(split, rev = true)
	#concatenate and add root
	return pushfirst!(vcat(split...), seq[1])
end

mutable struct indSubtrees
	subtree :: Vector{Int64}
	index :: Vector{Int64}
end

function splitSequence2(seq, level = seq[1] + 1)
	#find all occurences of x = level and store it in a vector of vectors
	v_inLevel = findall(x -> x == level, seq)
    subtrees = [indSubtrees([], [0,0]) for c in v_inLevel]
    k = 0
	#start searching
    for vertex in v_inLevel[1]:length(seq)
		#new induced subtree
    	if seq[vertex] == level
			k += 1
       		push!(subtrees[k].subtree, seq[vertex])
			#start index
			subtrees[k].index[1] = vertex
		#childrent
       	elseif seq[vertex] > level
       		push!(subtrees[k].subtree, seq[vertex])
			#end index
			subtrees[k].index[2] = vertex
       	end
		#case: prev node is leave
		if length(subtrees[k].subtree) == 1
			subtrees[k].index[2] = subtrees[k].index[1]
		end

   	end
   	return subtrees
end

function canonical_sortingIter2(seq)
	#repeat process max(seq) - 2 times
	for k in reverse(1:(maximum(seq) - 2))
		strcSubtrees = splitSequence2(seq, k)
		#order each ind subtree of level k
		for c in 1:length(strcSubtrees)
			newsub = []
			sub = strcSubtrees[c].subtree
			if length(sub) > 3
				#order
				s = splitSequence(sub)
				sort!(s, rev = true)
				newsub = vcat(s...)
				pushfirst!(newsub, newsub[1] - 1)
				#replace -> original sequence
				seq[strcSubtrees[c].index[1]:strcSubtrees[c].index[2]] = newsub
			end
		end
	end
	return seq

end

function splitSequence3(seq, level = seq[1] + 1)
	#find all occurences of x = level and store it in a vector of vectors
	v_inLevel = findall(x -> x == level, seq)
    subtrees = [[zeros(Int64, 0), [0,0]] for c in v_inLevel]
    k = 0
	#start searching
    for vertex in v_inLevel[1]:length(seq)
		#new induced subtree
    	if seq[vertex] == level
			k += 1
       		push!(subtrees[k][1], seq[vertex])
			#start index
			subtrees[k][2][1] = vertex
		#childrent
       	elseif seq[vertex] > level
       		push!(subtrees[k][1], seq[vertex])
			#end index
			subtrees[k][2][2] = vertex
       	end
		#case: prev node is leave
		if length(subtrees[k][1]) == 1
			subtrees[k][2][2] = subtrees[k][2][1]
		end

   	end
   	return subtrees
end

function canonical_sortingIter3(seq)
	#repeat process max(seq) - 2 times
	for k in reverse(1:(maximum(seq) - 2))
		subtrees = splitSequence3(seq, k)
		#order each ind subtree of level k
		for c in 1:length(subtrees)
			newsub = []
			sub = subtrees[c][1]
			if length(sub) > 3
				#order
				s = splitSequence(sub)
				sort!(s, rev = true)
				newsub = vcat(s...)
				pushfirst!(newsub, newsub[1] - 1)
				#replace -> original sequence
				seq[subtrees[c][2][1]:subtrees[c][2][2]] = newsub
			end
		end
	end
	return seq

end