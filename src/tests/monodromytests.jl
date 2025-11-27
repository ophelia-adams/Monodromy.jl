@testset "Monodromy and Lifting" begin
	@testset "Monodromy step" begin
		# Use z^2 as test case
		f = Power(2)

		# Start at 1+0im, which maps to 1+0im
		x₀ = 1.0+0.0im
		t₀ = 1.0+0.0im
		t₁ = 1.1+0.0im

		x₁ = monodromy_step(f, x₀, t₀, t₁; corrector_steps=5)

		@test abs(f(x₁) - t₁) < 1e-10
	end

	@testset "Monodromy along path" begin
		# start at sqrt(2) ⟼ 2 and follow a path from 2 to 3 ⟻ sqrt(3).
		f = Power(2)
		x = sqrt(2.0)+0.0im
		path = subdivide(ComplexPath([2.0+0.0im, 3.0+0.0im]),20)
		result = monodromy(f, x, path; corrector_steps=5)
		@test abs(f(result) - 3.0) < 1e-10
		@test abs(result - sqrt(3.0)) < 0.01
	end

	@testset "Lift path" begin
		f = Power(2)
		x = 1.0+0.0im
		path = ComplexPath([1.0+0.0im, 2.0+0.0im, 3.0+0.0im])

		lifted = lift(f, x, path; corrector_steps=5)

		@test length(lifted) == length(path)
		@test tail(lifted) == x

		# verify projection of path
		for i in 1:length(path)
			@test abs(f(lifted[i]) - path[i]) < 0.01
		end
	end

	@testset "Monodromy around loop" begin
		# z^3 and cube roots of unity
		# the lift of a single loop at 1.0 lifts to a path at 1.0 from to ζ₃
		# a second loop to (ζ₃)²
		f = Power(3)
		x = 1.0+0.0im
		lp = loop(0.0+0.0im, 1.0+0.0im, 100)

		result = monodromy(f, x, lp; corrector_steps=3)
		zeta = exp(2*pi*im/3)
		@test abs(result - zeta) < 0.001
	end

	@testset "Monodromy permutation" begin
		# z^3 with three fibers
		f = Power(3)

		zeta = exp(2*pi*im/3)
		fibers = Dict(
			:one => 1.0+0.0im,
			:zeta => zeta,
			:zeta2 => zeta^2
		)

		lp = loop(0.0+0.0im, 1.0+0.0im, 100)

		perm = monodromy_permutation(f, fibers, lp; corrector_steps=3)

		@test !isempty(perm)
		cs = cycles(perm)
		@test length(cs) == 1
		@test length(cs[1]) == 3
		@test (:one)^perm == :zeta
		@test (:zeta)^perm == :zeta2
		@test (:zeta2)^perm == :one
	end

	@testset "findnearest" begin
		import Monodromy: findnearest

		fiber = Dict(
			:a => 1.0+0.0im,
			:b => 2.0+0.0im,
			:c => 3.0+0.0im
		)

		@test findnearest(fiber, 1.1+0.0im) == :a
		@test findnearest(fiber, 2.05+0.0im) == :b
		@test findnearest(fiber, 2.9+0.1im) == :c
	end
end