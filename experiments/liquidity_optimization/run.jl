using BankSim
using DataStructures
using DataFrames
using CSV
include("config.jl")
include("utils.jl")
using Random
using Serialization
Random.seed!(RNG_SEED)

function single_run(MIN_RESERVES_FACTOR, R_CLIENT_LOAN, R_BANK_LOAN, R_DEPOSIT, simulation_scheduled_events)

    sim = create_simulation()
    reserves_split = generate_initial_reserves(TOTAL_INITIAL_RESERVES, NUM_BANKS)
    sim.interbank_loaning_term = INTERBANK_LOAN_TERM
    for reserve in reserves_split
        add_bank!(sim, reserve, MIN_RESERVES_FACTOR, R_CLIENT_LOAN, R_BANK_LOAN, R_DEPOSIT)
    end

    sim.scheduled_events = simulation_scheduled_events 
    log_bank_states!(sim)
    run_simulation!(sim)
    #bank decisions 
    n_client_loan_requests = count(x -> x isa EventRequestClientLoan, sim.executed_events)
    n_client_loan_granted = count(x -> x isa EventGrantClientLoan, sim.executed_events)
    n_client_deposit_requests = count(x -> x isa EventRequestClientDeposit , sim.executed_events)
    n_client_deposit_granted = count(x -> x isa  EventGrantClientDeposit , sim.executed_events)
    n_interbank_loan_granted = count(x -> x isa EventGrantBankLoan, sim.executed_events)

    #loan statistics (repay_time cutoff at simulation duration)
    interbank_loans = sim.history_bank_loans
    interbank_loans = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, interbank_loans)

    client_loans = sim.history_client_loans
    client_loans = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, client_loans)

    client_deposits = sim.history_client_deposits
    client_deposits = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, client_deposits)

    defaulted_loans = filter(x -> x.is_defaulted, client_loans)
    defaulted_deposits = filter(x -> x.is_defaulted, client_deposits)
    defaulted_bank_loans = filter(x -> x.is_defaulted, interbank_loans)
    
    #bank states 
    bank_states = sim.history_banks
    bank_states = filter(row -> row.time <= SIMULATION_DURATION_DAYS, bank_states)

    total_initial_net = 0
    total_final_net = 0
    for (id, bank) in sim.banks
        bank_data = filter(row -> row.id == id, bank_states)
        total_initial_net += first(bank_data).reserves + first(bank_data).total_loan_assets - first(bank_data).total_liabilities
        total_final_net += last(bank_data).reserves + last(bank_data).total_loan_assets - last(bank_data).total_liabilities
    end

    return Dict(
        "RANDOM_SEED" => RNG_SEED,#
        "NUM_BANKS" => NUM_BANKS,#
        "TOTAL_INITIAL_RESERVES" => TOTAL_INITIAL_RESERVES,#
        "MIN_RESERVES_FACTOR" => MIN_RESERVES_FACTOR,#
        "R_CLIENT_LOAN" => R_CLIENT_LOAN,#
        "R_DEPOSIT" => R_DEPOSIT,#
        "R_BANK_LOAN" => R_BANK_LOAN,#
        "n_client_loan_requests" => n_client_loan_requests,#
        "n_client_loan_granted" => n_client_loan_granted,#
        "n_client_deposit_requests" => n_client_deposit_requests,#
        "n_client_deposit_granted" => n_client_deposit_granted,#
        "n_interbank_loan_granted" => n_interbank_loan_granted,#
        "n_client_loans" => length(client_loans),#
        "n_client_deposits" => length(client_deposits),#
        "n_interbank_loans" => length(interbank_loans),#
        "n_defaulted_loans" => length(defaulted_loans),#
        "n_defaulted_deposits" => length(defaulted_deposits),#
        "n_defaulted_bank_loans" => length(defaulted_bank_loans),#
        "total_initial_banks_net" => total_initial_net,#
        "total_final_banks_net" => total_final_net
    )
end

