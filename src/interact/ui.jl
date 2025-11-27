mutable struct HideableColumn{T}
	parent::Figure
	column::Int
	size::Union{Aspect, Auto, Fixed, Relative}
	visible::Bool
	contents::Vector{T}
	button::Button
end

function hide!(hc::HideableColumn)
	for b in hc.contents
		Makie.hide!(b)
	end
	colsize!(hc.parent.layout, hc.column, 24)
	setproperty!(hc.button, :label, "▶")
end

function unhide!(hc::HideableColumn)
	for b in hc.contents
		Makie.unhide!(b)
	end
	colsize!(hc.parent.layout, hc.column, hc.size)
	setproperty!(hc.button, :label, "◀")
end


"""
	_standard_ui()

Assembles the standard UI for the tool, with a collapsable side panel. The panel layout is a 12 column grid (forget where I saw this, I think it's a common web dev thing).
"""
function _standard_ui()
	em = 16
	fig = Figure(;
		figure_padding = (0,20,20,20),
		size = (1300,1000)
	)
	DataInspector(fig)

	axis_lift = CleanAxis(fig[1,2][1,1], title="lift", aspect=1)
	axis_base = CleanAxis(fig[1,2][2,1], title="base", aspect=1)
	axis_braid = Axis3(fig[1,3], title="braid", zlabel="", xlabel="Re", ylabel="Im")

	delete!(Box(fig[1,1][1,1:12]))
	delete!(Box(fig[1,1][13,1:12]))

	controlpanel = Box(fig[1,1], color = _COLORS[:blue][:light], strokecolor = _COLORS[:blue][:light], alignmode=Outside(-2,0,-54,-54))
	btn_hide = Button(fig[1,1],
		label="◀",
		halign=:right,
		buttoncolor = _COLORS[:blue][:light],
		buttoncolor_hover = _COLORS[:blue][:light],
		buttoncolor_active = _COLORS[:blue][:light],
		strokewidth=0,
	)

	# 12 column layout
	panel_grid = contents(fig[1,1])[1]

	btn_smooth = Button(panel_grid[2,2:3], label="Smooth", width=5em, buttoncolor=_COLORS[:red][:dark])
	btn_close = Button(panel_grid[2,6:7], label="Close", width=5em)
	btn_lift = Button(panel_grid[2,10:11], label="Lift", width=5em)
	tog_smooth = Toggle(panel_grid[3,2:3], framecolor_active=_COLORS[:red][:dark])
	tog_close = Toggle(panel_grid[3,6:7])
	tog_lift = Toggle(panel_grid[3,10:11])
	lbl_togs = Label(panel_grid[4,1:12], "Toggle automatic smoothing/closing\nand animated lifting.")

	#Box(panel_grid[4,1:3])

	btn_permutation = Button(panel_grid[6,1:12], label="Get Permutation")
	lbl_permutation = Label(panel_grid[7,2:11], "")

	#Box(panel_grid[7,1:3])

	btn_undo = Button(panel_grid[9,2:3], label="↺ undo", buttoncolor=_COLORS[:red][:dark])
	btn_redo = Button(panel_grid[9,6:7], label="↻ redo", buttoncolor=_COLORS[:red][:dark])
	btn_clear = Button(panel_grid[9,10:11], label="✕ clear")

	#Box(panel_grid[9,1:3])

	txt_save = Textbox(panel_grid[11,1:12], placeholder="location", width = Relative(0.9))
	btn_save = Button(panel_grid[12,1:6], label="✎ save", buttoncolor=_COLORS[:red][:dark])
	btn_load = Button(panel_grid[12,7:12], label="⎘ load", buttoncolor=_COLORS[:red][:dark])



	hc = HideableColumn(fig, 1, Auto(true,1), true,
		[
			btn_smooth,
			btn_close,
			btn_lift,
			tog_smooth,
			tog_close,
			tog_lift,
			lbl_togs,
			btn_permutation,
			lbl_permutation,
			btn_undo,
			btn_redo,
			btn_clear,
			txt_save,
			btn_save,
			btn_load,
		],
		btn_hide
	)

	on(btn_hide.clicks) do n
		hc.visible ? hide!(hc) : unhide!(hc)
		hc.visible = !(hc.visible)
	end

	rowsize!(panel_grid, 2, em)
	rowsize!(panel_grid, 3, 2em)
	rowsize!(panel_grid, 4, 0)
	rowsize!(panel_grid, 6, em)
	rowsize!(panel_grid, 7, 4em)
	rowsize!(panel_grid, 9, em)
	rowsize!(panel_grid, 11, 2em)
	rowsize!(panel_grid, 12, em)
	for c in 1:11
		colgap!(panel_grid, c, 0)
	end

	colsize!(fig.layout, 2, Auto(1))
	colsize!(fig.layout, 3, Auto(2))

	axes = Dict(
		:lift => axis_lift,
		:base => axis_base,
		:braid => axis_braid,
	)
	buttons = Dict(
		:smooth => btn_smooth,
		:close => btn_close,
		:lift => btn_lift,
		:permutation => btn_permutation,
		:undo => btn_undo,
		:redo => btn_redo,
		:clear => btn_clear,
		:save => btn_save,
		:load => btn_load,
	)

	toggles = Dict(
		:smooth => tog_smooth,
		:close => tog_close,
		:lift => tog_lift,
	)

	textboxes = Dict(
		:save => txt_save,
	)

	labels = Dict(
		:permutation => lbl_permutation,
	)

	return fig, axes, buttons, toggles, textboxes, labels
end