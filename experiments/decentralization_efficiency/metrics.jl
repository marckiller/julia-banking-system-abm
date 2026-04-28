using BankSim
using CSV
using DataFrames
using Statistics

if !isdefined(@__MODULE__, :RESULTS_DIR)
    include("config.jl")
end

const EVENT_CLIENT_LOAN_REQUESTED = "EventRequestClientLoan"
const EVENT_CLIENT_LOAN_GRANTED = "EventGrantClientLoan"
const EVENT_CLIENT_LOAN_REJECTED = "EventRejectClientLoan"
const EVENT_DEPOSIT_REPAID = "EventDepositRepaid"
const EVENT_DEPOSIT_DEFAULTED = "EventDepositDefaulted"
const EVENT_INTERBANK_REQUESTED = "EventRequestBankLoan"
const EVENT_INTERBANK_GRANTED = "EventGrantBankLoan"
const EVENT_INTERBANK_REPAID = "EventBankLoanRepaid"
const EVENT_INTERBANK_DEFAULTED = "EventBankLoanDefaulted"
const EVENT_BANK_CREATED = "EventBankCreated"

function safe_ratio(numerator::Real, denominator::Real)
    return denominator == 0 ? missing : numerator / denominator
end

function score_ratio(numerator::Real, denominator::Real; empty_score::Float64 = 1.0)
    return denominator == 0 ? empty_score : numerator / denominator
end

function event_rows(events::DataFrame, event_type::String)::DataFrame
    return filter(:event_type => ==(event_type), events)
end

function filter_analysis_window(events::DataFrame, analysis_start_day::Int, analysis_end_day::Int)::DataFrame
    return filter(row -> analysis_start_day <= row.time <= analysis_end_day, events)
end

function count_events(events::DataFrame, event_type::String)::Int
    return nrow(event_rows(events, event_type))
end

function sum_event_column(events::DataFrame, event_type::String, column::Symbol)::Float64
    if !(column in Symbol.(names(events)))
        return 0.0
    end

    rows = event_rows(events, event_type)
    isempty(rows) && return 0.0

    return sum(skipmissing(rows[!, column]); init = 0.0)
end

function row_to_event(row)::AbstractEvent
    dict = Dict{Symbol, Any}()
    for name in propertynames(row)
        value = getproperty(row, name)
        dict[name] = ismissing(value) ? nothing : value
    end
    return reconstruct_event(dict)
end

function reconstruct_events(events::DataFrame)::Vector{AbstractEvent}
    return [row_to_event(row) for row in eachrow(events)]
end

function net_worth(reserves, total_loan_assets, total_liabilities)
    return reserves + total_loan_assets - total_liabilities
end

function bank_net_worth_at(bank_states::DataFrame, snapshot_day::Int)::Float64
    isempty(bank_states) && return 0.0

    total = 0.0
    for group in groupby(bank_states, :id)
        history = filter(row -> row.time <= snapshot_day, group)
        isempty(history) && continue
        row = last(history)
        total += net_worth(row.reserves, row.total_loan_assets, row.total_liabilities)
    end
    return total
end

function bank_net_metrics(events::DataFrame, analysis_start_day::Int, analysis_end_day::Int)
    bank_states = replay_bank_states(reconstruct_events(events))
    start_net = bank_net_worth_at(bank_states, analysis_start_day)
    end_net = bank_net_worth_at(bank_states, analysis_end_day)
    return start_net, end_net, safe_ratio(end_net, start_net)
end

function clipped_bank_net_growth_score(bank_net_growth_ratio)
    if ismissing(bank_net_growth_ratio)
        return 0.0
    end
    return clamp(bank_net_growth_ratio, 0.0, 2.0) / 2.0
end

