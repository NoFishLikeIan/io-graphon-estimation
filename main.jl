using DotEnv
using JSON
using ProgressMeter
using Plots, LaTeXStrings

using Random, Distributions
Random.seed!(1212)

using Base.Iterators
using Interpolations


DotEnv.config()
datapath = get(ENV, "DATA_PATH", "data")

include("src/data-utils/wiotingest.jl")
include("src/plots.jl")
include("src/estimation.jl")

tables = gettablesfromyears(directory = datapath, normalize = 2)
columns, idmap = getcolumns(directory = datapath)

allcountries = last.(columns) |> unique

for country in allcountries
    println("Country $country")
    
    country_tables = getcountriesdata(columns, tables, country) |> first

    Wₜ = country_tables[1, :, :]
    n = size(Wₜ, 1)
    V = collect(1:n)
    G = Graph(V, Wₜ)

    try
        Pₜ = isfe(G, 10; l = 10, decay = 0.9)
        g = stepwisegraphon(G, last(Pₜ))

        graphonplot = plotgraphon(g; title = "Country $country")

        savefig(graphonplot, "plots/c-estimate/$country.png") 
    catch
    end

end