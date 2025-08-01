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

    println("\n=== SIMULATION CONFIGURATION ===")
    for bank in banks
        println("Bank $(bank["id"]): reserves=$(bank["reserves"]), min_reserves factor=$(bank["min_reserves_factor"]), r_client_loan=$(bank["r_client_loan"]), r_bank_loan=$(bank["r_bank_loan"]), r_deposit=$(bank["r_deposit"])")
    end

    println("Simulation loans/deposit request generation: $(SIMULATION_DURATION_DAYS) days")
    println("Simulation interbank loaning term: $(INTERBANK_LOAN_TERM) days")
    println("Client loans arrival rate: $(CLIENT_LOAN_ARRIVAL_RATE) requests/day")
    println("Loans varies from $(CLIENT_LOAN_AMOUNT_RANGE[1]) to $(CLIENT_LOAN_AMOUNT_RANGE[2]) with terms: $(CLIENT_LOAN_TERMS) days and default probability range: $(CLIENT_LOAN_DEFAULT_PROB_RANGE)")
    println("Deposits arrival rate: $(CLIENT_DEPOSIT_ARRIVAL_RATE) requests/day")
    println("Deposits varies from $(CLIENT_DEPOSIT_AMOUNT_RANGE[1]) to $(CLIENT_DEPOSIT_AMOUNT_RANGE[2]) with terms: $(CLIENT_DEPOSIT_TERMS) days")


    # === simulation setup ===
    simulation = create_simulation()
    simulation.interbank_loaning_term = INTERBANK_LOAN_TERM
    for bank in banks
        add_bank!(simulation, bank["reserves"], bank["min_reserves_factor"], bank["r_client_loan"], bank["r_bank_loan"], bank["r_deposit"])
    end

    # === scheduling pre-generated random Events === 
    schedule_random_loan_requests!(
        simulation,
        CLIENT_LOAN_ARRIVAL_RATE,
        CLIENT_LOAN_AMOUNT_RANGE,
        CLIENT_LOAN_TERMS,
        CLIENT_LOAN_DEFAULT_PROB_RANGE,
        SIMULATION_DURATION_DAYS
    )
    schedule_random_deposit_requests!(
        simulation,
        CLIENT_DEPOSIT_ARRIVAL_RATE,
        CLIENT_DEPOSIT_AMOUNT_RANGE,
        CLIENT_DEPOSIT_TERMS,
        SIMULATION_DURATION_DAYS
    )

    # === simulation run ===
    println("\n === RUNNING SIMULATION ===")
    println("simulation running...")
    log_bank_states!(simulation)
    run_simulation!(simulation)
    println("Simulation finished.")

    
    # analysis and output
    println("\n=== SIMULATION RESULTS ===")
    cutoff_time = SIMULATION_DURATION_DAYS
    println("Simulation time: $(cutoff_time) days ($(simulation.time) days all loans repayment).")

    # === loans acceptance ===
    n_client_loan_requests = count(x -> x isa EventRequestClientLoan, simulation.executed_events)
    n_client_loan_granted = count(x -> x isa EventGrantClientLoan, simulation.executed_events)
    println("Client loan requests: $n_client_loan_requests, granted: $n_client_loan_granted, acceptance rate: $(n_client_loan_granted / n_client_loan_requests * 100)%")

    # === deposits acceptance ===
    n_client_deposit_requests = count(x -> x isa EventRequestClientDeposit , simulation.executed_events)
    n_client_deposit_granted = count(x -> x isa  EventGrantClientDeposit , simulation.executed_events)
    println("Client deposit requests: $n_client_deposit_requests, granted: $n_client_deposit_granted, acceptance rate: $(n_client_deposit_granted / n_client_deposit_requests * 100)%")

    # === interbank loans ===
    # in curent version bank always check availability of interbank loans and requests 
    # them only if they can be granted.
    n_bank_loan_granted = count(x -> x isa EventRequestBankLoan, simulation.executed_events)
    println("Interbank loans: $n_bank_loan_granted")

    # === liquidity summary (cutoff to active simulation time) ===

    interbank_loans = simulation.history_bank_loans
    interbank_loans = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, interbank_loans)

    client_loans = simulation.history_client_loans
    client_loans = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, client_loans)

    client_deposits = simulation.history_client_deposits
    client_deposits = filter(x -> x.time_repay <= SIMULATION_DURATION_DAYS, client_deposits)
    # Client Loans
    defaulted_loans = filter(x -> x.is_defaulted, client_loans)
    println("Defaulted loans (active simulation time only): $(length(defaulted_loans))/$(length(client_loans)) ($(round(100 * length(defaulted_loans) / max(length(client_loans), 1), digits=2))%)")
    # Client Deposits
    defaulted_deposits = filter(x -> x.is_defaulted, client_deposits)
    println("Defaulted deposits (active simulation time only): $(length(defaulted_deposits))/$(length(client_deposits)) ($(round(100 * length(defaulted_deposits) / max(length(client_deposits), 1), digits=2))%)")
    # Interbank Loans
    defaulted_bank_loans = filter(x -> x.is_defaulted, interbank_loans)
    println("Defaulted interbank loans (active simulation time only): $(length(defaulted_bank_loans))/$(length(interbank_loans)) ($(round(100 * length(defaulted_bank_loans) / max(length(interbank_loans), 1), digits=2))%)")
    println()

    # === bank states at the end of simulation ===
    bank_states = simulation.history_banks
    bank_states = filter(row -> row.time <= SIMULATION_DURATION_DAYS, bank_states)
    println("=== BANKS FINAL NET WEALTH (at time $(SIMULATION_DURATION_DAYS)) ===")
    pct_reserve_change = 0
    for (id, bank) in simulation.banks
        bank_data = filter(row -> row.id == id, bank_states)
        initial = first(bank_data).reserves + first(bank_data).total_loan_assets - first(bank_data).total_liabilities
        final = last(bank_data).reserves + last(bank_data).total_loan_assets - last(bank_data).total_liabilities
        delta_pct = round(100 * (final - initial) / initial, digits=2)
        pct_reserve_change += delta_pct
        println("  Bank $id: $initial → $final  ($delta_pct%)")
    end
end

run_experiment()