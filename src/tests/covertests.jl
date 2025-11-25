@testset "ComplexCover" begin
	@testset "Squaring" begin
		f = ComplexCover(z -> z^2)
		@test f(2.0) == 4.0
		@test f(1.0+1.0im) ≈ 0.0+2.0im
	end

	@testset "Composition" begin
		f = ComplexCover(z -> z^2)
		g = ComplexCover(z -> z + 1)
		fg = f(g)

		# Should compute f(g(z)) = (z+1)^2
		@test fg(0.0) == 1.0
		@test fg(1.0) == 4.0
		@test fg(2.0) == 9.0
	end
end

@testset "ComplexEtaleCover" begin
	@testset "Construction" begin
		f(z) = z^2
		df(z) = 2z
		branches = Set([0.0+0.0im])

		cover = ComplexEtaleCover(f, df, branches)
		@test cover(2.0) == 4.0
		@test diff(cover)(3.0) == 6.0
		@test branch_locus(cover) == branches
	end

	@testset "Error on empty branch locus" begin
		f(z) = z^2
		df(z) = 2z
		empty_branches = Set{ComplexF64}()

		@test_throws Any ComplexEtaleCover(f, df, empty_branches)
	end

	@testset "Composition of étale covers" begin
		# f(z) = z^2, branched at 0
		f(z) = z^2
		df(z) = 2z
		f_branch = Set([0.0+0.0im])
		cover_f = ComplexEtaleCover(f, df, f_branch)

		# g(z) = z^2, branched at 0
		g(z) = z^2
		dg(z) = 2z
		g_branch = Set([0.0+0.0im])
		cover_g = ComplexEtaleCover(g, dg, g_branch)

		# Composition should be z^4
		fg = cover_f(cover_g)
		@test fg(2.0) ≈ 16.0

		# Branch locus should be {0, f(0)} = {0}
		@test 0.0+0.0im in branch_locus(fg)

		# todo: tests for dfg
	end

	@testset "Power maps" begin
		for n in 2:5
			p = Power(n)
			@test p(2.0) ≈ 2.0^n
			@test diff(p)(2.0) ≈ n * 2.0^(n-1)
			@test 0.0+0.0im in branch_locus(p)
		end
	end
end