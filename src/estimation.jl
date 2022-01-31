Nodes = Vector{Int64}
Partition = Vector{Nodes}

struct Graph
    V::Nodes
    W::Matrix{Float64}
end


"Empirical cut distance over the partitions X and Y."
function c(X::Nodes, Y::Nodes; G::Graph)
    sum(G.W[X, Y])
end

e(X::Nodes, Y::Nodes; G::Graph) = c(X, Y; G = G) / (length(X) * length(Y))


"Algorithm 1 of Cai, Ackerman, Freer (2020)"
function iterstep(G::Graph, P::Partition, l::Int64, decay::Float64)::Partition 
    n = G.V[end]
    Q = [[1]]
    cᵧ = [1]

    ε = 1

    while length(Q) < l
        for i ∈ 2:n

            d(j) = sum(
                length(Pᵣ) * 
                abs(e([i], Pᵣ; G = G) - e([cᵧ[j]], Pᵣ; G = G)) for Pᵣ ∈ P
            ) / n
            
            dᵥ = d.(1:length(cᵧ))

            jᵐ = argmin(dᵥ)

            if dᵥ[jᵐ] < ε
                push!(Q[jᵐ], i)
            else
                push!(Q, [i])
                push!(cᵧ, i) 
            end


            ε = ε * (1 - decay)
        end
    end

    return Q
end

"Implementation of iterative step function estimation by Cai, Ackerman, Freer (2020)"
function isfe(G::Graph, T::Int64; l = 10, decay = 0.05) 
    σ = randperm(G.V[end])

    P₀ = [ σ[j:l:end] for j ∈ 1:l ]

    Phistory = [P₀]

    for _ in 1:T
        P = last(Phistory)

        P′= iterstep(G, P, l, decay)
        push!(Phistory, P′)
    end

    return Phistory

end

"Plot a stepwise function from `G`, given partition `P`."
function stepwisegraphon(G::Graph, P::Partition)
    Ŵ = zeros(size(G.W))
    for p ∈ P
        Ŵ[p, p] .= mean(G.W[p, p])
    end

    unit = range(0, 1; length = length(G.V))

    g = interpolate(
        (unit, unit), Ŵ, 
        (Gridded(Constant()), Gridded(Constant()))
    )
    
    return (x, y) -> g(x, y)
end