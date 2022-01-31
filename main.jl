# Environment
using DotEnv
DotEnv.config()
datapath = get(ENV, "DATA_PATH", "data")

using Random; Random.seed!(1212)
using JSON

using Interpolations
using Statistics

using ProgressMeter
using Plots, LaTeXStrings

include("src/data-utils/wiotingest.jl")
include("src/plots.jl")
include("src/estimation.jl")

tables = gettablesfromyears(directory = datapath, normalize = 2)
columns, idmap = getcolumns(directory = datapath)

allcountries = last.(columns) |> unique

for country in allcountries
    println("Country $country...")
    
    country_tables = getcountriesdata(columns, tables, country) |> first

    Wₜ = country_tables[1, :, :]
    n = size(Wₜ, 1)
    V = collect(1:n)
    G = Graph(V, Wₜ)

    Pₜ = isfe(G, 4; l = 10, decay = 0.05)
    g = stepwisegraphon(G, last(Pₜ))

    graphonplot = plotgraphon(g; title = "Country $country")

    savefig(graphonplot, "plots/c-estimate/$country.png") 
end
