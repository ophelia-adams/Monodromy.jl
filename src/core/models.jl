"""
	ComplexMonodromy(
		cover::ComplexEtaleCover
		names::Vector{Symbol}
		fibers::Dict{Symbol, ComplexF64}
		base::ComplexF64
		lifted_paths::Dict{Symbol, ComplexPath}
		base_path::ComplexPath
	)

Sets up a monodromy situation with the specified cover, fibers, and base. The struct further contains the current base path and its lifts, as well as the names of the fibers. The constructure does not yet validate the provided data, but this may be added.

Methods on this struct are as follows:

- `reset!`: delete the current base and lifted paths, restore the original.
- `extendpath!`: extend the base path, and lift it, by
	- a single complex number, or
	- a path, which is assumed to properly extend (i.e. not overlap) the current base path
- `getpermutation`: return the permutation estimated from the current lifted paths
- `refinefibers`: refine the given fibers over the base

"""
mutable struct ComplexMonodromy <: AbstractMonodromy{ComplexF64, ComplexF64}
	cover::ComplexEtaleCover
	names::Vector{Symbol}
	fibers::Dict{Symbol, ComplexF64}
	base::ComplexF64
	lifted_paths::Dict{Symbol, ComplexPath}
	base_path::ComplexPath

	function ComplexMonodromy(cover, fibers, base)
		# later, this will intervene for some kind of validation
		names = collect(keys(fibers))
		lifted_paths = Dict(k => ComplexPath(fibers[k]) for k in names)
		base_path = ComplexPath(base)
		new(cover, names, fibers, base, lifted_paths, base_path)
	end
end

function reset!(cm::ComplexMonodromy)
	cm.base_path = ComplexPath(cm.base)
	for k in cm.names
		cm.lifted_paths[k] = ComplexPath(cm.fibers[k])
	end
	return nothing
end

function extendpath!(cm::ComplexMonodromy, P::ComplexPath)
	f = cm.cover
	# lift(...) expects the path to include the base point
	Q = ComplexPath(cm.base_path[end]) * P
	Threads.@threads for k in cm.names
		extension = lift(f, cm.lifted_paths[k][end], Q)[2:end]
		append!(cm.lifted_paths[k], extension)
	end
	append!(cm.base_path, P)
	return nothing
end

function extendpath!(cm::ComplexMonodromy, p::ComplexF64)
	f = cm.cover
	# probably not worth the thread spawn cost for small degrees
	Threads.@threads for k in cm.names
		push!(cm.lifted_paths[k],
			monodromy_step(f,
				cm.lifted_paths[k][end],
				cm.base_path[end],
				p
			)
		)
	end
	push!(cm.base_path, p)
end

function getpermutation(cm::ComplexMonodromy)::Permutation
	return permbynearest(cm.fibers, Dict(k => cm.lifted_paths[k][end] for k in cm.names))
end

"""
	refinefibers!(cm::ComplexMonodromy, n::Int64)

Refine the each fiber by applying `n` steps of Newton's method. Causes a reset of the lifted paths.
"""
function refinefibers!(cm::ComplexMonodromy, n::Int64)
	# hit the fibers with some newton's method
	f = cm.cover
	df = diff(cm.cover)
	t = cm.base
	for k in cm.names
		x = cm.fibers[k]
		for _ in 1:n
			x = x - (f(x) - t)/df(x)
		end
		cm.fibers[k] = x
	end
	reset!(cm)
end

"""
	close_base_path!(cm::ComplexMonodromy, dz=0.1)

Closes the base path with a `piecewiselinear` of specified step size.
"""
function close_base_path!(cm::ComplexMonodromy, dz=0.1)
	closing = piecewiselinear(cm.base_path[end],cm.base_path[1],0.1)[1:end]
	extendpath!(cm, closing)
end

"""
	smooth_base_path!(cm::ComplexMonodromy)

Smooths the base path and recalculates the lift.
"""
function smooth_base_path!(cm::ComplexMonodromy)
	P = copy(cm.base_path)
	sP = smooth(P, :chaikin)[2:end]
	reset!(cm)
	extendpath!(cm, sP)
end