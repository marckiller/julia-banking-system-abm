function event_repayment(principal::Int, annual_interest_rate::Float64, term::Int)::Int
    return round(Int, principal * (1 + annual_interest_rate / 365)^term)
end

function append_replayed_bank_states!(
    rows::DataFrame,
    banks::Dict{Int, Bank},
    event::AbstractEvent
)
    for (id, bank) in banks
        push!(rows, (
            time = event.time,
            event_id = event.event_id,
            event_type = string(nameof(typeof(event))),
            id = id,
            reserves = bank.reserves,
            total_liabilities = bank.total_liabilities,
            total_loan_assets = bank.total_loan_assets,
            min_reserves = bank.min_reserves,
            R_client_loan = bank.R_client_loan,
            R_bank_loan = bank.R_bank_loan,
            R_deposit = bank.R_deposit
        ))
    end
end

function replay_bank_states(events::Vector{AbstractEvent})::DataFrame
    banks = Dict{Int, Bank}()
    rows = DataFrame(
        time = Int[],
        event_id = Int[],
        event_type = String[],
        id = Int[],
        reserves = Int[],
        total_liabilities = Int[],
        total_loan_assets = Int[],
        min_reserves = Float64[],
        R_client_loan = Float64[],
        R_bank_loan = Float64[],
        R_deposit = Float64[]
    )

    for event in sort(events; by = e -> (e.time, e.event_id))
        state_changed = true

        if event isa EventBankCreated
            banks[event.bank_id] = create_bank(
                event.bank_id,
                event.initial_reserves,
                event.min_reserves,
                event.R_client_loan,
                event.R_bank_loan,
                event.R_deposit
            )

        elseif event isa EventGrantClientLoan
            bank = banks[event.bank_id]
            repayment = event_repayment(event.principal, event.annual_interest_rate, event.term)
            bank.total_loan_assets += repayment
            bank.reserves -= event.principal

        elseif event isa EventClientLoanRepaid
            bank = banks[event.bank_id]
            bank.total_loan_assets -= event.repayment
            bank.reserves += event.repayment

        elseif event isa EventClientLoanDefaulted
            bank = banks[event.bank_id]
            bank.total_loan_assets -= event.repayment

        elseif event isa EventGrantClientDeposit
            bank = banks[event.bank_id]
            repayment = event_repayment(event.principal, event.annual_interest_rate, event.term)
            bank.reserves += event.principal
            bank.total_liabilities += repayment

        elseif event isa EventDepositRepaid
            bank = banks[event.bank_id]
            bank.reserves -= event.repayment
            bank.total_liabilities -= event.repayment

        elseif event isa EventDepositDefaulted
            bank = banks[event.bank_id]
            bank.total_liabilities -= event.repayment

        elseif event isa EventGrantBankLoan
            borrower = banks[event.bank_borrower_id]
            lender = banks[event.bank_lender_id]
            repayment = event_repayment(event.principal, event.annual_interest_rate, event.term)
            borrower.total_liabilities += repayment
            borrower.reserves += event.principal
            lender.total_loan_assets += repayment
            lender.reserves -= event.principal

        elseif event isa EventBankLoanRepaid
            borrower = banks[event.bank_borrower_id]
            lender = banks[event.bank_lender_id]
            borrower.reserves -= event.repayment
            borrower.total_liabilities -= event.repayment
            lender.reserves += event.repayment
            lender.total_loan_assets -= event.repayment

        elseif event isa EventBankLoanDefaulted
            borrower = banks[event.bank_borrower_id]
            lender = banks[event.bank_lender_id]
            borrower.total_liabilities -= event.repayment
            lender.total_loan_assets -= event.repayment

        else
            state_changed = false
        end

        if state_changed
            append_replayed_bank_states!(rows, banks, event)
        end
    end

    return rows
end
