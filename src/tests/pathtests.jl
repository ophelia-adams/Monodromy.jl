
@testset "ComplexPath" begin
	@testset "Construction" begin
		# plain old
		p1 = ComplexPath([1.0+0.0im, 2.0+1.0im, 3.0+2.0im])
		@test length(p1) == 3
		@test head(p1) == 3.0+2.0im
		@test tail(p1) == 1.0+0.0im

		# real number conversion
		p2 = ComplexPath([1, 2, 3])
		@test eltype(p2.elements) == ComplexF64

		# single point path
		p3 = ComplexPath(1.5+2.5im)
		@test length(p3) == 1
		@test head(p3) == tail(p3)
	end

	@testset "Concatenation" begin
		p1 = ComplexPath([1.0+0.0im, 2.0+0.0im])
		p2 = ComplexPath([2.0+0.0im, 3.0+0.0im])
		p3 = p1 * p2
		@test length(p3) == 4
		@test tail(p3) == 1.0+0.0im
		@test head(p3) == 3.0+0.0im
	end

	@testset "Indexing and iteration" begin
		p = ComplexPath([1.0+0.0im, 2.0+1.0im, 3.0+2.0im])
		@test p[1] == 1.0+0.0im
		@test p[2] == 2.0+1.0im
		@test p[end] == 3.0+2.0im
		@test p[1:2].elements == [1.0+0.0im, 2.0+1.0im]

		# comprehension
		collected = [z for z in p]
		@test collected == [1.0+0.0im, 2.0+1.0im, 3.0+2.0im]

		# mutating by index
		p = ComplexPath([1.0+0.0im, 2.0+0.0im, 3.0+0.0im])
		p[2] = 5.0+5.0im
		@test p[2] == 5.0+5.0im

		# pushing a point
		push!(p, 4.0+0.0im)
		@test length(p) == 4
		@test head(p) == 4.0+0.0im

		# popping a point
		pop!(p)
		@test length(p) == 3
	end

	@testset "Reversal" begin
		p = ComplexPath([1.0+0.0im, 2.0+0.0im, 3.0+0.0im])
		pr = reverse(p)
		@test tail(pr) == 3.0+0.0im
		@test head(pr) == 1.0+0.0im
		@test length(pr) == 3
	end

	@testset "Subdivision" begin
		p = ComplexPath([0.0+0.0im, 1.0+0.0im])
		ps = subdivide(p, 2)
		@test length(ps) == 3
		@test tail(ps) == 0.0+0.0im
		@test head(ps) == 1.0+0.0im
		@test ps[2] == 0.5+0.0im

		# error on invalid subdivision
		@test_throws Any subdivide(p, 0)
	end

	@testset "Loop construction" begin
		c = 0.0+0.0im
		z = 1.0+0.0im
		n = 4
		lp = loop(c, z, n)

		@test length(lp) == n + 1
		@test tail(lp) ≈ z
		@test head(lp) ≈ z
		@test all(abs(p - c) ≈ abs(z - c) for p in lp)
	end

	@testset "Lollipop construction" begin
		c = 0.0+0.0im
		z = 2.0+0.0im
		r = 0.5
		dz = 0.1

		lp = lollipop(c, z, r, dz)
		@test tail(lp) ≈ z
		@test head(lp) ≈ z
	end

	@testset "Piecewise linear construction" begin
		vertices = [0.0+0.0im, 1.0+0.0im, 1.0+1.0im]
		dz = 0.1
		p = piecewiselinear(vertices, dz)

		@test tail(p) == vertices[1]
		@test head(p) == vertices[end]
		@test length(p) > length(vertices)
	end
end