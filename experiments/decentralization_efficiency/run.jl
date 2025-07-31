using BankSim
using DataStructures
using DataFrames
using CSV
include("config.jl")
include("utils.jl")
using Random
#Random.seed!(RNG_SEED)

    # This experiment demonstrates that having multiple banks (instead of a single large one)
    # can improve liquidity and increase the likelihood of satisfying client demand for
    # deposits and loans.

    # Procedure:
    # - A fixed total reserve (e.g., 1,000,000) is evenly distributed among B banks.
    # - For each B in [1,10], we run the simulation N times (e.g., N = 5).
    # - In each simulation, we record the percentage of client loan requests that are accepted.
    # - The result is a plot showing the average acceptance rate of client loans 
    #   as a function of the number of banks in the system.
    # As an addition we compare results in different minimum reserve regime

function setup_simulation(
    NUM_BANKS::Int,
    TOTAL_INITIAL_RESERVES::Int,
    MIN_RESERVES_FACTOR::Float64,
    R_CLIENT_LOAN::Float64,
    R_BANK_LOAN::Float64,
    R_DEPOSIT::Float64,
    CLIENT_LOAN_AMOUNT_RANGE::Tuple{Int, Int},
    CLIENT_LOAN_TERMS::Vector{Int},
    CLIENT_LOAN_DEFAULT_PROB_RANGE::Tuple{Float64, Float64},
    CLIENT_LOAN_ARRIVAL_RATE::Float64,
    CLIENT_DEPOSIT_AMOUNT_RANGE::Tuple{Int, Int},
    CLIENT_DEPOSIT_TERMS::Vector{Int},
    CLIENT_DEPOSIT_ARRIVAL_RATE::Float64,
    INTERBANK_LOAN_TERM::Int,
    SIMULATION_DURATION_DAYS::Int
)::Simulation
    sim = create_simulation()
    reserve_split = generate_initial_reserves(TOTAL_INITIAL_RESERVES, NUM_BANKS)
    sim.interbank_loaning_term = INTERBANK_LOAN_TERM

    for reserve in reserve_split
        add_bank!(sim, reserve, MIN_RESERVES_FACTOR, R_CLIENT_LOAN, R_BANK_LOAN, R_DEPOSIT)
    end

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
    return sim
end

function run_single_simulation(
    NUM_BANKS::Int,
    TOTAL_INITIAL_RESERVES::Int,
    MIN_RESERVES_FACTOR::Float64,
    R_CLIENT_LOAN::Float64,
    R_BANK_LOAN::Float64,
    R_DEPOSIT::Float64,
    CLIENT_LOAN_AMOUNT_RANGE::Tuple{Int, Int},
    CLIENT_LOAN_TERMS::Vector{Int},
    CLIENT_LOAN_DEFAULT_PROB_RANGE::Tuple{Float64, Float64},
    CLIENT_LOAN_ARRIVAL_RATE::Float64,
    CLIENT_DEPOSIT_AMOUNT_RANGE::Tuple{Int, Int},
    CLIENT_DEPOSIT_TERMS::Vector{Int},
    CLIENT_DEPOSIT_ARRIVAL_RATE::Float64,
    INTERBANK_LOAN_TERM::Int,
    SIMULATION_DURATION_DAYS::Int
)
    sim = setup_simulation(
        NUM_BANKS,
        TOTAL_INITIAL_RESERVES,
        MIN_RESERVES_FACTOR,
        R_CLIENT_LOAN,
        R_BANK_LOAN,
        R_DEPOSIT,
        CLIENT_LOAN_AMOUNT_RANGE,
        CLIENT_LOAN_TERMS,
        CLIENT_LOAN_DEFAULT_PROB_RANGE,
        CLIENT_LOAN_ARRIVAL_RATE,
        CLIENT_DEPOSIT_AMOUNT_RANGE,
        CLIENT_DEPOSIT_TERMS,
        CLIENT_DEPOSIT_ARRIVAL_RATE,
        INTERBANK_LOAN_TERM,
        SIMULATION_DURATION_DAYS
    )

    log_bank_states!(sim)
    run_simulation!(sim)

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

    number_of_banks = [1,2,3,4,5,6,7,8,9,10]
    min_reserves = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
    averaging_n = 5

    for num_banks in number_of_banks
        for min_reserve in min_reserves
            for i in 1:averaging_n
                println("Running simulation with $num_banks banks and min reserve factor $min_reserve (run $i/$averaging_n)")
                result = run_single_simulation(
                    num_banks,
                    TOTAL_INITIAL_RESERVES,
                    min_reserve,
                    R_CLIENT_LOAN,
                    R_BANK_LOAN,
                    R_DEPOSIT,
                    CLIENT_LOAN_AMOUNT_RANGE,
                    CLIENT_LOAN_TERMS,
                    CLIENT_LOAN_DEFAULT_PROB_RANGE,
                    CLIENT_LOAN_ARRIVAL_RATE,
                    CLIENT_DEPOSIT_AMOUNT_RANGE,
                    CLIENT_DEPOSIT_TERMS,
                    CLIENT_DEPOSIT_ARRIVAL_RATE,
                    INTERBANK_LOAN_TERM,
                    SIMULATION_DURATION_DAYS
                )
                push!(results, result)

                if i % 20 == 0
                    CSV.write("results/decentralization_efficiency/results_tmp.csv", results)
                    println("Completed $i runs for $num_banks banks with min reserve factor $min_reserve")                  
                end
            end
        end
    end

    CSV.write("results/decentralization_efficiency/results.csv", results)
    println("Results saved to results.csv")
    println("Experiment completed.")
    println("Total number of runs: $(nrow(results))")

end

run_experiment()

