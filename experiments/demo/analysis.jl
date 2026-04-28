using DataFrames

function bank_net_worth(row)
    return Float64(row.reserves + row.total_loan_assets - row.total_liabilities)
end

function loan_repayment(row)
    return round(Int, row.principal * (1 + row.annual_interest_rate / 365)^row.term)
end

function completed_ids(events::DataFrame, event_types::Vector{String}, id_col::Symbol, snapshot_day::Int)
    selected = filter(row -> row.time <= snapshot_day && row.event_type in event_types && !ismissing(row[id_col]), events)
    return Set(Int.(selected[!, id_col]))
end

function outstanding_value(events::DataFrame, grant_event_type::String, completed_event_types::Vector{String}, id_col::Symbol, snapshot_day::Int)
    done = completed_ids(events, completed_event_types, id_col, snapshot_day)
    grants = filter(row -> row.time <= snapshot_day && row.event_type == grant_event_type && !ismissing(row[id_col]), events)
    total = 0.0
    for row in eachrow(grants)
        if !(Int(row[id_col]) in done)
            total += loan_repayment(row)
        end
    end
    return total
end

function system_reserves_at(bank_states::DataFrame, snapshot_day::Int)
    selected = filter(row -> row.time <= snapshot_day, bank_states)
    snapshot_time = maximum(selected.time)
    return sum(filter(row -> row.time == snapshot_time, selected).reserves)
end

function system_balance_sheet(events::DataFrame, bank_states::DataFrame, snapshot_day::Int)
    reserves = Float64(system_reserves_at(bank_states, snapshot_day))
    client_loans = outstanding_value(events, "EventGrantClientLoan", ["EventClientLoanRepaid", "EventClientLoanDefaulted"], :loan_id, snapshot_day)
    interbank_assets = outstanding_value(events, "EventGrantBankLoan", ["EventBankLoanRepaid", "EventBankLoanDefaulted"], :loan_id, snapshot_day)
    deposits = outstanding_value(events, "EventGrantClientDeposit", ["EventDepositRepaid", "EventDepositDefaulted"], :deposit_id, snapshot_day)
    interbank_liabilities = interbank_assets
    equity = reserves + client_loans + interbank_assets - deposits - interbank_liabilities

    return (
        assets = ["reserves", "client loans", "interbank assets"],
        asset_values = [reserves, client_loans, interbank_assets],
        liabilities = ["deposits", "interbank liabilities", "equity / net worth"],
        liability_values = [deposits, interbank_liabilities, equity]
    )
end

function cumulative_event_series(events::DataFrame, event_types::Vector{String})
    times = sort(unique(events.time))
    series = Dict{String, Vector{Int}}(event_type => Int[] for event_type in event_types)
    counts = Dict(event_type => 0 for event_type in event_types)

    for time in times
        today = filter(row -> row.time == time, events)
        for event_type in event_types
            counts[event_type] += count(==(event_type), today.event_type)
            push!(series[event_type], counts[event_type])
        end
    end

    return times, series
end

function cumulative_principal_series(events::DataFrame, event_types::Vector{String})
    times = sort(unique(events.time))
    series = Dict{String, Vector{Float64}}(event_type => Float64[] for event_type in event_types)
    totals = Dict(event_type => 0.0 for event_type in event_types)

    for time in times
        today = filter(row -> row.time == time, events)
        for event_type in event_types
            selected = filter(row -> row.event_type == event_type && !ismissing(row.principal), today)
            if !isempty(selected)
                totals[event_type] += sum(Float64.(selected.principal))
            end
            push!(series[event_type], totals[event_type])
        end
    end

    return times, series
end

function daily_principal_by_type(events::DataFrame, event_type::String, max_day::Int)
    values = Dict(day => 0.0 for day in 1:max_day)
    selected = filter(row -> row.time <= max_day && row.event_type == event_type && !ismissing(row.principal), events)
    for row in eachrow(selected)
        values[Int(row.time)] += Float64(row.principal)
    end
    return values
end

function rolling_sum(values::Dict{Int, Float64}, day::Int, window_days::Int)
    start_day = max(1, day - window_days + 1)
    return sum(values[d] for d in start_day:day)
end

function liquidity_buffer_series(bank_states::DataFrame)
    tmp = copy(bank_states)
    tmp.required_reserves = tmp.total_liabilities .* tmp.min_reserves
    grouped = combine(
        groupby(tmp, :time),
        :reserves => sum => :system_reserves,
        :required_reserves => sum => :required_reserves
    )
    sort!(grouped, :time)
    grouped.liquidity_buffer = grouped.system_reserves .- grouped.required_reserves
    return grouped
end

function reason_label(reason)
    labels = Dict(
        "negative_expected_value_credit_risk" => "credit risk / negative EV",
        "insufficient_liquidity_after_own_reserves" => "insufficient own liquidity",
        "insufficient_liquidity_even_after_interbank_funding" => "after interbank",
        "reserve_constraint_violation" => "reserve constraint"
    )
    return get(labels, string(reason), string(reason))
end

function interbank_lending_matrix(events::DataFrame)
    banks = collect(1:DEMO_NUM_BANKS)
    matrix = Dict((lender, borrower) => 0.0 for lender in banks for borrower in banks)
    selected = filter(row -> row.event_type == "EventGrantBankLoan", events)
    for row in eachrow(selected)
        lender = Int(row.bank_lender_id)
        borrower = Int(row.bank_borrower_id)
        matrix[(lender, borrower)] += Float64(row.principal)
    end
    return banks, matrix
end

function event_count(events::DataFrame, event_type::String)
    return count(==(event_type), events.event_type)
end

function event_principal_sum(events::DataFrame, event_type::String)
    selected = filter(row -> row.event_type == event_type && !ismissing(row.principal), events)
    isempty(selected) && return 0.0
    return sum(Float64.(selected.principal))
end
