abstract type AbstractEvent end

# repayment events
struct EventRepaymentClientLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    loan_id::Int
    default_probability::Float64
end

struct EventRepaymentBankLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    loan_id::Int
end

struct EventRepaymentDeposit <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    deposit_id::Int
end

# granting events 

struct EventGrantClientLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    client_id::Union{Int, Nothing}
    bank_id::Int
    principal::Int
    term::Int
    annual_interest_rate::Float64
    default_probability::Float64
end

struct EventGrantClientDeposit <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    client_id::Union{Int, Nothing}
    bank_id::Int
    principal::Int
    term::Int
    annual_interest_rate::Float64
end

struct EventGrantBankLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    bank_borrower_id::Int
    bank_lender_id::Int
    principal::Int
    term::Int
    annual_interest_rate::Float64
end

# requestin events

struct EventRequestClientLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    client_id::Union{Int, Nothing}
    bank_id::Int
    principal::Int
    term::Int
    default_probability::Float64
end

struct EventRequestClientDeposit <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    client_id::Union{Int, Nothing}
    bank_id::Int
    principal::Int
    term::Int
end

struct EventRequestBankLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    bank_borrower_id::Int
    bank_lender_id::Int
    principal::Int
    term::Int
end