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
    sim.interbank_loaning_term = INTERBANK_LOAN_TERM
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

    # compute default stats before summary
    interbank_loans = sim.history_bank_loans
    defaulted_loans = count(loan -> loan.is_defaulted, interbank_loans)
    fraction_defaulted = length(interbank_loans) > 0 ? defaulted_loans / length(interbank_loans) : 0.0

    deposits = sim.history_client_deposits
    defaulted_deposits = count(deposit -> deposit.is_defaulted, deposits)
    fraction_defaulted_deposits = length(deposits) > 0 ? defaulted_deposits / length(deposits) : 0.0

    event_history = sim.executed_events
    total_loan_requests = count(event -> event isa EventRequestClientLoan, event_history)
    total_approved_loans = count(event -> event isa EventGrantClientLoan, event_history)
    approval_ratio = total_loan_requests > 0 ? total_approved_loans / total_loan_requests : 0.0

    total_bank_loan_requests = count(event -> event isa EventRequestBankLoan, event_history)
    total_approved_bank_loans = count(event -> event isa EventGrantBankLoan, event_history)
    bank_approval_ratio = total_bank_loan_requests > 0 ? total_approved_bank_loans / total_bank_loan_requests : 0.0

    total_loan_volume = sum(event.principal for event in event_history if event isa EventGrantClientLoan)
    total_days = maximum([event.time for event in event_history if event isa EventGrantClientLoan]; init=1)
    average_daily_loan_volume = total_loan_volume / total_days

    total_deposit_volume = sum(event.principal for event in event_history if event isa EventGrantClientDeposit)
    total_deposit_days = maximum([event.time for event in event_history if event isa EventGrantClientDeposit]; init=1)
    average_daily_deposit_volume = total_deposit_volume / total_deposit_days

    println("\n======= Summary =======")
    println("interbank defaulted loans: $defaulted_loans / $(length(interbank_loans)) ($(round(100 * fraction_defaulted, digits=2))%)")
    println("client defaulted deposits: $defaulted_deposits / $(length(deposits)) ($(round(100 * fraction_defaulted_deposits, digits=2))%)")
    println("client loan approval: $total_approved_loans / $total_loan_requests ($(round(100 * approval_ratio, digits=2))%)")
    println("bank loan approval: $total_approved_bank_loans / $total_bank_loan_requests ($(round(100 * bank_approval_ratio, digits=2))%)")
    println("avg daily loan volume: $(round(average_daily_loan_volume, digits=2))")
    println("avg daily deposit volume: $(round(average_daily_deposit_volume, digits=2))")

    println("\nbreached reserve days per bank:")
    for bank in values(sim.banks)
        bank_data = filter(row -> row.id == bank.id, sim.history_banks)
        bank_data.min_abs_reserve = bank_data.min_reserves .* bank_data.total_liabilities
        breached = bank_data[bank_data.reserves .< bank_data.min_abs_reserve, :]
        unique_breached_days = unique(breached.time)
        println("  Bank $(bank.id): $(length(unique_breached_days)) days")
    end

    println("\nreserve change summary:")
    for (id, bank) in sim.banks
        bank_data = filter(row -> row.id == id, sim.history_banks)
        initial = first(bank_data).reserves
        final = last(bank_data).reserves
        delta_pct = round(100 * (final - initial) / initial, digits=2)
        println("  Bank $id: $initial → $final  ($delta_pct%)")
    end

end

run_experiment()