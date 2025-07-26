abstract type Loan end

struct BulletLoan <: Loan
    id::Int
    principal::Int
    interest_rate::Float64
    term::Int
    time_issued::Int
    time_repay::Int
    repayment::Int
    borrower::Union{Int, Nothing}
    lender::Union{Int, Nothing}
    is_defaulted::Bool
end

function BulletLoan(id::Int, principal::Int, annual_interest_rate::Float64, term::Int, time_issued::Int, borrower::Union{Int, Nothing}, lender::Union{Int, Nothing})
    time_repay = time_issued + term
    repayment = round(Int, principal * (1 + annual_interest_rate / 365)^term) # Assuming interest is compounded daily
    return BulletLoan(id, principal, annual_interest_rate, term, time_issued, time_repay, repayment, borrower, lender, false)
end