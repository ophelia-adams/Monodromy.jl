"""
The exponential map is branched over zero and has monodromy group ℤ. One of the function's interesting features is that its real part is constant on circles around zero; the action on fibers is quite literally unrolling a circle.
"""
function ExpCEC()
	e(z) = exp(z)
	de(z) = exp(z)
	e_branch = Set(0.0im)
	return ComplexEtaleCover(e,de,e_branch)
end

function interact_exponential()
	fibers = Dict(
		:zero => 1.0 + 0.0im,
		:one => 1.0 + 2π*im,
		:two => 1.0 + 2*2π*im,
		:mone => 1.0 - 2π*im,
		:mthree => 1.0 - 3*2π*im,
	)

	visdata = interact(
		ComplexMonodromy(ExpCEC(), fibers, exp(1)+0.0im),
		(-3,3,-30,30),(-4,4,-4,4)
	)
	display(visdata[:fig])

	return visdata
end