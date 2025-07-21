abstract type CreditScoreModel end

struct SimpleScoreModel <: CreditScoreModel end

function score(model::SimpleScoreModel, client::Client, normalization_factor::Int)::Float64
    total_loans = sum(l.principal for l in client.loans)
    total_deposits = sum(d.principal for d in client.deposits)
    net_wealth = client.wealth + total_deposits - total_loans
    debt_burden = total_loans / max(1, client.income)
    raw_score = net_wealth / (1+ debt_burden)
    return clamp(raw_score / normalization_factor, 0.0, 1.0)
end