function compute_run_metrics(
    run_id::Int,
    events::DataFrame;
    analysis_start_day::Int = ANALYSIS_START_DAY,
    analysis_end_day::Int = ANALYSIS_END_DAY
)
    analysis_events = filter_analysis_window(events, analysis_start_day, analysis_end_day)

    n_loan_requested = count_events(analysis_events, EVENT_CLIENT_LOAN_REQUESTED)
    n_loan_granted = count_events(analysis_events, EVENT_CLIENT_LOAN_GRANTED)
    n_loan_rejected = count_events(analysis_events, EVENT_CLIENT_LOAN_REJECTED)

    requested_loan_principal = sum_event_column(analysis_events, EVENT_CLIENT_LOAN_REQUESTED, :principal)
    granted_loan_principal = sum_event_column(analysis_events, EVENT_CLIENT_LOAN_GRANTED, :principal)
    rejected_loan_principal = sum_event_column(analysis_events, EVENT_CLIENT_LOAN_REJECTED, :principal)

    n_deposit_repaid = count_events(analysis_events, EVENT_DEPOSIT_REPAID)
    n_deposit_defaulted = count_events(analysis_events, EVENT_DEPOSIT_DEFAULTED)
    deposit_repaid_amount = sum_event_column(analysis_events, EVENT_DEPOSIT_REPAID, :repayment)
    deposit_defaulted_amount = sum_event_column(analysis_events, EVENT_DEPOSIT_DEFAULTED, :repayment)
    n_deposit_matured = n_deposit_repaid + n_deposit_defaulted
    deposit_matured_amount = deposit_repaid_amount + deposit_defaulted_amount

    n_interbank_requested = count_events(analysis_events, EVENT_INTERBANK_REQUESTED)
    n_interbank_granted = count_events(analysis_events, EVENT_INTERBANK_GRANTED)
    n_interbank_repaid = count_events(analysis_events, EVENT_INTERBANK_REPAID)
    n_interbank_defaulted = count_events(analysis_events, EVENT_INTERBANK_DEFAULTED)
    n_interbank_matured = n_interbank_repaid + n_interbank_defaulted

    interbank_requested_principal = sum_event_column(analysis_events, EVENT_INTERBANK_REQUESTED, :principal)
    interbank_granted_principal = sum_event_column(analysis_events, EVENT_INTERBANK_GRANTED, :principal)
    interbank_repaid_amount = sum_event_column(analysis_events, EVENT_INTERBANK_REPAID, :repayment)
    interbank_defaulted_amount = sum_event_column(analysis_events, EVENT_INTERBANK_DEFAULTED, :repayment)
    interbank_matured_amount = interbank_repaid_amount + interbank_defaulted_amount

    start_net, end_net, bank_net_growth_ratio = bank_net_metrics(events, analysis_start_day, analysis_end_day)

    loan_acceptance_rate = safe_ratio(n_loan_granted, n_loan_requested)
    loan_volume_acceptance_rate = safe_ratio(granted_loan_principal, requested_loan_principal)
    deposit_repay_rate = safe_ratio(n_deposit_repaid, n_deposit_matured)
    deposit_volume_repay_rate = safe_ratio(deposit_repaid_amount, deposit_matured_amount)
    interbank_dependency_rate = safe_ratio(n_interbank_granted, n_loan_granted)
    interbank_volume_dependency_rate = safe_ratio(interbank_granted_principal, granted_loan_principal)
    interbank_request_rate = safe_ratio(n_interbank_requested, n_loan_requested)
    interbank_repay_rate = safe_ratio(n_interbank_repaid, n_interbank_matured)
    interbank_volume_repay_rate = safe_ratio(interbank_repaid_amount, interbank_matured_amount)
    liquidity_stress_rate = safe_ratio(n_loan_rejected, n_loan_requested)
    liquidity_stress_volume_rate = safe_ratio(rejected_loan_principal, requested_loan_principal)

    liquidity_score =
        0.30 * score_ratio(granted_loan_principal, requested_loan_principal; empty_score = 0.0) +
        0.25 * score_ratio(deposit_repaid_amount, deposit_matured_amount; empty_score = 1.0) +
        0.20 * clipped_bank_net_growth_score(bank_net_growth_ratio) +
        0.15 * score_ratio(interbank_repaid_amount, interbank_matured_amount; empty_score = 1.0) +
        0.10 * (1.0 - score_ratio(rejected_loan_principal, requested_loan_principal; empty_score = 0.0))

    return (
        run_id = run_id,
        analysis_start_day = analysis_start_day,
        analysis_end_day = analysis_end_day,
        n_client_loan_requests = n_loan_requested,
        n_client_loan_granted = n_loan_granted,
        n_client_loan_rejected = n_loan_rejected,
        requested_client_loan_principal = requested_loan_principal,
        granted_client_loan_principal = granted_loan_principal,
        rejected_client_loan_principal = rejected_loan_principal,
        n_deposits_repaid = n_deposit_repaid,
        n_deposits_defaulted = n_deposit_defaulted,
        deposit_repaid_amount = deposit_repaid_amount,
        deposit_defaulted_amount = deposit_defaulted_amount,
        n_interbank_loan_requests = n_interbank_requested,
        n_interbank_loan_granted = n_interbank_granted,
        n_interbank_loans_repaid = n_interbank_repaid,
        n_interbank_loans_defaulted = n_interbank_defaulted,
        interbank_requested_principal = interbank_requested_principal,
        interbank_granted_principal = interbank_granted_principal,
        interbank_repaid_amount = interbank_repaid_amount,
        interbank_defaulted_amount = interbank_defaulted_amount,
        total_analysis_start_banks_net = start_net,
        total_analysis_end_banks_net = end_net,
        total_initial_banks_net = start_net,
        total_final_banks_net = end_net,
        loan_acceptance_rate = loan_acceptance_rate,
        loan_volume_acceptance_rate = loan_volume_acceptance_rate,
        deposit_repay_rate = deposit_repay_rate,
        deposit_volume_repay_rate = deposit_volume_repay_rate,
        interbank_dependency_rate = interbank_dependency_rate,
        interbank_volume_dependency_rate = interbank_volume_dependency_rate,
        interbank_request_rate = interbank_request_rate,
        interbank_repay_rate = interbank_repay_rate,
        interbank_volume_repay_rate = interbank_volume_repay_rate,
        liquidity_stress_rate = liquidity_stress_rate,
        liquidity_stress_volume_rate = liquidity_stress_volume_rate,
        bank_net_growth_ratio = bank_net_growth_ratio,
        liquidity_score = liquidity_score
    )
