"""
	interact(f::ComplexEtaleCover,
			 fibers::Dict{Symbol, ComplexF64},
			 t::ComplexF64,
			 limits_lift::NTuple{4, S},
			 limits_base::NTuple{4, T};
			 layout = :standard)

Create an interactive visualization of the monodromy of a branched cover.

# Arguments
- `f`: The étale cover to study
- `fibers`: Dictionary of lifts of `t`
- `t`: Base point
- `limits_lift`: (xmin, xmax, ymin, ymax)
- `limits_base`: (xmin, xmax, ymin, ymax)
- `layout`: Layout; only `:standard` is available for now.

# Returns
A tuple containing:
- `fig`: The Figure
- `ax_lift`: Axis showing the covering space (domain)
- `ax_base`: Axis showing the base space (codomain)
- `ax_braid`: 3D axis showing braiding
- `bps`: Dictionary of BraidPlots (one per fiber)
- `xpps`: Dictionary of PathPlots
- `tpp`: PathPlot of the base

# Interaction
- **Left click/drag** on base axis: Draw path
- **Right click** on base or lift axis: Reset path to just the current point.
- **Middle click** (or Option+MB1) on base axis: Animate lift
- **Shift+Middle click**: Re-lift without animation

Lifts are automatically calculated as you draw in the base.

# Example
```julia
f = Power(3)
fibers = Dict(:one => 1.0, :azeta => exp(2πim/3), :bzeta => exp(4πim/3))
visdata = interact(
	f, 1.0 + 0.0im, fibers,
	(-2, 2, -2, 2),
	(-2, 2, -2, 2);
	layout = standard
)
display(visdata[:fig])
```
"""
function interact(
	f::ComplexEtaleCover,
	fibers::Dict{Symbol,ComplexF64},
	t::ComplexF64,
	limits_lift::NTuple{4, S},
	limits_base::NTuple{4, T};
	layout=:standard
) where {S<:Number,T<:Number}

	fig, axes, buttons, toggles, textboxes, labels = _standard_ui()
	ax_lift, ax_base, ax_braid = axes[:lift], axes[:base], axes[:braid]

	setproperty!(ax_lift, :limits, limits_lift)
	setproperty!(ax_base, :limits, limits_base)
	setproperty!(ax_braid, :limits, (limits_lift...,0,1))

	bp = branchplot!(ax_base, f)

	tpp = pathplot!(ax_base, ComplexPath(t); name=:base)
	tpp.hovercolor[] = tpp.regcolor[]

	xpps = Dict{Symbol,PathPlot}()
	bps = Dict{Symbol,BraidPlot}()
	for name in keys(fibers)
		xpps[name] = liftpathplot!(ax_lift, f, fibers[name], tpp, name)
		bps[name] = braidpathplot!(ax_braid, xpps[name])
	end

	# cleanup, aligns braids
	reset_path!(tpp)
	reset_path!.(values(xpps))

	register_path_draw!(ax_base, tpp)
	register_path_close!(ax_base, tpp)
	register_repeat!(ax_base, tpp)
	register_path_smooth!(ax_base, xpps, tpp)

	on(buttons[:smooth].clicks) do _
		_smooth(xpps, tpp)
	end

	on(buttons[:close].clicks) do _
		_close(tpp)
	end

	on(buttons[:lift].clicks) do _
		repeat_draw!(tpp; animate=toggles[:lift].active[])
	end

	on(toggles[:smooth].active) do enable
		if enable
			activate_interaction!(ax_base, :path_smooth)
		else
			deactivate_interaction!(ax_base, :path_smooth)
		end
	end

	on(toggles[:close].active) do enable
		if enable
			activate_interaction!(ax_base, :path_close)
		else
			deactivate_interaction!(ax_base, :path_close)
		end
	end

	on(buttons[:permutation].clicks) do _
		perm = Dict{Symbol,Symbol}()
		for name in keys(fibers)
			x = fibers[name]
			y = head(xpps[name].zpath[])
			perm[name] = findnearest(fibers,y)
		end
		setproperty!(labels[:permutation], :text,
			cyclestring(Permutation(perm))
		)
	end

	on(buttons[:clear].clicks) do _
		reset_path!(tpp)
		reset_path!.(values(xpps))
	end

	return (fig=fig, ax_lift=ax_lift, ax_base=ax_base, ax_braid=ax_braid, braid_pathplots=bps, lift_pathplots=xpps, base_pathplot=tpp)
end

interact(f::ComplexEtaleCover, x::ComplexF64, ll, lb; layout=:standard) = interact(f, Dict(:fiber => x), f(x), ll, lb; layout=layout)


"""
	liftpathplot!(ax, f, z, tpp, name)

Makes a reactive lift of a path in the base. Requiring a name allows it to be deactivated or deregistered through Makie's interface.
"""
function liftpathplot!(ax::Axis, f::ComplexEtaleCover, z::ComplexF64, tpp::PathPlot, name::Symbol)
	xpp = pathplot!(ax, z; name=name, linear=true)

	register_path_reset!(ax, xpp)

	on(tpp.zpath) do zp
		x₁ = monodromy_step(f, xpp.zpath[][end], zp[end-1], zp[end])
		xpp.zpath[] = push!(xpp.zpath[],x₁)
	end

	return xpp
end

