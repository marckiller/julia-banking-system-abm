using Random

function random_keys_except(dict::Dict, exclude_key)
    other_keys = filter(k -> k != exclude_key, keys(dict))
    return shuffle!(collect(other_keys))
end

function check_interbank_loan(lender::Bank, amount::Int)
    required_reserves = lender.min_reserves * lender.total_liabilities
    available = lender.reserves - required_reserves
    if available >= amount
        return (
            is_available = true,
            interest_rate = lender.R_bank_loan,
            max_amount = available
        )
    else
        return nothing
    end
end

function pop!(dict::Dict, key, default=nothing)
    #poping element from dict
    if haskey(dict, key)
        val = dict[key]
        delete!(dict, key)
        return val
    else
        return default
    end
end