using BankSim
using DataStructures
using DataFrames
using CSV
include("config.jl")
include("utils.jl")
using Random
Random.seed!(RNG_SEED)

function run_experiment()

    println("Simulation with $NUM_BANKS banks and total reserves: $TOTAL_INITIAL_RESERVES")

    reserves_split = generate_initial_reserves(TOTAL_INITIAL_RESERVES, NUM_BANKS, MIN_INITIAL_RESERVES)
    sim = create_simulation()
    for reserve in reserves_split
        add_bank!(sim, reserve, MIN_RESERVES_FACTOR, R_CLIENT_LOAN, R_BANK_LOAN, R_DEPOSIT)
    end

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

    log_bank_states!(sim)
    println("Initial bank states logged.")
    run_simulation!(sim)

    println("Simulation completed. Final bank states:")
    for (id, bank) in sim.banks
        println("Bank ID: $id, Reserves: $(bank.reserves), Total Liabilities: $(bank.total_liabilities), Total Loan Assets: $(bank.total_loan_assets)")
    end

    #save results to CSV
    CSV.write("bank_states.csv", sim.history_banks)
    println("Bank states saved to bank_states.csv")
    #CSV.write("executed_events.csv", DataFrame(sim.executed_events))
    #println("Executed events saved to executed_events.csv")

end

run_experiment()