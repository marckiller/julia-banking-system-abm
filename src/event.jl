abstract type AbstractEvent end

# system facts
struct EventBankCreated <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    bank_id::Int
    initial_reserves::Int
    min_reserves::Float64
    R_client_loan::Float64
    R_bank_loan::Float64
    R_deposit::Float64
end

# scheduled repayment commands
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

# granting facts

struct EventGrantClientLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    client_id::Union{Int, Nothing}
    bank_id::Int
    loan_id::Int
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
    deposit_id::Int
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
    loan_id::Int
    principal::Int
    term::Int
    annual_interest_rate::Float64
end

# rejection facts

struct EventRejectClientLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    client_id::Union{Int, Nothing}
    bank_id::Int
    principal::Int
    term::Int
    default_probability::Float64
    reason::String
end

struct EventRejectBankLoan <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    bank_borrower_id::Int
    bank_lender_id::Int
    principal::Int
    term::Int
    reason::String
end

# repayment/default facts

struct EventClientLoanRepaid <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    loan_id::Int
    bank_id::Int
    repayment::Int
end

struct EventClientLoanDefaulted <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    loan_id::Int
    bank_id::Int
    repayment::Int
end

struct EventDepositRepaid <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    deposit_id::Int
    bank_id::Int
    repayment::Int
end

struct EventDepositDefaulted <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    deposit_id::Int
    bank_id::Int
    repayment::Int
end

struct EventBankLoanRepaid <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    loan_id::Int
    bank_borrower_id::Int
    bank_lender_id::Int
    repayment::Int
end

struct EventBankLoanDefaulted <: AbstractEvent
    event_id::Int
    trigger_event_id::Union{Int, Nothing}
    time::Int
    loan_id::Int
    bank_borrower_id::Int
    bank_lender_id::Int
    repayment::Int
end

# requesting commands

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
