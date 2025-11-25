"""
	PathPlot

Plot of a path in ℂ with the head marked.
Default attributes are from OAPlain(:blue).

# Attributes
- `zpath`: Observable vector of complex numbers representing the path
- `name`: Symbol identifying this path (for interaction registration)
- `emphcolor`: Color for the emphasized endpoint
- `emphmarkersize`: Size of the endpoint marker
- `emphstrokewidth`: Stroke width for endpoint
- `emphlabel`: Function to format tooltip labels
- `regcolor`: Color for regular path points
- `regmarkersize`: Size of regular markers
"""
@recipe PathPlot begin
	zpath = ComplexPath([0.0im])
	name = :zero
	emphcolor = @inherit emphcolor _COLORS[:blue][:highlight]
	emphmarkersize = @inherit emphmarkersize 12
	emphstrokewidth = @inherit emphstrokewidth 1
	emphlabel = @inherit emphlabel (self, i, pos) -> string(:zero, ": ", round(pos[1]+pos[2]*im; digits=2))
	hovercolor = @inherit emphcolor _COLORS[:blue][:highlight]
	regcolor = @inherit regcolor _COLORS[:blue][:dark]
	regmarkersize = @inherit regmarkersize 8
	linear = @inherit linear false
	inspector_hover = (inspector, self, idx, child) -> begin
		subplots = plots(self)
		subplots[1].color[] = self.hovercolor[]
		Makie.show_data(inspector, subplots[2], 1)
		return true
	end
	inspector_clear = (inspector, self) -> begin
		subplots = plots(self)
		subplots[1].color[] = self.regcolor[]
		return true
	end
end

"""
	BraidPlot

3D visualization showing how lifts of paths braid.
Shows the path in 3D (z, time) with a shadow projection onto t=0.

Attributes are similar to PathPlot.
"""
@recipe BraidPlot begin
	zpath = ComplexPath([0.0im])
	name = :zero
	emphcolor = @inherit emphcolor _COLORS[:blue][:highlight]
	emphmarkersize = @inherit emphmarkersize 12
	emphstrokewidth = @inherit emphstrokewidth 1
	emphlabel = @inherit emphlabel (self, i, pos) -> string(round(pos[1]+pos[2]*im; digits=2))
	hovercolor = @inherit emphcolor _COLORS[:blue][:highlight]
	regcolor = @inherit regcolor _COLORS[:blue][:dark]
	regmarkersize = @inherit regmarkersize 8
	inspector_hover = (inspector, self, idx, child) -> begin
		subplots = plots(self)
		subplots[1].color[] = self.hovercolor[]
		subplots[4].color[] = self.hovercolor[]
		Makie.show_data(inspector, subplots[2], 1)
		Makie.show_data(inspector, subplots[3], 1)
		return true
	end
	inspector_clear = (inspector, self) -> begin
		subplots = plots(self)
		subplots[1].color[] = self.regcolor[]
		subplots[4].color[] = self.regcolor[]
		return true
	end
end

"""
	BranchPlot

For marking the branch locus in the base space. Primarily a convenience type to hook into the theming system.
"""
@recipe BranchPlot begin
	branches = Set(0.0im)
	color = @inherit color _COLORS[:yellow][:highlight]
	marker = @inherit marker :xcross
	markersize = @inherit markersize 12
	strokewidth = @inherit strokewidth 1
	inspector_label = @inherit inspector_label (self, i, pos) -> string(round(pos[1]+pos[2]*im; digits=2))
end

"""
Draws a PathPlot. Modifying `pp.zpath` allows it to be reactively updated.
"""
function Makie.plot!(pp::PathPlot)
	pp.zpath = ComplexPath(pp[1][])

	if pp.linear[]
		s = lines!(pp,
			pp.zpath;
			color = pp.regcolor,
			linewidth = @lift($(pp.regmarkersize)/2),
			linecap = :round
		)
		translate!(s,0,0,-0.001) # so that the emphasized point is always on top
	else
		s = scatter!(pp,
			pp.zpath;
			color = pp.regcolor,
			markersize = pp.regmarkersize
		)
		translate!(s,0,0,-0.001) # so that the emphasized point is always on top
	end

	scatter!(pp,
		@lift($(pp.zpath)[end]);
		color = pp.emphcolor,
		markersize = pp.emphmarkersize,
		strokewidth = pp.emphstrokewidth,
		inspector_label = (self, i, pos) -> string(pp.name[], ": ", round(pos[1]+pos[2]*im; digits=2)),
	)
end

"""
Plots the braids, emphasizes start and end points, and a shadow on `t=0`.
Due to a bug (see github) the palettes have to be set here for cycling.
"""
function Makie.plot!(pp::BraidPlot)
	pp.zpath = ComplexPath(pp[1][])

	# actual braids
	lines!(pp,
		@lift(normalize3d($(pp.zpath)));
		color = pp.regcolor,
	)

	scatter!(pp,
		@lift($(pp.zpath)[end]);
		markersize = pp.emphmarkersize,
		strokewidth = pp.emphstrokewidth,
		inspector_label = (self, i, pos) -> string(pp.name[], ": ", round(pos[1]+pos[2]*im; digits=2)),
		color = pp.emphcolor,
	)

	scatter!(pp,
		@lift((reim($(pp.zpath)[end])...,1.0));
		markersize = pp.emphmarkersize,
		strokewidth = pp.emphstrokewidth,
		inspector_label = (self, i, pos) -> string(pp.name[], ": ", round(pos[1]+pos[2]*im; digits=2)),
		overdraw = true,
		color = pp.emphcolor,
	)

	lines!(pp,
		pp.zpath;
		color = pp.regcolor,
	)
end

function Makie.plot!(bp::BranchPlot)
	scatter!(bp, bp[1][].branch_locus;
		color = bp.color[],
		marker = bp.marker[],
		markersize= bp.markersize[],
		strokewidth = bp.strokewidth,
		inspector_label = bp.inspector_label
	)
end

"""
	normalize3d(P)

Helper function for `BraidPlot` to stretch out a path along a time axis.
"""
function normalize3d(zp::ComplexPath)
	L = length(zp)
	nzp = Vector{Point{3, Float64}}(undef, L)
	for k in 1:L
		x, y = reim(zp[k])
		nzp[k] = Point3(x,y,(k-1)/(L-1))
	end
	return nzp
end

# various conversions to make plotting complex numbers straightforward.
Makie.convert_arguments(PT::PointBased, Z::Set{T}) where T <: Complex = ([Point2f(reim(z)) for z in Z],)
Makie.convert_arguments(PT::PointBased, Z::Vector{T}) where T <: Complex = ([Point2f(reim(z)) for z in Z],)
Makie.convert_arguments(PT::PointBased, Z::ComplexPath) = ([Point2f(reim(z)) for z in Z],)
Makie.convert_arguments(PT::PointBased, z::T) where T <: Complex = (Point2f(reim(z)),)
Makie.convert_text_string!(nt::NamedTuple, z::ComplexF64, rest...) = Makie.convert_text_string!(nt, string(round(z; digits=2)), rest...)
Makie.convert_text_string!(nt::NamedTuple, pp::PathPlot, rest...) = Makie.convert_text_string!(nt, pp.zpath[][end], rest...)

# Makie has a whitespace test somewhere that doesn't first convert non-strings to strings.
Makie.iswhitespace(x::ComplexF64) = false