# Description

Small interactive tool for visualizing monodromy and numerically calculating the monodromy action. The interface is all written with [GLMakie.jl](https://github.com/MakieOrg/Makie.jl).

This is mainly for small examples and educational purposes. The actual implementation is far less sophisticated than what you can find in [HomotopyContinuation.jl](https://www.juliahomotopycontinuation.org) except insofar as this package works with non-polynomial maps. Their restriction to polynomials is what allows their use of Smale's theory to certify root calculations. Of course, it's not possible (yet, that I know of) to certify a *path*, which would be quite interesting -- then we could provably numerically calculate a monodromy group.

In this package, each monodromy step comprises one step of Euler's method followed by two steps of Newton for path correction. This seems more than adequate in small-degree examples for which this tool is intended (a testament to path correction) but is an area for improvement.

If you have comments, questions, or find a cool-looking example, I'd love to know!

# Very quick guide

Run any of the following:

```
interact_power(;degree=4)
interact_chebyshev()
interact_rabbits()
interact_symmetric_seven()
```

You will see a window with three plots: the lift and base on the left, and a 3D plot on the right. You can draw paths on the base plot with your mouse, and they will be lifted to the provided fibers. At the same time, the 3D plot will show those paths plotted against time, so you can see how they braid.


Mouse controls:

- right click: clear plot (lift or base)
- middle click / option click on base: animated retrace of the current path
- shift + middle click / option click on base: instant retrace of the current path
- scroll: zoom in or out
- right click + drag: pan around (be careful not to clear! this binding will likely change to shift+left)

Panel controls:

- paths close automatically by default
- lift will animate by default
- get permutation will report its best guess at the permutation for your current path; this wil likely error if it is not a loop
- red buttons do not function right now, but will one day

# Quick guide

First, define a self-cover of the Riemann sphere. To be considered étale, you must provide lifting data (the derivative) and the branch locus (at which we imagine punctures have been made, and further punctures on its preimage).

```
f(z) = z^3 - 12z
df(z) = 3z^2 - 12
branches = Set([-16 + 0.0im, 16 + 0.0im])
F = ComplexEtaleCover(f,df,branches)
```

To experiment with it, call `interact` and provide:

- your cover
- a dictionary of fibers over the base point
- the actual base point
- limits for the lift plot
- limits for the base plot
- optionally, request a horizontal layout

The names are used as symbols when representing the permutation, and for display on the plot.


```
fibers = Dict(:z => 0.0im, :a => 3.45 + 0.0im, :b => -3.45 + 0.0im)
base_pt = 0.0im
ll = (-5,5,-3,3)
lb = (-25,25,-20,20)
plotdata = interact(F, fibers, base_pt, ll, lb)
display(plotdata[:fig])
```

If you don't have fibers or a base in mind, you can instead give it just one point to use as a fiber. From there, you can find others by using the monodromy method :)

A rough heuristic for deciding the limits:

- Base limits should make all branch points visible, perhaps roughly centered around them, with some room for drawing
- If the degree is $d$, then the lift axes should be roughly a $d$th root of the base axes. When the map takes the real line to itself, lifts tend to flatten toward it too.

Usually you'll want to tweak them after drawing your first paths (or while determining your fibers).

# Long guide

Almost all the current functions are documented. Reading the examples shows you how to run more visual calculations. Currently there are no examples for the non-visual uses. Those are handled by:

- `piecewiselinear` in `paths.jl`: returns a path with specified vertices.
- `lollipop` in `paths.jl`: returns a "lollipop" shaped path from one point around another by attaching two lines and a circle of specified radius.
- `monodromy_permutation` in `lifting.jl`: returns the permutation associated to a loop's action on named fibers.

Note that my groups all act from the right, so that $g \in G$ acting on $x \in X$ is as $x^g$ rather than $g(x)$.


# Planned features

Suggestions welcome. Most of the very small interface tweaks will be finished soon, and are just listed here for me.

## Mathematical

	- Integrate with `GAP.jl` to calculate and name the groups (when small).
	- Better algorithms and implementations.
	- Path smoothing.

## Technical

	- Saving and loading paths to files, or to a provided dictionary variable for easier REPL access.
	- Split off the interactivity into an extension or separate package to reduce load time when not using them.
	- More "safety" features like checking that fibers are, in fact, fibers.

## Interface

Most of these will have a button or hotkey associated. The current controls are entirely by mouse.

	- Saving paths (see above).
	- Undo/redo.
	- Smoothing (see above).
	- Hide interface and export animation.
