"""
	monodromy_step(
		f::ComplexEtaleCover,
		x₀::ComplexF64,
		t₀::ComplexF64,
		t₁::ComplexF64;
		corrector_steps::Int64=2
	)::ComplexF64

Carries out one step of path lifting from `x₀` to `x₁` above `t₀` to `t₁`.
This implementation just does one step of Euler's method:
	x₁ ≈ x₀ + Δt/f'(x₀),
followed by the specified number of Newton's method steps for solving
	f(z) = t₁
starting from the guess for `x₁` above, as path correction.
"""
function monodromy_step(
	f::ComplexEtaleCover,
	x₀::ComplexF64,
	t₀::ComplexF64,
	t₁::ComplexF64;
	corrector_steps::Int64=2
)::ComplexF64
	Δt = t₁ - t₀
	df = diff(f)
	x₁ = x₀ + Δt/df(x₀)
	for _ in 1:corrector_steps
		x₁ = x₁ - (f(x₁) - t₁)/df(x₁)
	end
	return x₁
end

"""
	monodromy(f::ComplexEtaleCover,
		x::ComplexF64,
		path::ComplexPath;
		corrector_steps::Int64
	)::ComplexF64

Monodromy action: lift a path `P` over `x` and return the endpoint.
Marginal space efficiency gain by not saving the path as it is lifted.
"""
function monodromy(
	f::ComplexEtaleCover,
	x::ComplexF64,
	path::ComplexPath;
	corrector_steps::Int64=2
)::ComplexF64
	for k in 2:length(path)
		x = monodromy_step(f, x, path[k-1], path[k];
			corrector_steps=corrector_steps)
	end
	return x
end

"""
	monodromy(f::ComplexEtaleCover,
		X::Vector{ComplexF64},
		path::ComplexPath;
		corrector_steps::Int64
	)::ComplexF64

Lift a path `P` over each `x` in `X` and return the endpoints. Spreads the calculation across some threads; basically speeds it up by a factor of the number of threads available when the degree is large enough.
"""
function monodromy(
	f::ComplexEtaleCover,
	X::Vector{ComplexF64},
	path::ComplexPath;
	corrector_steps::Int64=2
)::Vector{ComplexF64}
	X = copy(X)
	Threads.@threads for i in length(X)
		X[i] = monodromy(f,X[i],path;
			corrector_steps=corrector_steps)
	end
	return X
end
function monodromy(
	f::ComplexEtaleCover,
	X::Dict{Symbol,ComplexF64},
	path::ComplexPath;
	corrector_steps::Int64=2
)::Dict{Symbol,ComplexF64}
	X = copy(X)
	Threads.@threads for k in collect(keys(X))
		X[k] = monodromy(f,X[k],path;
			corrector_steps=corrector_steps)
	end
	return X
end

"""
	lift(
		f::ComplexEtaleCover{X,Y},
		x::ComplexF64,
		path::ComplexPath;
		corrector_steps=2
	)::ComplexPath

Lifts the path as a sequence of monodromy steps, though only to a piecewise linear approximation.
"""
function lift(
	f::ComplexEtaleCover{X,Y},
	x::ComplexF64,
	path::ComplexPath;
	corrector_steps=2
)::ComplexPath where {X <: Any, Y <: Any}
	N = length(path)
	L = ComplexPath(Vector{ComplexF64}(undef,N))
	L[1] = x
	for k in 2:N
		L[k] = monodromy_step(f,L[k-1], path[k-1], path[k]; corrector_steps=corrector_steps)
	end
	return L
end


"""
	lift(
		f::ComplexEtaleCover{X,Y},
		X::Vector{ComplexF64},
		path::ComplexPath;
		corrector_steps=2
	)::ComplexPath

Lifts a path over multiple fibers.
"""
function lift(
	f::ComplexEtaleCover,
	X::Vector{ComplexF64},
	path::ComplexPath;
	corrector_steps=2
)::Vector{ComplexPath}
	n = length(X)
	N = length(path)
	L = Vector{ComplexPath}(undef, n)
	Threads.@threads for i in 1:n
		L[i] = lift(f,X[i],path; corrector_steps=corrector_steps)
	end
	return L
end
function lift(
	f::ComplexEtaleCover,
	X::Dict{Symbol, ComplexF64},
	path::ComplexPath;
	corrector_steps=2
)::Dict{Symbol, ComplexPath}
	n = length(X)
	N = length(path)
	L = Dict{Symbol,ComplexPath}()
	Threads.@threads for k in collect(keys(X))
		L[k] = lift(f,X[k],path; corrector_steps=corrector_steps)
	end
	return L
end

"""
	monodromy_permutation(
		f::ComplexEtaleCover{X,Y},
		fibers::Dict{Symbol, ComplexF64},
		loop::ComplexPath;
		corrector_steps=2
	)::Permutation

Given (named) fibers and a loop to lift, this returns a dictionary representing the permutation action. Does not currently verify that the provided collection of fibers is complete or consistent.
"""
function monodromy_permutation(
	f::ComplexEtaleCover{X,Y},
	fibers::Dict{Symbol, ComplexF64},
	loop::ComplexPath;
	corrector_steps=2
)::Permutation where {X <: Any, Y <: Any}
	perm = Dict{Symbol,Symbol}()
	permutedfibers = monodromy(f, fibers, loop; corrector_steps=corrector_steps)
	for name in keys(fibers)
		x = fibers[name]
		y = permutedfibers[name]
		perm[name] = findnearest(fibers,y)
	end
	return Permutation(perm)
end

function findnearest(
	fibers::Dict{Symbol, ComplexF64},
	z::ComplexF64,
)
	local current_best::Symbol
	current_distance = Inf

	for (name, value) in fibers
		dist = abs(value - z)
		if dist < current_distance
			current_best = name
			current_distance = dist
		end
	end
	return current_best
end