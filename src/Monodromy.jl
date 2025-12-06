"""
	Monodromy

A package for calculating monodromy actions and visualizing them over the complex plane.
Provides tools for defining covers, paths, computing lifts, and interactive visualization.

See `interact_rabbits()` or the other `interact_*()` functions to get started.
"""
module Monodromy
	using GLMakie
	using Serialization

	include("core/types.jl")
	include("core/paths.jl")
	include("core/covers.jl")
	include("core/lifting.jl")
	include("core/permutations.jl")
	include("core/models.jl")

	include("interact/themes.jl")
	include("interact/recipes.jl")
	include("interact/ui.jl")
	include("interact/interact.jl")

	include("examples/chebyshev.jl")
	include("examples/exponential.jl")
	include("examples/power.jl")
	include("examples/rabbits.jl")
	include("examples/symmseven.jl")

	# types
	export ComplexPath
	export ComplexCover
	export ComplexEtaleCover
	export Permutation

	# cover functions
	export diff
	export branch_locus

	# path functions
	export head
	export tail
	export loop
	export lollipop
	export piecewiselinear
	export subdivide

	# monodromy functions
	export lift
	export monodromy
	export monodromy_step
	export monodromy_permutation

	# permutation functions
	export cycleof
	export cycles
	export inverse

	# monodromy models
	export ComplexMonodromy
	export reset!
	export extendpath!
	export getpermutation

	# interaction functions
	export interact
	export OAPlain

	# example interactions
	export Power
	export T4
	export rabbit_cover
	export interact_power
	export interact_exponential
	export interact_chebyshev
	export interact_rabbits
	export interact_symmetric_seven

	# new interaction
	export _interact

	function __init__()
		set_theme!(OAPlain())
	end
end
