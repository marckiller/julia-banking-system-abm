using Distributions

function generate_initial_reserves(total::Int, n::Int, min_val::Int)
    remaining = total - n * min_val
    if remaining < 0
        error("Total is too small to allocate minimum reserves to all banks")
    end
    if n == 1
        extras = [remaining]
    else
        raw = rand(Dirichlet(n, 1.0)) .* remaining
        extras = floor.(Int, raw)
        diff = remaining - sum(extras)
        for i in 1:diff
            extras[i] += 1
        end
    end
    return [min_val + extras[i] for i in 1:n]
end