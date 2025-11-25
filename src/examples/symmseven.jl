"""
An unusual function with an A₅ symmetry.
Its monodromy group is still S₇, though!
"""
function symmetric_seven()
	S(x) = (-x^7 - 7*x^2)/(7*x^5 - 1)
	dS(x) = -14*(x^11 - 11*x^6 - x)/(49*x^10 - 14*x^5 + 1)

	# observe $S'(x)/x$ is $(y^2 - 11y - 1)/(49y^2 - 14y + 1) at $y=x^5$
	# so its branches have $\zeta_5$ symmetry, presumably from its A5 symmetry

	zeta = ((-1+0im)^(1/5))^2
	alpha = (-5/2*sqrt(5) + 11/2 + 0im)^(1/5)
	beta = (5/2*sqrt(5) + 11/2 + 0im)^(1/5)

	S_crit = Set{ComplexF64}([0.0im,
		alpha, zeta*alpha, zeta^2*alpha, zeta^3*alpha, zeta^4*alpha,
		beta, zeta*beta, zeta^2*beta, zeta^3*beta, zeta^4*beta
	])

	S_branch = Set{ComplexF64}([S(x) for x in S_crit])

	return ComplexEtaleCover(S,dS,S_branch)
end

function interact_symmetric_seven()
	fibers = Dict(
		:a => 1+0.0im,
		:b => -0.5 - 0.75im,
		:bb => -0.5 + 0.75im,
		:c => 0.43im,
		:cc => -0.43im,
		:d => 3+0.0im,
		:dd => -3+0.0im,
	)
	base = -4/3 + 0.0im

	fig, ax_lift, ax_base, ax_braid, bps, xpps, tpp = interact(
		symmetric_seven(),
		fibers, base,
		(-5,5,-5,5),(-2,2,-2,2);
		vertical=true)
	display(fig)
	return fig, ax_lift, ax_base, ax_braid, bps, xpps, tpp
end