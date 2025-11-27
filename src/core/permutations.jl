"""
	Permutation

Wrapper over a dictionary `dict` representing a permutation. The inner constructor checks it is a permutation.
"""
struct Permutation
	perm::Dict{Symbol,Symbol}
	inv::Dict{Symbol,Symbol}
	function Permutation(perm::Dict{Symbol,Symbol})
		inv = Dict(value => key for (key, value) in perm)

		ks = Set(keys(perm))
		vs = Set(keys(inv))

		if !(ks == vs) || !(length(perm) == length(inv))
			throw("$perm is not a permutation: not invertible.")
		end

		new(perm,inv)
	end

end

Base.getindex(p::Permutation, key::Symbol)::Symbol = p.perm[key]
Base.isempty(p::Permutation)::Bool = isempty(p.perm)
Base.keys(p::Permutation)::Vector{Symbol} = [k for k in keys(p.perm)]
Base.values(p::Permutation)::Vector{Symbol} = [v for v in values(p.perm)]


function Base.show(io::IO, p::Permutation)
	if isempty(p)
		println("Empty permutation; probably an error.")
	else
		cs = cycles(p)
		println("Permutation on:")
		println(keys(p))
		println("given by the cycles")
		for c in cs
			println(io, string(c))
		end
	end
end

"""
	cycleof(p::Permutation, k::Symbol)::Vector{Symbol}

Calculates the cycle, or orbit, of permutation `p` on symbol `k`.
"""
function cycleof(p::Permutation, k::Symbol)::Vector{Symbol}
	cycle = Vector{Symbol}()
	push!(cycle,k)
	while !(p[cycle[end]] == k)
		push!(cycle,p[cycle[end]])
	end
	return cycle
end

"""
	cycles(p::Permutation)::Vector{Vector{Symbol}}

Returns a representation of `p` as a list of disjoint cycles.
"""
function cycles(p::Permutation)::Vector{Vector{Symbol}}
	remaining = Set(keys(p))
	cycles = Vector{Vector{Symbol}}()

	while !(isempty(remaining))
		name = first(remaining)
		cycle = cycleof(p, name)
		push!(cycles, cycle)
		setdiff!(remaining, cycle)
	end

	return cycles
end

"""
	cyclestring(p::Permutation)

Returns a string with the decomposition of `p` into disjoint cycles.
"""
function cyclestring(p::Permutation)
	cycs = cycles(p)
	s = " "
	for c in cycs
		if length(c) > 1
			s = s*"( "
			s = s*prod([string(l)*", " for l in c[1:end-1]])
			s = s*string(c[end])*" ) "
		end
	end
	s = s == " " ? "id" : s[2:end-1]
	return s
end

"""
	inverse(p::Permutation)::Permutation

Returns the inverse of a permutation; this is already part of the `Permutation` struct because it has to be calculated during the validation anywa.
"""
inverse(p::Permutation)::Permutation = Permutation(p.inv)

"""
	((s::Symbol)^(p::Permutation))::Symbol

Applies the permutation `p` to `s`, acting on the *right*.
"""
Base.:^(s::Symbol, p::Permutation) = p[s]

"""
	((p::Permutation)*(q::Permutation))::Permutation

Composes permutations `p` and `q`, using the more natural *right* action, so that
	a^(p*q) = (a^p)^q
"""
Base.:*(p::Permutation, q::Permutation) = Permutation(Dict(a => (a^p)^q for a in values(p)))

"""
	((p::Permutation)^(q::Permutation))::Permutation

Conjugates the permutation `p` by the permutation `q`.
"""
Base.:^(p::Permutation, q::Permutation) = inverse(q)*p*q
