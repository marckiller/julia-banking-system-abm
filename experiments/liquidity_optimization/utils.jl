using Distributions

function generate_initial_reserves(total::Int, n::Int)
    if n <= 0
        error("Number of banks must be positive")
    end
    base = div(total, n)
    extras = total - base * n
    reserves = fill(base, n)
    for i in 1:extras
        reserves[i] += 1
    end
    return reserves
end