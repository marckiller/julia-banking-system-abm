using CSV
using DataFrames

function flatten_event(event::AbstractEvent)
    flattened = Dict{Symbol, Any}(:event_type => string(nameof(typeof(event))))
    for field in fieldnames(typeof(event))
        flattened[field] = getfield(event, field)
    end
    return flattened
end

function reconstruct_event(dict::Dict{Symbol, Any})::AbstractEvent
    T = getfield(@__MODULE__, Symbol(dict[:event_type]))
    values = map(field -> dict[field], fieldnames(T))
    return T(values...)
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
