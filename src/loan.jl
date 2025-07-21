abstract type Loan end

struct LumpSumLoan <: Loan
    principal::Int
    interest_rate::Float64
    due_date::Int
    borrower::Agent
    lender::Agent
end

struct AmortizingLoan <: Loan
    principal::Int
    interest_rate::Float64
    schedule::Vector{Tuple{Int, Int}}
    next_payment_time::Int
    borrower::Agent
    lender::Agent
end

function generate_amortization_schedule(
    principal::Int,
    annual_rate::Float64,
    start_time::Int,
    num_payments::Int,
    period_length::Int)::Vector{Tuple{Int, Int}}

    period_rate = annual_rate * period_length / 365
    total_to_repay = principal * (1 + period_rate)
    base_payment = round(Int, total_to_repay / num_payments)
    payments = fill(base_payment, num_payments)
    payments[end] += round(Int, total_to_repay) - sum(payments)
    schedule = [(start_time + i * period_length, payments[i]) for i in 1:num_payments]
    return schedule
end

function create_lump_sum_loan(principal::Int, rate::Float64, t_start::Int, t_due::Int, borrower::Agent, lender::Agent)
    return LumpSumLoan(principal, rate, t_due, borrower, lender)
end

function create_amortizing_loan(principal::Int, rate::Float64, t_start::Int, n_periods::Int, period_length::Int, borrower::Agent, lender::Agent)
    sched = generate_amortization_schedule(principal, rate, t_start, n_periods, period_length)
    return AmortizingLoan(principal, rate, sched, borrower, lender)
end