"""
	ComplexCover(f::Function)

Just a good old map f: ℂ → ℂ, which should be at least holomorphic (with a discrete branch locus, but that should follow from holomorphic). Typically a rational map.

Parameterizing by the type of the stored function significantly improves performance, which I learned from
https://discourse.julialang.org/t/structures-containing-a-function-field/65696
"""
struct ComplexCover{F} <: AbstractCover{ComplexF64,ComplexF64}
	f::F
	function ComplexCover(f)
		new{typeof(f)}(f)
	end
end

"""
	ComplexEtaleCover

This is a `ComplexCover` augmented with the data of:

- its branch locus, and
- its derivative.

Such a map is étale when the codomain is punctured at the branches and the domain at the preimages of the branches. The derivative provides the information necessary to carry out a lift.

```julia
f(x) = x^3
df(x) = 3x^2
branches = Set([0.0 + 0.0im])
cube = ComplexEtaleCover(f, df, branches)
```
"""
struct ComplexEtaleCover{F,D} <: AbstractCover{ComplexF64,ComplexF64}
	f::ComplexCover{F}
	df::D
	branch_locus::Set{ComplexF64}

	function ComplexEtaleCover(
		f::ComplexCover{F},
		df::D,
		branch_locus::Set{ComplexF64}
	) where {F<:Any,D<:Any}
		if isempty(branch_locus)
			throw("An étale [branched] cover of ℙ¹(ℂ) must come with a branch locus.")
		end
		return new{F,D}(f,df,branch_locus)
	end

	function ComplexEtaleCover(
		f::F,
		df::D,
		branch_locus::Set{ComplexF64}
	) where {F<:Function,D<:Any}
		if isempty(branch_locus)
			throw("An étale [branched] cover of ℙ¹(ℂ) must come with a branch locus.")
		end
		return new{F,D}(ComplexCover(f),df,branch_locus)
	end
end


(C::ComplexCover)(x::ComplexF64)::ComplexF64 = C.f(x)
(C::ComplexCover)(x::Number)::ComplexF64 = C.f(complex(float(x)))
(C::ComplexCover)(D::ComplexCover)::ComplexCover = ComplexCover(z -> C(D(z)))
(C::ComplexEtaleCover)(x::Number)::ComplexF64 = C.f(x)
Base.diff(C::ComplexEtaleCover) = C.df # avoid accidental shadowing
branch_locus(C::ComplexEtaleCover) = C.branch_locus

# composition rule:
# branch(f∘g) = branch(f) ∪ f(branch(g))

function (C::ComplexEtaleCover)(D::ComplexEtaleCover)::ComplexEtaleCover
	function dCD(x::ComplexF64)::ComplexF64
		 return diff(C)(D(x))*(diff(D)(x))
	end
	function CD(x::ComplexF64)::ComplexF64
		 return C.f(D.f(x))
	end
	branchCD = copy(branch_locus(C))
	for z in branch_locus(D)
		push!(branchCD, C(z))
	end
	return ComplexEtaleCover(CD,dCD,branchCD)
end



