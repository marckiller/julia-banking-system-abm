abstract type Loan end

struct BulletLoan <: Loan
    id::Int
    principal::Int
    annual_interest_rate::Float64
    term::Int #in days
    issue_date::Int
    end_time::Int
    repay_amount::Int
    borrower::Symbol
    lender::Symbol
end

function BulletLoan(id::Int,principal::Int, annual_interest_rate::Float64, term::Int, issue_date::Int, borrower::Symbol, lender::Symbol)
    end_time = issue_date + term
    repay_amount = round(Int, principal * (1 + annual_interest_rate / 365) ^ term)
    return BulletLoan(id, principal, annual_interest_rate, term, issue_date, end_time, repay_amount, borrower, lender)
end
