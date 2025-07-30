using BankSim
using DataStructures
using DataFrames
using CSV
using Dates

include("config.jl")
include("utils.jl")

using Random
Random.seed!(RNG_SEED)

function run_experiment()

    MIN_RESERVES_FACTOR = 0.3
    R_CLIENT_LOAN = 0.20
    R_BANK_LOAN = 0.04
    R_DEPOSIT = 0.03
    
    # === simulation setup ===
    println("\nSimulation with $NUM_BANKS banks and total reserves: $TOTAL_INITIAL_RESERVES")
    reserves_split = generate_initial_reserves(TOTAL_INITIAL_RESERVES, NUM_BANKS)
    sim = create_simulation()
    sim.interbank_loaning_term = INTERBANK_LOAN_TERM
    for reserve in reserves_split
        add_bank!(sim, reserve, MIN_RESERVES_FACTOR, R_CLIENT_LOAN, R_BANK_LOAN, R_DEPOSIT)
    end
    println("$(length(sim.banks)) banks created.")

    # === event scheduling as random process ===
    scheduling_start = now()
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
    scheduling_end = now()
    # === simulation execution ===

    log_bank_states!(sim)
    println("Initial bank states logged.")

    sim_start = now()
    run_simulation!(sim)
    sim_end = now()
    # ==== quick analysis of simulation results===

    println()
    println("=== LIQUIDITY SUMMARY ===")
    analysis_start = now()
    #count all event of type EventRequestClientLoan
    n_client_loan_requests = count(x -> x isa EventRequestClientLoan, sim.executed_events)
    n_client_loan_granted = count(x -> x isa EventGrantClientLoan, sim.executed_events)

    n_client_deposit_requests = count(x -> x isa EventRequestClientDeposit , sim.executed_events)
    n_client_deposit_granted = count(x -> x isa  EventGrantClientDeposit , sim.executed_events) #rules are set to always accept deposits

    n_bank_loan_requests = count(x -> x isa EventGrantBankLoan, sim.executed_events)

    println("LOANS ACCEPTANCE: $(n_client_loan_granted)/$(n_client_loan_requests) ($(round(100 * n_client_loan_granted / max(n_client_loan_requests, 1), digits=2))%)")
    println("DEPOSITS ACCEPTANCE: $(n_client_deposit_granted)/$(n_client_deposit_requests) ($(round(100 * n_client_deposit_granted / max(n_client_deposit_requests, 1), digits=2))%)")
    
    interbank_loans = sim.history_bank_loans
    interbank_loans = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, interbank_loans)

    client_loans = sim.history_client_loans
    client_loans = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, client_loans)

    client_deposits = sim.history_client_deposits
    client_deposits = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, client_deposits)

    println()
    println("=== DEFAULTS SUMMARY ===")

    # Client Loans
    defaulted_loans = filter(x -> x.is_defaulted, client_loans)
    println("DEFAULTED LOANS: $(length(defaulted_loans))/$(length(client_loans)) ($(round(100 * length(defaulted_loans) / max(length(client_loans), 1), digits=2))%)")

    # Client Deposits
    defaulted_deposits = filter(x -> x.is_defaulted, client_deposits)
    println("DEFAULTED DEPOSITS: $(length(defaulted_deposits))/$(length(client_deposits)) ($(round(100 * length(defaulted_deposits) / max(length(client_deposits), 1), digits=2))%)")

    # Interbank Loans
    defaulted_bank_loans = filter(x -> x.is_defaulted, interbank_loans)
    println("DEFAULTED INTERBANK LOANS: $(length(defaulted_bank_loans))/$(length(interbank_loans)) ($(round(100 * length(defaulted_bank_loans) / max(length(interbank_loans), 1), digits=2))%)")
    println()

    #final bank states
    bank_states = sim.history_banks
    bank_states = filter(row -> row.time <= SIMULATION_DURATION_DAYS, bank_states)
    println("=== BANKS FINAL NET WEALTH (at time $(SIMULATION_DURATION_DAYS)) ===")
    pct_reserve_change = 0
    for (id, bank) in sim.banks
        bank_data = filter(row -> row.id == id, bank_states)
        initial = first(bank_data).reserves + first(bank_data).total_loan_assets - first(bank_data).total_liabilities
        final = last(bank_data).reserves + last(bank_data).total_loan_assets - last(bank_data).total_liabilities
        delta_pct = round(100 * (final - initial) / initial, digits=2)
        pct_reserve_change += delta_pct
        println("  Bank $id: $initial → $final  ($delta_pct%)")
    end

    # Calculate average net wealth change across all banks
    avg_reserve_change = pct_reserve_change / length(sim.banks)
    println("\n=== BANKS AVERAGE NET WEALTH CHANGE ===")
    println("Average net wealth change: $avg_reserve_change%\n")
    analysis_end = now()

    # === simulation summary ===
    println("\n=== SIMULATION SUMMARY ===")
    println("Simulation duration: $((sim_end - sim_start).value / 1000) seconds")
    println("Event scheduling duration: $((scheduling_end - scheduling_start).value / 1000) seconds")
    println("Analysis duration: $((analysis_end - analysis_start).value / 1000) seconds")
    println("Total simulation duration: $(((sim_end - sim_start) + (analysis_end - analysis_start)).value / 1000) seconds")

end

run_experiment()