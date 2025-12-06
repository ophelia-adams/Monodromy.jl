"""
	interact(
		cm::ComplexMonodromy,
		limits_lift::NTuple{4, S},
		limits_base::NTuple{4, T};
		layout = :standard
	)

Create an interactive visualization of the monodromy of a branched cover.

# Arguments
- `cm`: The complex monodromy to study, largely comprising the étale cover `cm.cover` and the fibers `cm.cibers`.
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
- **Right click** on base axis: Reset path to the original.
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
	cm::ComplexMonodromy,
	limits_lift::NTuple{4, S},
	limits_base::NTuple{4, T};
	layout=:standard
) where {S<:Number,T<:Number}
	fig, axes, buttons, toggles, textboxes, labels = _standard_ui()
	ax_lift, ax_base, ax_braid = axes[:lift], axes[:base], axes[:braid]

	history = Dict(:undo => Vector{ComplexMonodromy}(), :redo => Vector{ComplexMonodromy}())
	record_undo(cm, history)

	setproperty!(ax_lift, :limits, limits_lift)
	setproperty!(ax_base, :limits, limits_base)
	setproperty!(ax_braid, :limits, (limits_lift...,0,1))

	bp = branchplot!(ax_base, cm.cover)

	tpp = pathplot!(ax_base, cm.base_path; name=:base)
	tpp.hovercolor[] = tpp.regcolor[]


	bps = Dict{Symbol,BraidPlot}()
	xpps = Dict{Symbol,PathPlot}()
	for name in keys(cm.fibers)
		xpps[name] = pathplot!(ax_lift, cm.lifted_paths[name]; name=name)
		bps[name] = braidpathplot!(ax_braid, xpps[name])
	end

	register_path_draw!(ax_base, cm, xpps, tpp, history)
	register_path_reset!(ax_base, cm, xpps, tpp, history)
	register_path_smooth!(ax_base, cm, xpps, tpp, history)
	register_path_close!(ax_base, cm, xpps, tpp, history)
	register_repeat!(ax_base, cm, xpps, tpp, history)
	register_undo_draw!(ax_base, cm, history)


	on(buttons[:smooth].clicks) do _
		smooth_base_path!(cm)
		update_base(cm, tpp)
		update_lifts(cm, xpps)
		record_undo(cm, history)
	end

	on(buttons[:close].clicks) do _
		close_base_path!(cm)
		update_base(cm, tpp)
		update_lifts(cm, xpps)
		record_undo(cm, history)
	end

	on(buttons[:lift].clicks) do _
		repeat_draw!(ax_base, cm, xpps, tpp; animate=toggles[:lift].active[])
		record_undo(cm, history)
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
		setproperty!(labels[:permutation], :text, cyclestring(getpermutation(cm)))
	end

	on(buttons[:undo].clicks) do _
		if length(history[:undo]) >= 2
			push!(history[:redo], pop!(history[:undo]))
			new = history[:undo][end]
			cm.base_path = copy(new.base_path)
			cm.lifted_paths = copy(new.lifted_paths)
			update_base(cm, tpp)
			update_lifts(cm, xpps)
		end
	end

	on(buttons[:redo].clicks) do _
		if length(history[:redo]) > 0
			cm = pop!(history[:redo])
			push!(history[:undo], deepcopy(cm))
			update_base(cm, tpp)
			update_lifts(cm, xpps)
		end
	end

	on(buttons[:clear].clicks) do _
		reset!(cm)
		update_base(cm, tpp)
		update_lifts(cm, xpps)
		record_undo(cm, history)
	end

	return (fig=fig, ax_lift=ax_lift, ax_base=ax_base, ax_braid=ax_braid, braid_pathplots=bps, lift_pathplots=xpps, base_pathplot=tpp)
end

function interact(f::ComplexEtaleCover, fibers::Dict{Symbol, ComplexF64}, ll, lb; layout=:standard)
	cm = ComplexMonodromy(f, fibers, f(first(fibers)))
	interact(cm, ll, lb; layout=layout)
end


function update_base(cm::ComplexMonodromy, tpp::PathPlot)
	tpp.zpath[] = cm.base_path
end

function update_lifts(cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot})
	for name in keys(xpps)
		xpps[name].zpath[] = cm.lifted_paths[name]
	end
end

"""
Captures drawing paths (left click & drag) on the base plot.
"""
function register_path_draw!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot, history)
	register_interaction!(ax,:path_draw) do event::MouseEvent, axis
		simulated_mc = ispressed(ax, Keyboard.left_alt)
		if (event.type === MouseEventTypes.leftdrag || event.type === MouseEventTypes.leftclick) && !simulated_mc
			mp = mouseposition(axis)
			z = mp[1] + mp[2]*im
			extendpath!(cm, z)
			update_lifts(cm, xpps)
			update_base(cm, tpp)
		end
	end
end

"""
On right click, reset the path plot to the one-point path at its currently emphasized point.
"""
function register_path_reset!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot, history)
	register_interaction!(ax, Symbol(:path_clear, tpp.name[])) do event::MouseEvent, axis
		if event.type === MouseEventTypes.rightclick
			reset!(cm)
			update_base(cm, tpp)
			update_lifts(cm, xpps)
			record_undo(cm, history)
		end
	end
end

"""
On middle click, retrace the path. If shift is held, it does this instantly, but otherwise it animates it.
"""
function register_repeat!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot, history)
	register_interaction!(ax, Symbol(:path_animate, tpp.name[])) do event::MouseEvent, axis
		actual_mc = event.type == MouseEventTypes.middleclick
		simulated_mc = event.type == MouseEventTypes.leftclick && ispressed(ax, Keyboard.left_alt)
		shift_pressed = ispressed(ax,Keyboard.left_shift)
		if actual_mc || simulated_mc
			if shift_pressed
				repeat_draw!(ax, cm, xpps, tpp)
			else
				repeat_draw!(ax, cm, xpps, tpp; animate=true)
			end
			record_undo(cm, history)
		end
	end
end

"""
Animation speed is O(log(n)) where N is the number of points. This seems to produce visually clear results for typical path lengths.
"""
function repeat_draw!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot; animate=false)
	N = length(cm.base_path)
	extendpath!(cm, cm.base_path[2:end])
	framerate = 15*log(N)
	for i in 1:(N-1)
		if animate
			@async begin
				sleep(i/framerate)
				tpp.zpath[] = cm.base_path[1:i+N]
				for name in keys(xpps)
					xpps[name].zpath[] = cm.lifted_paths[name][1:i+N]
				end
			end
		else
			update_base(cm, tpp)
			update_lifts(cm, xpps)
		end
	end
end

"""
	register_path_close!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot)

