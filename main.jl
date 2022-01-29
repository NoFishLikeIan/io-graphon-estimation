using DotEnv
using JSON

DotEnv.config()
datapath = get(ENV, "DATA_PATH", "data")

include("src/data-utils/wiotingest.jl")