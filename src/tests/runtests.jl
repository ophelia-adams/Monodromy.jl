using Test
using Monodromy

@testset "Monodromy.jl" begin
	include("pathtests.jl")
	include("permutationtests.jl")
	include("covertests.jl")
	include("monodromytests.jl")
end