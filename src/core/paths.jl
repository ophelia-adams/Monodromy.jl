"""
	ComplexPath <: AbstractPath{ComplexF64}

A list of points, which amounts to a piecewise-linear path in the complex plane.
"""
struct ComplexPath <: AbstractPath{ComplexF64}
	elements::Vector{ComplexF64}
	ComplexPath(P::Vector{ComplexF64}) = new(P)
	ComplexPath(P::Vector{T}) where T <:Number = new(convert(Vector{ComplexF64},P))
	ComplexPath(p::T) where T <:Number = new([ComplexF64(p)])
end

# path requirements

head(P::ComplexPath) = return P.elements[end]
tail(P::ComplexPath) = P.elements[1]
Base.:*(P::ComplexPath, Q::ComplexPath) = ComplexPath([P.elements; Q.elements])

# assorted iteration/vector features

Base.iterate(P::ComplexPath, n=1) = n > length(P) ? nothing : (P.elements[n], n+1)
Base.length(P::ComplexPath) = length(P.elements)
Base.lastindex(P::ComplexPath) = lastindex(P.elements)
Base.getindex(P::ComplexPath, i::Int) = P.elements[i]
Base.getindex(P::ComplexPath, u::UnitRange{Int64}) = P.elements[u.start:u.stop]
Base.setindex!(P::ComplexPath, p, i::Int) = P.elements[i] = p
Base.push!(P::ComplexPath, p) = begin push!(P.elements, p); P end
Base.reverse(P::ComplexPath) = ComplexPath(reverse(copy(P.elements)))
Base.reverse!(P::ComplexPath) = begin reverse!(P.elements); P end
Base.pop!(P::ComplexPath) = begin pop!(P.elements); P end
Base.copy(P::ComplexPath) = ComplexPath(P.elements)

function Base.show(io::IO, P::ComplexPath)
	p = tail(P)
	q = head(P)
	n = length(P)
	print(io, "ComplexPath from $p to $q with $n elements.")
end


"""
	subdivide(
		P::ComplexPath,
		n::Int64
	)::ComplexPath

Refines a `ComplexPath`. Between each current point, it will add `n-1` more. Total length goes from `N` to `nN+1`, roughly an `n`-fold increase.
"""
function subdivide(
	P::ComplexPath,
	n::Int64
)::ComplexPath
	if n < 1
		throw("Subdivision factor must be positive.")
	end
	N = length(P)
	Q = ComplexPath(Vector{ComplexF64}(undef, (N-1)*(n-1) + N))
	for i in 1:(N-1)
		qi = n*(i-1) + 1
		p = Q[qi] = P[i]
		d = (P[i+1] - p)/n
		for j in 1:n-1
			Q[qi + j] = p + j*d
		end
	end
	Q[end] = P[end]
	return Q
end


"""
	loop(c::ComplexF64, z::ComplexF64, n_points::Int64 )::ComplexPath

Clockwise loop around `c` starting at `z`. It has `n+1` points, starting and ending at `z`.
"""
function loop(c::ComplexF64, z::ComplexF64, n_points::Int64)::ComplexPath
	return ComplexPath([c + (z-c)*exp(2*pi*im*k/n_points) for k in 0:(n_points)])
end

"""
	lollipop(c::ComplexF64, z::ComplexF64, r::Float64, dz::Float64)::ComplexPath

Creates a "lollipop" path starting at `z` around `c` with `n` points comprised of:

- a clockwise loop of radius `r` around `c`,
- straight line paths to and from from `z` to this circle

and point spaced roughly `dz` apart.
"""
function lollipop(c::ComplexF64, z::ComplexF64, r::Float64, dz::Float64)
	dir = (c - z)/abs(c-z)
	dist = abs(c-z) - r

	cloop = loop(c, c - r*dir, round(Int, 2*pi*r/dz))
	czpath = ComplexPath([z + n*dz*dir for n in 0:trunc(Int, dist/dz)])

	return czpath*cloop*reverse(czpath)
end

"""
	piecewiselinear(vertices::Vector{ComplexF64}, dz::Float64})::ComplexPath

Returns a piecewise linear path, with vertices at `points` and intermediate steps spaced out by approximately `dz` (or less). It is not necessarily a loop; ensure that the first and last points coincide if you want one.
"""
function piecewiselinear(vertices::Vector{ComplexF64}, dz::Float64)::ComplexPath
	if length(vertices) < 2
		@warn "You requested a piecewise linear path with a single vertex."
		return vertices
	end

	deltas = vertices[2:end] - vertices[1:end-1]
	dists = abs.(deltas)
	dirs = deltas./dists

	nbetweenpoints = convert(Vector{Int},trunc.(dists./dz))
	nvertices = length(vertices)

	P = Vector{ComplexF64}()
	sizehint!(P, sum(nbetweenpoints) + nvertices)

	for i in 1:(nvertices-1)
		v = vertices[i]
		push!(P,v)
		dir = dirs[i]
		for j in 1:nbetweenpoints[i]
			push!(P, v + dir*dz*j)
		end
	end
	push!(P,vertices[end])

	return ComplexPath(P)
end