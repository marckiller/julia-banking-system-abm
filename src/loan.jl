abstract type Loan end

struct BulletLoan <: Loan
    principal::Int
    interest_rate::Float64
    term::Int #in days
    start_time::Int
    end_time::Int
    repay_amount::Int
    borrower::Symbol
    lender::Symbol
end

function BulletLoan(principal::Int, interest_rate::Float64, term::Int, start_time::Int, borrower::Symbol, lender::Symbol)
    end_time = start_time + term
    repay_amount = round(Int, principal * (1 + interest_rate / 365) ^ term)
    return BulletLoan(principal, interest_rate, term, start_time, end_time, repay_amount, borrower, lender)
end