On left drag release, closes the base path.
"""
function register_path_close!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot, history)
	register_interaction!(ax, :path_close) do event::MouseEvent, axis
		if event.type === MouseEventTypes.leftdragstop
			close_base_path!(cm)
			update_base(cm, tpp)
			update_lifts(cm, xpps)
		end
	end
end

"""
	register_path_smooth!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot)

On left drag release, smooths the path and recalculates the lift.
"""
function register_path_smooth!(ax::Axis, cm::ComplexMonodromy, xpps::Dict{Symbol, PathPlot}, tpp::PathPlot, history)
	register_interaction!(ax, :path_smooth) do event::MouseEvent, axis
		if event.type === MouseEventTypes.leftdragstop
			smooth_base_path!(cm)
			update_base(cm, tpp)
			update_lifts(cm, xpps)
		end
	end
	deactivate_interaction!(ax, :path_smooth)
end

function register_undo_draw!(ax::Axis, cm::ComplexMonodromy, history)
	register_interaction!(ax,:path_undo_watch) do event::MouseEvent, axis
		if event.type === MouseEventTypes.leftdragstop
			record_undo(cm, history)
		end
	end
end

function record_undo(cm::ComplexMonodromy, history)
	push!(history[:undo], deepcopy(cm))
	# clear the redos after taking any action
	history[:redo] = Vector{ComplexMonodromy}()
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