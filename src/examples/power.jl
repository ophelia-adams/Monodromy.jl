"""
The powering map z ↦ zⁿ. It is branched at 0 and ∞. Its monodromy action corresponds to rotating the roots of unity.
# Example
```julia
f = Power(3)
fig, ax_lift, ax_base, ax_braid, bps, xpps, tpp = interact(
	f, 1.0 + 0.0im,
	(-2, 2, -2, 2),
	(-2, 2, -2, 2)
)
```
"""
function Power(n::Int64)
	if n < 1
		@error "Degree must be positive."
	end
	pwr(x) = x^n
	dpwr(x) = n*x^(n-1)
	pwr_branch = Set{ComplexF64}(0)
	return ComplexEtaleCover(pwr,dpwr,pwr_branch)
end

"""
Play around with the powering map!
"""
function interact_power(; degree=3, x=1.0+0.0im)
	f = Power(degree)
	visdata = interact(
		ComplexMonodromy(f, x, 0.0im),
		(-2, 2, -2, 2), (-2, 2, -2, 2)
	)

	display(visdata[:fig])

	return visdata
end