@testset "Model Tests" begin
	@testset "Path and point extensions" begin
		# Rabbits are my favorite
		rabbit = rabbit_cover()
		RRR = rabbit(rabbit(rabbit))
		fibers = Dict(
			:a => -1.18 +  0.6im,
			:b => -0.92 + 0.67im,
			:c => -0.28 + 0.48im,
			:d => -0.04 + 0.89im,
			:aa => 1.18 -  0.6im,
			:bb => 0.92 - 0.67im,
			:cc => 0.28 - 0.48im,
			:dd => 0.04 - 0.89im,
		)

		CMone = ComplexMonodromy(RRR, fibers, -0.28 + 0.48im)
		CMtwo =ComplexMonodromy(RRR, fibers, -0.28 + 0.48im)
		P = ComplexPath([-0.28 + 0.6im, -0.28 + 0.7im])

		extendpath!(CMone, P)
		extendpath!(CMtwo, -0.28 + 0.6im)
		extendpath!(CMtwo, -0.28 + 0.7im)

		for k in CMone.names
			@test abs(CMone.lifted_paths[k][end] - CMtwo.lifted_paths[k][end]) < 1e-10
			@test length(CMone.lifted_paths[k]) == 3
			@test length(CMtwo.lifted_paths[k]) == 3
		end
		@test length(CMtwo.base_path) == 3
		@test length(CMone.base_path) == 3
	end
end