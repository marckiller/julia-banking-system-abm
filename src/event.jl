struct Event
    time::Int
    type::Symbol
    payload::Dict{Symbol, Any}
end

function EventClientLoanRequest(time::Int, bank_id::Int, principal::Int, term::Int)
    return Event(time, :client_loan_request, Dict(:bank_id => bank_id, :principal => principal, :term => term))
end

function EventInterbankLoanRequest(time::Int, bank_id::Int, principal::Int, term::Int)
    return Event(time, :interbank_loan_request, Dict(:bank_id => bank_id, :principal => principal, :term => term))
end

function EventGrantLoan(time::Int, loan_id::Int, borrower::Symbol, lender::Symbol, principal::Int, annual_interest_rate::Float64, term::Int)
    return Event(time, :grant_loan, Dict(:loan_id => loan_id, :borrower => borrower, :lender => lender, :principal => principal, :annual_interest_rate => annual_interest_rate, :term => term))
end

function EventRepayLoan(time::Int, loan_id::Int)
    #loans are kept in the SimulationState loan book (loans::Dict{Int, Loan})
    return Event(time, :repay_loan, Dict(:loan_id => loan_id))
end

function EventClientDepositRequest(time::Int, bank_id::Int, principal::Int)
    return Event(time, :client_deposit_request, Dict(:bank_id => bank_id, :principal => principal))
end