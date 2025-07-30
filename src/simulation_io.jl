using CSV
using DataFrames

function flatten_event(event::AbstractEvent)

    base = Dict(
        :event_id => event.event_id,
        :trigger_event_id => event.trigger_event_id,
        :time => event.time,
        :event_type => string(nameof(typeof(event)))
    )

    if event isa EventRepaymentClientLoan
        base[:loan_id] = event.loan_id
        base[:default_probability] = event.default_probability

    elseif event isa EventRepaymentBankLoan
        base[:loan_id] = event.loan_id

    elseif event isa EventRepaymentDeposit
        base[:deposit_id] = event.deposit_id

    elseif event isa EventGrantClientLoan
        base[:client_id] = event.client_id
        base[:bank_id] = event.bank_id
        base[:principal] = event.principal
        base[:term] = event.term
        base[:annual_interest_rate] = event.annual_interest_rate
        base[:default_probability] = event.default_probability

    elseif event isa EventGrantClientDeposit
        base[:client_id] = event.client_id
        base[:bank_id] = event.bank_id
        base[:principal] = event.principal
        base[:term] = event.term
        base[:annual_interest_rate] = event.annual_interest_rate

    elseif event isa EventGrantBankLoan
        base[:bank_borrower_id] = event.bank_borrower_id
        base[:bank_lender_id] = event.bank_lender_id
        base[:principal] = event.principal
        base[:term] = event.term
        base[:annual_interest_rate] = event.annual_interest_rate

    elseif event isa EventRequestClientDeposit
        base[:client_id] = event.client_id
        base[:bank_id] = event.bank_id
        base[:principal] = event.principal
        base[:term] = event.term
    
    elseif event isa EventRequestClientLoan
        base[:client_id] = event.client_id
        base[:bank_id] = event.bank_id
        base[:principal] = event.principal
        base[:term] = event.term
        base[:default_probability] = event.default_probability

    elseif event isa EventRequestBankLoan
        base[:bank_borrower_id] = event.bank_borrower_id
        base[:bank_lender_id] = event.bank_lender_id
        base[:principal] = event.principal
        base[:term] = event.term
    end

    return base
end

function reconstruct_event(dict::Dict{Symbol, Any})::AbstractEvent
    T = getfield(Main, Symbol(dict[:event_type]))

    if T == EventRepaymentClientLoan
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:loan_id], dict[:default_probability])
    elseif T == EventRepaymentBankLoan
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:loan_id])
    elseif T == EventRepaymentDeposit
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:deposit_id])
    elseif T == EventGrantClientLoan
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:client_id], dict[:bank_id], dict[:principal], dict[:term], dict[:annual_interest_rate], dict[:default_probability])
    elseif T == EventGrantClientDeposit
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:client_id], dict[:bank_id], dict[:principal], dict[:term], dict[:annual_interest_rate])
    elseif T == EventGrantBankLoan
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:bank_borrower_id], dict[:bank_lender_id], dict[:principal], dict[:term], dict[:annual_interest_rate])
    elseif T == EventRequestClientDeposit
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:client_id], dict[:bank_id], dict[:principal], dict[:term])
    elseif T == EventRequestClientLoan
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:client_id], dict[:bank_id], dict[:principal], dict[:term], dict[:default_probability])
    elseif T == EventRequestBankLoan
        return T(dict[:event_id], dict[:trigger_event_id], dict[:time], dict[:bank_borrower_id], dict[:bank_lender_id], dict[:principal], dict[:term])
    else
        error("Unknown event type: $(dict[:event_type])")
    end
end

function keys_union(dicts::Vector{Dict{Symbol, Any}})
    reduce(union, map(keys, dicts))
end

function flattened_events_to_dataframe(flattened_events::Vector{Dict{Symbol, Any}})
    cols = keys_union(flattened_events)
    data = Dict(k => Vector{Any}(undef, length(flattened_events)) for k in cols)
    for (i, ev) in enumerate(flattened_events)
        for k in cols
            val = get(ev, k, missing)
            data[k][i] = val === nothing ? missing : val
        end
    end
    return DataFrame(data)
end

function save_events_to_csv(executed_events::Vector{AbstractEvent}, path::String)
    flattened_events = map(flatten_event, executed_events)
    df = flattened_events_to_dataframe(flattened_events)
    CSV.write(path, df)
    @info "Executed events saved to $(path)"
end

function load_events_from_csv(path::String)::Vector{AbstractEvent}
    df = CSV.read(path, DataFrame)
    events = AbstractEvent[]
    for row in eachrow(df)
        dict = Dict(Symbol(k) => row[k] === missing ? nothing : row[k] for k in names(df))
        push!(events, reconstruct_event(dict))
    end
    return events
end


function save_loans_to_csv(loans::Vector{Loan}, path::String)
    df = DataFrame(
        id = [loan.id for loan in loans],
        principal = [loan.principal for loan in loans],
        interest_rate = [loan.interest_rate for loan in loans],
        term = [loan.term for loan in loans],
        time_issued = [loan.time_issued for loan in loans],
        time_repay = [loan.time_repay for loan in loans],
        repayment = [loan.repayment for loan in loans],
        borrower = [loan.borrower === nothing ? missing : loan.borrower for loan in loans],
        lender = [loan.lender === nothing ? missing : loan.lender for loan in loans],
        is_defaulted = [loan.is_defaulted for loan in loans]
    )
    CSV.write(path, df)
    @info "Loans saved to $(path)"
end


function load_loans_from_csv(path::String)::Vector{Loan}
    df = CSV.read(path, DataFrame)
    loans = Loan[]
    for row in eachrow(df)
        borrower = row[:borrower] === missing ? nothing : row[:borrower]
        lender = row[:lender] === missing ? nothing : row[:lender]
        loan = BulletLoan(
            row[:id], row[:principal], row[:interest_rate], row[:term],
            row[:time_issued], borrower, lender
        )
        loan.time_repay = row[:time_repay]
        loan.repayment = row[:repayment]
        loan.is_defaulted = row[:is_defaulted]
        push!(loans, loan)
    end
    return loans
end

function save_banks_states_to_csv(banks_states::DataFrame, path::String)
    CSV.write(path, banks_states)
    @info "Bank states saved to $(path)"
end

function load_banks_states_from_csv(path::String)::DataFrame
    df = CSV.read(path, DataFrame)
    if !haskey(df, :id) || !haskey(df, :reserves) ||
       !haskey(df, :total_liabilities) || !haskey(df, :total_loan_assets)
        error("CSV file does not contain required columns: id, reserves, total_liabilities, total_loan_assets")
    end
    return df
end

