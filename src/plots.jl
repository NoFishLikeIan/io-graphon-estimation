a4 = [11.69, 8.27]
theme(:dao)
default(size = 50 * a4, dpi = 250, label = nothing)

function plotgraphon(f; N = 100, kwargs...)
    unit = range(0, 1; length = N)
    heatmap(
		unit, unit, f; 
		aspect_ratio = 1, xlims = ylims = (0., 1.),
		xlabel = "x", ylabel = "y",
		c = :deep, kwargs...
	)
end