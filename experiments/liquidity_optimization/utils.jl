using Distributions

function generate_initial_reserves(total::Int, n::Int, min_val::Int)
    remaining = total - n * min_val
    raw_shares = rand(Dirichlet(n, 1.0))
    extras = round.(Int, raw_shares .* remaining)
    extras[end] += total - (n * min_val + sum(extras[1:end-1]))
    return [min_val + extras[i] for i in 1:n]
end