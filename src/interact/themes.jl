using GLMakie

const _COLORS = Dict(
	:black => RGBf(0.0, 0.0, 0.0),
	:white => RGBf(1.0, 1.0, 1.0),
	:grey => RGBf(0.33, 0.33, 0.33),
	:blue => Dict(
		:light => RGBf(0.78, 0.88, 1.0),
		:medium => RGBf(0.6, 0.8, 1.0),
		:dark => RGBf(0.0, 0.33, 0.66),
		:highlight => RGBf(0.2, 0.6, 1.0),
	),
	:red => Dict(
		:light => RGBf(1.0, 0.78, 0.88),
		:medium => RGBf(1.0, 0.6, 0.8),
		:dark => RGBf(0.66, 0.0, 0.33),
		:highlight => RGBf(1.0, 0.2, 0.6),
	),
	:green => Dict(
		:light => RGBf(0.78, 1.0, 0.88),
		:medium => RGBf(0.6, 1.0, 0.8),
		:dark => RGBf(0.0, 0.66, 0.33),
		:highlight => RGBf(0.0, 1.0, 0.6),
	),
	:purple => Dict(
		:light => RGBf(0.88, 0.78, 1.0),
		:medium => RGBf(0.8, 0.6, 1.0),
		:dark => RGBf(0.33, 0.0, 0.66),
		:highlight => RGBf(0.6, 0.2, 1.0),
	),
	:orange => Dict(
		:light => RGBf(1.0, 0.88, 0.78),
		:medium => RGBf(1.0, 0.8, 0.6),
		:dark => RGBf(0.66, 0.33, 0.0),
		:highlight => RGBf(1.0, 0.6, 0.2),
	),
	:yellow => Dict(
		:light => RGBf(1.0, 1.0, 0.78),
		:medium => RGBf(1.0, 1.0, 0.6),
		:dark => RGBf(0.66, 0.66, 0.0),
		:highlight => RGBf(1.0, 1.0, 0.2),
	),
)

const _RAINBOW_LIGHT = [
	_COLORS[:blue][:light],
	_COLORS[:purple][:light],
	_COLORS[:red][:light],
	_COLORS[:orange][:light],
	_COLORS[:yellow][:light],
	_COLORS[:green][:light],
]

const _RAINBOW_MEDIUM = [
	_COLORS[:blue][:medium],
	_COLORS[:purple][:medium],
	_COLORS[:red][:medium],
	_COLORS[:orange][:medium],
	_COLORS[:yellow][:medium],
	_COLORS[:green][:medium],
]

const _RAINBOW_DARK = [
	_COLORS[:blue][:dark],
	_COLORS[:purple][:dark],
	_COLORS[:red][:dark],
	_COLORS[:orange][:dark],
	_COLORS[:yellow][:dark],
	_COLORS[:green][:dark],
]

const _RAINBOW_HIGHLIGHT = [
	_COLORS[:blue][:highlight],
	_COLORS[:purple][:highlight],
	_COLORS[:red][:highlight],
	_COLORS[:orange][:highlight],
	_COLORS[:yellow][:highlight],
	_COLORS[:green][:highlight],
]

const _OPPOSITE = Dict(
	:blue => :yellow,
	:yellow => :blue,
	:purple => :orange,
	:orange => :purple,
	:red => :green,
	:green => :red,
)

function OAPlain(;base=:blue, em=12)

if !haskey(_COLORS, base)
	@warn "Unknown color :$base, defaulting to :blue"
	base = :blue
end

return Theme(
	backgroundcolor = _COLORS[:white],
	fontsize = 1em,
	Axis = (
		titlegap = 0.5em,
		backgroundcolor = _COLORS[:white],
		topspinecolor = _COLORS[:black],
		bottomspinecolor = _COLORS[:black],
		leftspinecolor = _COLORS[:black],
		rightspinecolor = _COLORS[:black],
		xtickcolor = _COLORS[:black],
		ytickcolor = _COLORS[:black],
		xticksmirrored = true,
		yticksmirrored = true,
	),
	Axis3 = (
		titlegap = 0.5em,
		backgroundcolor = _COLORS[:white],
		topspinecolor = _COLORS[:black],
		bottomspinecolor = _COLORS[:black],
		leftspinecolor = _COLORS[:black],
		rightspinecolor = _COLORS[:black],
		xtickcolor = _COLORS[:black],
		ytickcolor = _COLORS[:black],
		xticksmirrored = true,
		yticksmirrored = true,
	),
	Button = (
		tellwidth = false,
		tellheight = false,
		cornerradius = 4,
		buttoncolor = _COLORS[base][:medium],
		buttoncolor_active = _COLORS[base][:highlight],
		buttoncolor_hover = _COLORS[base][:highlight],
		labelcolor = _COLORS[:black],
		labelcolor_active = _COLORS[:white],
		labelcolor_hover = _COLORS[:white],
		strokecolor = _COLORS[base][:light],
	),
	Label = (
		tellwidth = false,
		tellheight = false,
	),
	Textbox = (
		tellwidth = false,
		tellheight = false,
		bordercolor= _COLORS[base][:dark],
		bordercolor_focused = _COLORS[base][:dark],
		bordercolor_focused_invalid = _COLORS[base][:dark],
		bordercolor_hover = _COLORS[base][:dark],
		textcolor_placeholder = _COLORS[base][:medium],
	),
	Toggle = (
		tellwidth = false,
		tellheight = false,
		active = true,
		buttoncolor = _COLORS[base][:dark],
		framecolor_active = _COLORS[base][:medium],
		framecolor_inactive = _COLORS[base][:light],
	),
	PathPlot = (
		emphcolor = _COLORS[base][:highlight],
		hovercolor = _COLORS[base][:highlight],
		regcolor = _COLORS[base][:dark],
	),
	BraidPlot = (
		emphcolor = _COLORS[base][:highlight],
		hovercolor = _COLORS[base][:highlight],
		regcolor = _COLORS[base][:dark],
	),
	BranchPlot = (
		markersize = 12,
		marker = :xcross,
		color = _COLORS[_OPPOSITE[base]][:highlight],
	)
)
end