"""
	braidpathplot!(ax, xpp)

Assigns the lifted PathPlot `xpp` to a BraidPlot and reactively updates it.
"""
function braidpathplot!(ax, xpp)
	bp = braidplot!(ax, xpp.zpath[][1], name=xpp.name[], cycle=[:color])
	on(xpp.zpath) do zp
		bp.zpath[] = zp
	end
	return bp
end


"""
	CleanAxis(GP, args; kwargs...)

Returns an 2D axis with two interactions removed:

- rectangle zoom: annoying
- limitreset: issue on macs and conflicts with other interactions.
"""
function CleanAxis(GP::Union{GridPosition,GridSubposition}, args...; kwargs...)::Axis
	axis = Axis(GP, args...; kwargs...)
	deregister_interaction!(axis,:rectanglezoom)
	deregister_interaction!(axis,:limitreset)
	return axis
end

"""
Captures left clicks and drags, handing them to the PathPlot to be drawn.
"""
function register_path_draw!(ax::Axis, pp::PathPlot)
	register_path_reset!(ax, pp)
	register_interaction!(ax,:path_draw) do event::MouseEvent, axis
		simulated_mc = ispressed(ax, Keyboard.left_alt)
		if (event.type === MouseEventTypes.leftdrag || event.type === MouseEventTypes.leftclick) && !simulated_mc
			mp = mouseposition(axis)
			pp.zpath[] = push!(pp.zpath[], mp[1] + mp[2]*im)
		end
	end
end

"""
On right click, reset the path plot to the one-point path at its currently emphasized point.
"""
function register_path_reset!(ax::Axis, pp::PathPlot)
	register_interaction!(ax, Symbol(:path_clear,pp.name[])) do event::MouseEvent, axis
		if event.type === MouseEventTypes.rightclick
			reset_path!(pp)
		end
	end
end

"""
	register_path_close!(ax::Axis, pp::PathPlot)

On left drag release, closes the path by a `piecewiselinear` with `dz=0.1`.
"""
function register_path_close!(ax::Axis, pp::PathPlot)
	register_interaction!(ax, :path_close) do event::MouseEvent, axis
		if event.type === MouseEventTypes.leftdragstop
			_close(pp)
		end
	end
end

"""
	register_path_smooth!(ax::Axis, xpps::Dict{Symbol,PathPlot}, tpp::PathPlot)

On left drag release, smooths the path and recalculates the lift
"""
function register_path_smooth!(ax::Axis, xpps::Dict{Symbol,PathPlot}, tpp::PathPlot)
	register_interaction!(ax, :path_smooth) do event::MouseEvent, axis
		if event.type === MouseEventTypes.leftdragstop
			_smooth(xpps, tpp)
		end
	end
	deactivate_interaction!(ax, :path_smooth)
end

"""
On middle click, retrace the path. If shift is held, it does this instantly, but otherwise it animates it.
"""
function register_repeat!(ax::Axis, tpp::PathPlot)
	register_interaction!(ax, Symbol(:path_animate, tpp.name[])) do event::MouseEvent, axis
		actual_mc = event.type == MouseEventTypes.middleclick
		simulated_mc = event.type == MouseEventTypes.leftclick && ispressed(ax, Keyboard.left_alt)
		shift_pressed = ispressed(ax,Keyboard.left_shift)
		if actual_mc || simulated_mc
			if shift_pressed
				repeat_draw!(tpp)
			else
				repeat_draw!(tpp; animate=true)
			end
		end
	end
end

"""
Animation speed is O(log(n)) where N is the number of points. This seems to produce visually clear results for typical path lengths.
"""
function repeat_draw!(tpp::PathPlot; animate=false)
	L = copy(tpp.zpath[])
	tpp.zpath.value[] = ComplexPath(ComplexF64[L[1]])
	N = length(L)
	framerate = 15*log(N)
	for i in 2:N
		if animate
			@async begin
				sleep(i/framerate)
				tpp.zpath[] = push!(tpp.zpath[],L[i])
			end
		else
			tpp.zpath[] = push!(tpp.zpath[],L[i])
		end
	end
end

"""
	reset_path!(pp::PathPlot)

Clears a `PathPlot`, leaving only its currently emphasized point.
"""
function reset_path!(pp::PathPlot)
	# a notified update, for the redraw, but it requires two points in case someone is watching
	pp.zpath[] = ComplexPath([pp.zpath[][1], pp.zpath[][1]])
	# silent change to one point (ready for input)
	pp.zpath.value[] = ComplexPath([pp.zpath[][1]])
end

function _close(pp::PathPlot)
	zp = pp.zpath[]
	closing = piecewiselinear(zp[end],zp[1],0.1)
	for c in closing
		pp.zpath[] = push!(zp, c)
	end
end

function _smooth(xpps::Dict{Symbol,PathPlot}, tpp::PathPlot)
	n = length(tpp.zpath[])
	szp = smooth(tpp.zpath[], :chaikin)[2:end]
	for pp in values(xpps)
		if length(pp.zpath[]) > n - 1
			pp.zpath[] = pp.zpath[][1:(end - n + 1)]
		else
			reset_path!(pp)
		end
	end
	tpp.zpath.value[] = ComplexPath([tpp.zpath[][1]])
	for s in szp
		tpp.zpath[] = push!(tpp.zpath[],s)
	end
end