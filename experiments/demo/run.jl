using CSV
using DataFrames

include(joinpath(@__DIR__, "..", "decentralization_efficiency", "run.jl"))
include(joinpath(@__DIR__, "config.jl"))
include(joinpath(@__DIR__, "analysis.jl"))
include(joinpath(@__DIR__, "plots.jl"))
include(joinpath(@__DIR__, "report.jl"))

const DEMO_RESULTS_DIR = "results/demo"
const DEMO_PLOTS_DIR = joinpath(DEMO_RESULTS_DIR, "plots")

function build_demo_scenario()
    return generate_demand_scenario(
        DEMO_SCENARIO_SEED,
        DEMO_DURATION_DAYS,
        CLIENT_LOAN_AMOUNT_RANGE,
        DEMO_CLIENT_LOAN_TERMS,
        DEMO_CLIENT_LOAN_DEFAULT_PROB_RANGE,
        DEMO_CLIENT_LOAN_REQUESTS_PER_DAY,
        CLIENT_DEPOSIT_AMOUNT_RANGE,
        DEMO_CLIENT_DEPOSIT_TERMS,
        DEMO_CLIENT_DEPOSIT_REQUESTS_PER_DAY
    )
end

function build_demo_simulation(scenario)
    return setup_simulation(
        DEMO_NUM_BANKS,
        DEMO_TOTAL_INITIAL_RESERVES,
        DEMO_MIN_RESERVES_FACTOR,
        R_CLIENT_LOAN,
        R_BANK_LOAN,
        R_DEPOSIT,
        INTERBANK_LOAN_TERM,
        scenario,
        DEMO_RUN_SEED
    )
end

function demo_bank_states(sim)
    bank_states = copy(sim.history_banks)
    bank_states.net_worth = [bank_net_worth(row) for row in eachrow(bank_states)]
    return bank_states
end

function write_demo_outputs(events::DataFrame, bank_states::DataFrame, metrics::DataFrame)
    mkpath(DEMO_RESULTS_DIR)

    CSV.write(joinpath(DEMO_RESULTS_DIR, "events.csv"), events)
    CSV.write(joinpath(DEMO_RESULTS_DIR, "bank_states.csv"), bank_states)
    CSV.write(joinpath(DEMO_RESULTS_DIR, "metrics.csv"), metrics)
end

function run_demo()
    if isdir(DEMO_RESULTS_DIR)
        rm(DEMO_RESULTS_DIR; recursive = true, force = true)
    end

    mkpath(DEMO_PLOTS_DIR)

    scenario = build_demo_scenario()
    sim = build_demo_simulation(scenario)

    println("Running single-scenario demo...")
    println("banks=$(DEMO_NUM_BANKS), min_reserve=$(DEMO_MIN_RESERVES_FACTOR), scenario_seed=$(DEMO_SCENARIO_SEED), run_seed=$(DEMO_RUN_SEED)")

    log_bank_states!(sim)
    run_simulation!(sim)

    events = events_dataframe(1, sim.event_log)
    metrics = DataFrame([compute_run_metrics(1, events)])
    bank_states = demo_bank_states(sim)

    write_demo_outputs(events, bank_states, metrics)
    save_demo_plots(events, bank_states, DEMO_PLOTS_DIR)

    println("Demo completed.")
    println("Events: $(joinpath(DEMO_RESULTS_DIR, "events.csv"))")
    println("Bank states: $(joinpath(DEMO_RESULTS_DIR, "bank_states.csv"))")
    println("Metrics: $(joinpath(DEMO_RESULTS_DIR, "metrics.csv"))")
    println("Plots: $(joinpath(DEMO_PLOTS_DIR, "index.html"))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_demo()
end
