"""
	AbstractPath{T}

A path through a space of type `T`. Often, but not always, represents a continuous map from [0,1] to the space.
"""
abstract type AbstractPath{T} end

"""
	AbstractCover{X,Y}

Essentially any map f: X → Y.
"""
abstract type AbstractCover{X,Y} end

"""
	AbstractEtaleCover{X,Y}

A cover which should satisfy the lifting property. Examples include

- A topological cover.
- An étale morphism of schemes.
- A rational map with its branch locus marked (since this determines where one must puncture to make it a true étale morphism).

I am inclined to build lifting data into the type definition at some point.
"""
abstract type AbstractEtaleCover{X,Y} <: AbstractCover{X,Y} end

"""
	head(P)

Returns the end of the path.
"""
function head(P::AbstractPath{T})::T where T
	error("head not implemented for $(typeof(P))")
end

"""
	tail(P)

Returns the start of the path.
"""
function tail(P::AbstractPath{T})::T where T
	error("tail not implemented for $(typeof(P))")
end

"""
	P*Q

Concatenates paths. Should requires head(P) ≈ tail(Q), or really that one uses pointed paths.
"""

"""
	x^P

The path groupoid action: when the path `P` starts at `x`, this should return the head of `P`. For approximate paths, an implementation should check proximity of `x` to the tail.
"""
function Base.:^(x::T, P::AbstractPath{T}) where T <: Any
	error("Implement application for $(typeof(P)).")
end

"""
	C(x)

Evaluate a cover at a point.
"""
function (C::AbstractCover{X,Y})(x::X)::Y where {X,Y}<:Any
	error("Implement evaluation for $(typeof(C)).")
end

"""
	C(D)

Composition of covers.
"""
function (C::AbstractCover{Y,Z})(D::AbstractCover{X,Y})::AbstractCover{X,Z} where {X,Y,Z} <:Any
	error("Implement composition for $(typeof(C)).")
end

"""
	lift(C::AbstractEtaleCover{X,Y}, x::X, path::AbstractPath{Y})::AbstractPath{X}

An étale cover has the lifting property: given a point x in the domain and a path in the codomain starting at C(x), there's a unique lift of P to a path starting at x.
"""
function lift(
	C::AbstractEtaleCover{X,Y},
	x::X,
	path::AbstractPath{Y}
)::AbstractPath{X} where {X <: Any, Y <: Any}
	error("Implement path lifting for $(typeof(C)).")
end

"""
	monodromy(C::AbstractEtaleCover{X,Y}, x::X, path::AbstractPath{Y})::X

The actual monodromy action: lift `path` to `x`, then follow the path to its end.
"""
function monodromy(
	C::AbstractEtaleCover{X,Y},
	x::X,
	path::AbstractPath{Y}
)::X where {X,Y} <: Any
	return head(lift(C, x, path))
end

"""
	AbstractMonodromy

Struct enclosing a particular monodromy situation. Generally, its fields should include:

- `cover::AbstractEtaleCover{X,Y}`
- `fibers::Dict{Symbol, X}`
- `base::Y`
- `lifted_paths::Dict{Symbol, AbstractPath{X}}`
- `base_path::AbstractPath{Y
}`

"""
abstract type AbstractMonodromy end