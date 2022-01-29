using DotEnv
using XLSX, JSON, Downloads

CFG = DotEnv.config()
cache = get(CFG, "CACHE", "") == "true"
verbose = get(CFG, "VERBOSE", "") == "true"
outdir = get(CFG, "WIOT_LOCAL_DATA", "data")

include("scripts/importxlsx.jl")

"""
Import WIOT data from directory. Normalization:
- normalize = 0 for no normalization
- normalize = 1 to normalize across all 
- normalize = 2 to normalize within time
"""
function gettablesfromyears(year::String; directory = ".")::Matrix{Float64}
    data = JSON.parsefile(joinpath(directory, "$(year).json"))
	table = hcat(data["table"]...) # FIXME: Inefficient spread
    return table
end
function gettablesfromyears(years::Int64...; kwargs...)
    gettablesfromyears(string.(years)...; kwargs...)
end
function gettablesfromyears(years::String...; normalize = -1, directory = "")::Array{Float64, 3}
    W₀ = gettablesfromyears(first(years); directory = directory)
    N = size(W₀, 1)
    T = length(years)

    tables = Array{Float64}(undef, (T, N, N))
    tables[1, :, :] = normalize == 2 ? W₀ / maximum(W₀) : W₀

    for t ∈ 2:T
        Wₜ = gettablesfromyears(years[t]; directory = directory)

        tables[t, :, :] = normalize == 2 ? Wₜ / maximum(Wₜ) : Wₜ
    end
    
    if normalize == 1
        tables /= maximum(tables)         
    end

    return tables

end
function gettablesfromyears(;directory = "", kwargs...)
    files = readdir(directory)
    years = replace.(files, ".json" => "")
    return gettablesfromyears(years...; directory = directory, kwargs...)
end

function getcolumns(; directory = ".")
    firstfile = directory |> readdir |> first
    data = JSON.parsefile(joinpath(directory, firstfile))

    columns = Tuple.(data["columns"])
	idmap = data["industry"]

    return columns, idmap
end

function getcountriesdata(columns::Vector{Tuple{String, String}}, tables::Array{Float64, 3})
    countries = unique(last.(columns))
    return getcountriesdata(columns, tables, countries...)
end
function getcountriesdata(columns::Vector{Tuple{String, String}}, tables::Array{Float64, 3}, countries::String...)
    
    T = size(tables, 1)
    
    indices = Set(findall(c -> last(c) ∈ countries, columns))

    for t in 1:T
        trivial = Set(i for i in indices if all(tables[t, i, :] .≈ 0))
        
        setdiff!(indices, trivial)
    end

    idx = indices |> collect |> sort

    return @view(tables[:, idx, idx]), columns[idx]
end


ismain = abspath(PROGRAM_FILE) == @__FILE__
if ismain && !cache
    # TODO: The years 2010 and 2011 have "sep" and an extre url path.

    years = 1995:2009
    for y ∈ years
        year = string(y)
        verbose && print("Downloading $(year)...\r")
    
        data = makeurl(year) |> downloadxlsx

        open(joinpath(outdir, "$(year).json"), "w") do io
            write(io, json(data))
        end
    end

    print("\n...done!")
end

