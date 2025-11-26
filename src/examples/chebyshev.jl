"""
The Chebyshev maps are defined by
	Tₙ(x + 1/x) = xⁿ + 1/xⁿ
This is just the fourth, I am sure there's a nice algorithm to produce the others.
"""
function T4()
	T4(x) = (x^2-2)^2-2
	dT4(x) = 4*x*(x^2-2)
	T4_branch = Set{ComplexF64}([T4(0),T4(sqrt(2)),T4(-sqrt(2))])
	return ComplexEtaleCover(T4,dT4,T4_branch)
end

function interact_chebyshev()
	fibers = Dict(
		:a => 1.0 + 0.0im,
		:b => -1.0 + 0.0im,
		:c => sqrt(3) + 0.0im,
		:d => -sqrt(3) + 0.0im,
	)

	visdata = interact(
		T4(), fibers, -1+0.0im,
		(-3,3,-1,1),(-4,4,-3,3);
		vertical = true
	)
	display(visdata[:fig])

	return visdata
end