end

function compute_metrics(
    events::DataFrame,
    runs::DataFrame;
    analysis_start_day::Int = ANALYSIS_START_DAY,
    analysis_end_day::Int = ANALYSIS_END_DAY
)::DataFrame
    metrics = DataFrame()

    for run_id in sort(unique(events.run_id))
        run_events = filter(:run_id => ==(run_id), events)
        push!(
            metrics,
            compute_run_metrics(
                run_id,
                run_events;
                analysis_start_day = analysis_start_day,
                analysis_end_day = analysis_end_day
            ),
            cols = :union
        )
    end

    return leftjoin(runs, metrics; on = :run_id)
end

function mean_or_missing(values)
    observed = collect(skipmissing(values))
    return isempty(observed) ? missing : mean(observed)
end

function summarize_metrics(metrics::DataFrame)::DataFrame
    metric_columns = [
        :loan_acceptance_rate,
        :loan_volume_acceptance_rate,
        :deposit_repay_rate,
        :deposit_volume_repay_rate,
        :interbank_dependency_rate,
        :interbank_volume_dependency_rate,
        :interbank_request_rate,
        :interbank_repay_rate,
        :interbank_volume_repay_rate,
        :liquidity_stress_rate,
        :liquidity_stress_volume_rate,
        :bank_net_growth_ratio,
        :liquidity_score
    ]

    grouped = groupby(metrics, [:NUM_BANKS, :MIN_RESERVES_FACTOR])
    summary = combine(grouped, metric_columns .=> mean_or_missing .=> metric_columns)

    if :analysis_start_day in Symbol.(names(metrics)) && :analysis_end_day in Symbol.(names(metrics))
        summary.analysis_start_day = fill(first(skipmissing(metrics.analysis_start_day)), nrow(summary))
        summary.analysis_end_day = fill(first(skipmissing(metrics.analysis_end_day)), nrow(summary))
    end

    return summary
end

function build_metrics(
    results_dir::String = RESULTS_DIR;
    analysis_start_day::Int = ANALYSIS_START_DAY,
    analysis_end_day::Int = ANALYSIS_END_DAY
)
    events_path = joinpath(results_dir, "events.csv")
    runs_path = joinpath(results_dir, "runs.csv")
    metrics_path = joinpath(results_dir, "metrics.csv")
    summary_path = joinpath(results_dir, "summary.csv")

    events = CSV.read(events_path, DataFrame)
    runs = CSV.read(runs_path, DataFrame)

    metrics = compute_metrics(
        events,
        runs;
        analysis_start_day = analysis_start_day,
        analysis_end_day = analysis_end_day
    )
    summary = summarize_metrics(metrics)

    CSV.write(metrics_path, metrics)
    CSV.write(summary_path, summary)

    println("Metrics saved to $(metrics_path)")
    println("Summary saved to $(summary_path)")

    return metrics, summary
end

if abspath(PROGRAM_FILE) == @__FILE__
    build_metrics()
end
