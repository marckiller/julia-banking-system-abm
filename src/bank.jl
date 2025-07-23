mutable struct Bank
    id::Int
    reserves::Int
    min_reserves_frac::Float64

    total_liabilities::Int
    total_assets::Int

    credit_interest_rate::Float64
    deposit_interest_rate::Float64
    interbank_credit_rate::Float64
end

function Bank(id::Int, reserves::Int, min_reserves_frac::Float64,
               credit_interest_rate::Float64, deposit_interest_rate::Float64,
               interbank_credit_rate::Float64)
    return Bank(id, reserves, min_reserves_frac, 0, 0, 
    credit_interest_rate, deposit_interest_rate, 
    interbank_credit_rate)
end