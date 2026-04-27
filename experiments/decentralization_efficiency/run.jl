using BankSim
using DataFrames
using CSV
using Random

include("config.jl")
include("utils.jl")
include("scenario.jl")

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

function total_bank_net(bank_state)
    return bank_state.reserves + bank_state.total_loan_assets - bank_state.total_liabilities
end

function summarize_simulation(
    sim::Simulation,
    run_id::Int,
    replication_id::Int,
    scenario_seed::Int,
    run_seed::Int,
    num_banks::Int,
    total_initial_reserves::Int,
    min_reserves_factor::Float64,
    r_client_loan::Float64,
    r_bank_loan::Float64,
    r_deposit::Float64,
    simulation_duration_days::Int
)
    event_log = sim.event_log

    n_client_loan_requests = count(x -> x isa EventRequestClientLoan, event_log)
    n_client_loan_granted = count(x -> x isa EventGrantClientLoan, event_log)
    n_client_deposit_requests = count(x -> x isa EventRequestClientDeposit, event_log)
    n_client_deposit_granted = count(x -> x isa EventGrantClientDeposit, event_log)
    n_interbank_loan_granted = count(x -> x isa EventGrantBankLoan, event_log)

    interbank_loans = filter(x -> x.time_repay <= simulation_duration_days, sim.history_bank_loans)
    client_loans = filter(x -> x.time_repay <= simulation_duration_days, sim.history_client_loans)
    client_deposits = filter(x -> x.time_repay <= simulation_duration_days, sim.history_client_deposits)

    bank_states = filter(row -> row.time <= simulation_duration_days, sim.history_banks)

    total_initial_net = 0
    total_final_net = 0
    for id in keys(sim.banks)
        bank_data = filter(row -> row.id == id, bank_states)
        total_initial_net += total_bank_net(first(bank_data))
        total_final_net += total_bank_net(last(bank_data))
    end

    return (
        run_id = run_id,
        replication_id = replication_id,
        scenario_seed = scenario_seed,
        run_seed = run_seed,
        NUM_BANKS = num_banks,
        TOTAL_INITIAL_RESERVES = total_initial_reserves,
        MIN_RESERVES_FACTOR = min_reserves_factor,
        R_CLIENT_LOAN = r_client_loan,
        R_DEPOSIT = r_deposit,
        R_BANK_LOAN = r_bank_loan,
        n_client_loan_requests = n_client_loan_requests,
        n_client_loan_granted = n_client_loan_granted,
        n_client_deposit_requests = n_client_deposit_requests,
        n_client_deposit_granted = n_client_deposit_granted,
        n_interbank_loan_granted = n_interbank_loan_granted,
        n_client_loans = length(client_loans),
        n_client_deposits = length(client_deposits),
        n_interbank_loans = length(interbank_loans),
        n_defaulted_loans = count(x -> x.is_defaulted, client_loans),
        n_defaulted_deposits = count(x -> x.is_defaulted, client_deposits),
        n_defaulted_bank_loans = count(x -> x.is_defaulted, interbank_loans),
        total_initial_banks_net = total_initial_net,
        total_final_banks_net = total_final_net
    )
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

function run_experiment()
    mkpath(RESULTS_DIR)

    results = DataFrame()
    runs = DataFrame()
    events = DataFrame()

    run_id = 1
    total_runs = AVERAGING_N * length(NUMBER_OF_BANKS) * length(MIN_RESERVES_FACTORS)

    for replication_id in 1:AVERAGING_N
        scenario_seed = SCENARIO_SEED_BASE + replication_id
        scenario = generate_demand_scenario(
            scenario_seed,
            SIMULATION_DURATION_DAYS,
            CLIENT_LOAN_AMOUNT_RANGE,
            CLIENT_LOAN_TERMS,
            CLIENT_LOAN_DEFAULT_PROB_RANGE,
            CLIENT_LOAN_REQUESTS_PER_DAY,
            CLIENT_DEPOSIT_AMOUNT_RANGE,
            CLIENT_DEPOSIT_TERMS,
            CLIENT_DEPOSIT_REQUESTS_PER_DAY
        )

        for num_banks in NUMBER_OF_BANKS
            for (min_reserve_index, min_reserve) in enumerate(MIN_RESERVES_FACTORS)
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

                push!(
                    results,
                    summarize_simulation(
                        sim,
                        run_id,
                        replication_id,
                        scenario_seed,
                        current_run_seed,
                        num_banks,
                        TOTAL_INITIAL_RESERVES,
                        min_reserve,
                        R_CLIENT_LOAN,
                        R_BANK_LOAN,
                        R_DEPOSIT,
                        SIMULATION_DURATION_DAYS
                    ),
                    cols = :union
                )

                push!(
                    runs,
                    run_metadata(run_id, replication_id, scenario_seed, current_run_seed, num_banks, min_reserve),
                    cols = :union
                )

                events = vcat(events, events_dataframe(run_id, sim.event_log); cols = :union)

                if run_id % 20 == 0
                    CSV.write(joinpath(RESULTS_DIR, "results_tmp.csv"), results)
                    CSV.write(joinpath(RESULTS_DIR, "runs_tmp.csv"), runs)
                end

                run_id += 1
            end
        end
    end

    CSV.write(joinpath(RESULTS_DIR, "results.csv"), results)
    CSV.write(joinpath(RESULTS_DIR, "runs.csv"), runs)
    CSV.write(joinpath(RESULTS_DIR, "events.csv"), events)

    println("Experiment completed.")
    println("Results saved to $(RESULTS_DIR)")
    println("Total number of runs: $(nrow(results))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_experiment()
end