function run_experiment()

    # === simulation setup ===
    println("\nSimulation with $NUM_BANKS banks and total reserves: $TOTAL_INITIAL_RESERVES")
    sim = create_simulation()

    # === event scheduling as random process ===
    current_time_loan = 0
    while current_time_loan ≤ SIMULATION_DURATION_DAYS
        current_time_loan += rand(Poisson(1 / CLIENT_LOAN_ARRIVAL_RATE))
        if current_time_loan > SIMULATION_DURATION_DAYS
            break
        end
        bank_id = rand(1:NUM_BANKS)
        principal = rand(CLIENT_LOAN_AMOUNT_RANGE[1]:CLIENT_LOAN_AMOUNT_RANGE[2])
        term = rand(CLIENT_LOAN_TERMS)
        default_prob = rand(Uniform(CLIENT_LOAN_DEFAULT_PROB_RANGE...))
        event = EventRequestClientLoan(
            get_event_id!(sim),
            nothing,
            current_time_loan,
            nothing,
            bank_id,
            principal,
            term,
            default_prob
        )
        schedule_event!(sim, event)
    end

    current_time_deposit = 0
    while current_time_deposit ≤ SIMULATION_DURATION_DAYS
        current_time_deposit += rand(Poisson(1 / CLIENT_DEPOSIT_ARRIVAL_RATE))
        if current_time_deposit > SIMULATION_DURATION_DAYS
            break
        end
        bank_id = rand(1:NUM_BANKS)
        principal = rand(CLIENT_DEPOSIT_AMOUNT_RANGE[1]:CLIENT_DEPOSIT_AMOUNT_RANGE[2])
        term = rand(CLIENT_DEPOSIT_TERMS)
        event = EventRequestClientDeposit(
            get_event_id!(sim),
            nothing,
            current_time_deposit,
            nothing,
            bank_id,
            principal,
            term
        )
        schedule_event!(sim, event)
    end

    results = DataFrame(
        RANDOM_SEED = Int[],
        NUM_BANKS = Int[],
        TOTAL_INITIAL_RESERVES = Int[],
        MIN_RESERVES_FACTOR = Float64[],
        R_CLIENT_LOAN = Float64[],
        R_DEPOSIT = Float64[],
        R_BANK_LOAN = Float64[],
        n_client_loan_requests = Int[],
        n_client_loan_granted = Int[],
        n_client_deposit_requests = Int[],
        n_client_deposit_granted = Int[],
        n_interbank_loan_granted = Int[],
        n_client_loans = Int[],
        n_client_deposits = Int[],
        n_interbank_loans = Int[],
        n_defaulted_loans = Int[],
        n_defaulted_deposits = Int[],
        n_defaulted_bank_loans = Int[],
        total_initial_banks_net = Float64[],
        total_final_banks_net = Float64[]
    )

    total_n_of_runs = length(V_MIN_RESERVES_FACTOR) * length(V_R_CLIENT_LOAN) * length(V_R_DEPOSIT) * length(V_R_BANK_LOAN)
    run_counter = 0
    for MIN_RESERVES_FACTOR in V_MIN_RESERVES_FACTOR
        for R_CLIENT_LOAN in V_R_CLIENT_LOAN
            for R_DEPOSIT in V_R_DEPOSIT
                for R_BANK_LOAN in V_R_BANK_LOAN

                    base_events = deepcopy(sim.scheduled_events)
                    result = single_run(MIN_RESERVES_FACTOR, R_CLIENT_LOAN, R_BANK_LOAN, R_DEPOSIT, base_events)
                    push!(results, result)
                    run_counter += 1
                    if run_counter % 20 == 0
                        CSV.write("results/liquidity_optimization/results_tmp.csv", results)
                        println("Temporary results saved to results_tmp.csv after $run_counter runs.")
                    end
                    println("Run $run_counter of $total_n_of_runs completed.")
                    
                end
            end
        end
    end

    CSV.write("results/liquidity_optimization/results.csv", results)
    println("Results saved to results.csv")
    println("Experiment completed.")
    println("Total number of runs: $(nrow(results))")

end

run_experiment()

