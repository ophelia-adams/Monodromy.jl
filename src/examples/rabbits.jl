"""
The polynomial associated to the rabbit fractal.
It has a fixed point around -0.3 + 0.4im that is pretty much in the center of the branch locus, and hence makes for good lifts.
"""
function rabbit_cover()
	r(z) = z^2 - 0.1225611668766536 + 0.7448617666197442im
	dr(z) = 2z
	r_branch = Set(r(0))
	return ComplexEtaleCover(r,dr,r_branch)
end

function interact_rabbits()
	rabbit = rabbit_cover()
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
	fp = -0.28 + 0.48im
	visdata = interact(
		rabbit(rabbit(rabbit)),
		fibers, fp,
		(-1.5,1.5,-1.5,1.5),(-1.0,0.5,-0.5,1.0)
	)
	display(visdata[:fig])

	return visdata
end