@testset "Permutation" begin
	@testset "Construction and validation" begin
		# a plain cycle
		perm_dict = Dict(:a => :b, :b => :c, :c => :a)
		p = Permutation(perm_dict)
		@test !isempty(p)

		# handles not bijective
		not_bij = Dict(:a => :b, :b => :b)
		@test_throws Any Permutation(not_bij)
	end

	@testset "Cycles" begin
		# three-cycle
		p1 = Permutation(Dict(:a => :b, :b => :c, :c => :a))
		c1 = cycleof(p1, :a)
		@test Set(c1) == Set([:a, :b, :c])
		@test c1[1] == :a

		cs = cycles(p1)
		@test length(cs) == 1
		@test length(cs[1]) == 3

		# 2,2-cycle
		p2 = Permutation(Dict(:a => :b, :b => :a, :c => :d, :d => :c))
		cs2 = cycles(p2)
		@test length(cs2) == 2
		@test all(length(c) == 2 for c in cs2)

		# identity
		p3 = Permutation(Dict(:a => :a, :b => :b))
		cs3 = cycles(p3)
		@test length(cs3) == 2
		@test all(length(c) == 1 for c in cs3)
	end

	@testset "Inverse" begin
		p = Permutation(Dict(:a => :b, :b => :c, :c => :a))
		pinv = inverse(p)
		@test pinv[:b] == :a
		@test pinv[:c] == :b
		@test pinv[:a] == :c
	end

	@testset "Application" begin
		p = Permutation(Dict(:a => :b, :b => :c, :c => :a))
		@test :a^p == :b
		@test :b^p == :c
		@test :c^p == :a
	end

	@testset "Composition" begin
		p = Permutation(Dict(:a => :b, :b => :c, :c => :a))
		q = Permutation(Dict(:a => :c, :b => :a, :c => :b))
		pq = p * q

		# associativity etc
		@test :a^pq == (:a^p)^q
		@test :b^pq == (:b^p)^q
		@test :c^pq == (:c^p)^q
	end

	@testset "Conjugation" begin
		letters = [:a, :b, :c]
		p = Permutation(Dict(:a => :b, :b => :a, :c => :c))
		q = Permutation(Dict(:a => :b, :b => :c, :c => :a))
		pconj = p^q
		apconj = inverse(q)*p*q

		@test foldl(&, [l^pconj == l^apconj for l in letters])
	end
end