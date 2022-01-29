source = get(CFG, "WIOT_SOURCE", "")
signature = get(CFG, "WIOT_FILE_SIGNATURE", "")

"""
Make WIOT data url from year
"""
makeurl(year::AbstractString) = makeurl(year, "apr")::String
function makeurl(year::AbstractString, month::AbstractString)::String
    yeardecade = year[end - 1:end]

    filename = signature |> 
        x -> replace(x, "YEAR" => yeardecade) |>
        x -> replace(x, "MONTH" => month)

    url = joinpath(source, filename)

    return url
end

"""
Downloads .xlsx file from url and returns an IO-table, a (id, country) list, and a map from ids to industries
"""
function downloadxlsx(url::AbstractString)
    xf = Downloads.download(url) |> XLSX.readxlsx   
     
    data = xf[1]
    lastcell = data.dimension.stop |> string
    lastrow = filter(x -> '0' ≤ x ≤ '9', lastcell)
    
    ids = map(string, filter(!ismissing, data["A7:A$lastrow"]))
    N = length(ids)

    table = data["E7:$lastcell"][1:N, 1:N]

    industries = data["B7:B$(7 + N - 1)"]
    countries = data["C7:C$(7 + N - 1)"]

    industrymap = Dict(ids .=> industries)

    return Dict(
        :table => table,
        :columns => collect(zip(ids, countries)), :industry => industrymap
    )

end