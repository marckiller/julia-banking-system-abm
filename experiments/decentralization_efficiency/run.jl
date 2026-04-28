using BankSim
using DataFrames
using CSV
using Random

include("config.jl")
include("utils.jl")
include("scenario.jl")
include("metrics.jl")

function setup_simulation(
    num_banks::Int,
    total_initial_reserves::Int,
    min_reserves_factor::Float64,
    r_client_loan::Float64,
    r_bank_loan::Float64,
    r_deposit::Float64,
    interbank_loan_term::Int,
    scenario::Vector{DemandRequest},
    run_seed::Int
)::Simulation
    Random.seed!(run_seed)

    sim = create_simulation()
    sim.interbank_loaning_term = interbank_loan_term

    for reserve in generate_initial_reserves(total_initial_reserves, num_banks)
        add_bank!(sim, reserve, min_reserves_factor, r_client_loan, r_bank_loan, r_deposit)
    end

    route_scenario!(sim, scenario, num_banks)
    return sim
end

function run_metadata(
    run_id::Int,
    replication_id::Int,
    scenario_seed::Int,
    run_seed::Int,
    num_banks::Int,
    min_reserves_factor::Float64
)
    return (
        run_id = run_id,
        replication_id = replication_id,
        scenario_seed = scenario_seed,
        run_seed = run_seed,
        NUM_BANKS = num_banks,
        MIN_RESERVES_FACTOR = min_reserves_factor
    )
end

function should_save_events(run_id::Int, save_events::Bool, save_event_run_ids::Vector{Int})::Bool
    return save_events && (isempty(save_event_run_ids) || run_id in save_event_run_ids)
end

function save_run_events(run_id::Int, events::DataFrame, events_dir::String)
    mkpath(events_dir)
    path = joinpath(events_dir, "run_$(lpad(string(run_id), 6, '0')).csv")
    CSV.write(path, events)
end

function events_dataframe(run_id::Int, events::Vector{AbstractEvent})::DataFrame
    flattened = map(flatten_event, events)
    for event in flattened
        event[:run_id] = run_id
    end
    return flattened_events_to_dataframe(flattened)
end

function run_seed(replication_id::Int, num_banks::Int, min_reserve_index::Int)::Int
    return RUN_SEED_BASE + 10_000 * replication_id + 100 * num_banks + min_reserve_index
end

function run_experiment(;
    results_dir::String = RESULTS_DIR,
    events_dir::String = joinpath(results_dir, "events"),
    averaging_n::Int = AVERAGING_N,
    number_of_banks::Vector{Int} = NUMBER_OF_BANKS,
    min_reserves_factors::Vector{Float64} = MIN_RESERVES_FACTORS,
    simulation_duration_days::Int = SIMULATION_DURATION_DAYS,
    analysis_start_day::Int = ANALYSIS_START_DAY,
    analysis_end_day::Int = ANALYSIS_END_DAY,
    client_loan_requests_per_day::Float64 = CLIENT_LOAN_REQUESTS_PER_DAY,
    client_deposit_requests_per_day::Float64 = CLIENT_DEPOSIT_REQUESTS_PER_DAY,
    save_events::Bool = SAVE_EVENTS,
    save_event_run_ids::Vector{Int} = SAVE_EVENT_RUN_IDS
)
    mkpath(results_dir)

    runs = DataFrame()
    metrics = DataFrame()

    run_id = 1
    total_runs = averaging_n * length(number_of_banks) * length(min_reserves_factors)
    println("Analysis window: days $(analysis_start_day)-$(analysis_end_day)")

    for replication_id in 1:averaging_n
        scenario_seed = SCENARIO_SEED_BASE + replication_id
        scenario = generate_demand_scenario(
            scenario_seed,
            simulation_duration_days,
            CLIENT_LOAN_AMOUNT_RANGE,
            CLIENT_LOAN_TERMS,
            CLIENT_LOAN_DEFAULT_PROB_RANGE,
            client_loan_requests_per_day,
            CLIENT_DEPOSIT_AMOUNT_RANGE,
            CLIENT_DEPOSIT_TERMS,
            client_deposit_requests_per_day
        )

        for num_banks in number_of_banks
            for (min_reserve_index, min_reserve) in enumerate(min_reserves_factors)
                current_run_seed = run_seed(replication_id, num_banks, min_reserve_index)
                println(
                    "Running $run_id/$total_runs: replication=$replication_id, " *
                    "banks=$num_banks, min_reserve=$min_reserve, " *
                    "scenario_seed=$scenario_seed, run_seed=$current_run_seed"
                )

                sim = setup_simulation(
                    num_banks,
                    TOTAL_INITIAL_RESERVES,
                    min_reserve,
                    R_CLIENT_LOAN,
                    R_BANK_LOAN,
                    R_DEPOSIT,
                    INTERBANK_LOAN_TERM,
                    scenario,
                    current_run_seed
                )

                log_bank_states!(sim)
                run_simulation!(sim)

                metadata = run_metadata(run_id, replication_id, scenario_seed, current_run_seed, num_banks, min_reserve)
                run_events = events_dataframe(run_id, sim.event_log)
                run_metrics = compute_run_metrics(
                    run_id,
                    run_events;
                    analysis_start_day = analysis_start_day,
                    analysis_end_day = analysis_end_day
                )

                push!(
                    runs,
                    metadata,
                    cols = :union
                )

                push!(metrics, merge(metadata, run_metrics), cols = :union)

                if should_save_events(run_id, save_events, save_event_run_ids)
                    save_run_events(run_id, run_events, events_dir)
                end

                if run_id % 20 == 0
                    CSV.write(joinpath(results_dir, "metrics_tmp.csv"), metrics)
                    CSV.write(joinpath(results_dir, "runs_tmp.csv"), runs)
                end

                run_id += 1
            end
        end
    end

    summary = summarize_metrics(metrics)

    CSV.write(joinpath(results_dir, "metrics.csv"), metrics)
    CSV.write(joinpath(results_dir, "summary.csv"), summary)
    CSV.write(joinpath(results_dir, "runs.csv"), runs)

    println("Experiment completed.")
    println("Results saved to $(results_dir)")
    println("Total number of runs: $(nrow(metrics))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_experiment()
end
