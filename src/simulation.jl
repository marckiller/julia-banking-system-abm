using DataStructures
using DataFrames

mutable struct Simulation

    #counters 
    next_event_id::Int
    next_bank_id::Int
    next_loan_id::Int
    #customers are not used in curent version of simulation
    #next_customer_id::Int 

    time::Int
    banks::Dict{Int, Bank}
    client_loans::Dict{Int, Loan}
    bank_loans::Dict{Int, Loan}
    client_deposits::Dict{Int, Loan}
    
    scheduled_events::PriorityQueue{AbstractEvent, Int}
    executed_events::Vector{AbstractEvent}

    #bankin system parameters
    interbank_loaning_term::Int

    #simulation history
    history_client_loans::Vector{Loan}
    history_bank_loans::Vector{Loan}
    history_client_deposits::Vector{Loan}
    history_banks::DataFrame

end

function schedule_event!(simulation::Simulation, event::AbstractEvent)
    enqueue!(simulation.scheduled_events, event => event.time)
end

function execute_event!(simulation::Simulation, event::AbstractEvent)
    simulation.time = event.time
    handle_event!(simulation, event)
    if event isa EventRepaymentClientLoan
        loan = pop!(simulation.client_loans, event.loan_id)
        push!(simulation.history_client_loans, loan)
    elseif event isa EventRepaymentBankLoan
        loan = pop!(simulation.bank_loans, event.loan_id)
        push!(simulation.history_bank_loans, loan)
    elseif event isa EventRepaymentDeposit
        deposit = pop!(simulation.client_deposits, event.deposit_id)
        push!(simulation.history_client_deposits, deposit)
    end
    push!(simulation.executed_events, event)
end

function run!(simulation::Simulation)
    while !isempty(simulation.scheduled_events)
        event = dequeue!(simulation.scheduled_events)
        simulation.time = max(simulation.time, event.time)
        execute_event!(simulation, event)
        log_bank_states!(simulation)
    end

end

function get_event_id!(sim::Simulation)
    id = sim.next_event_id
    sim.next_event_id += 1
    return id
end

function get_bank_id!(sim::Simulation)
    id = sim.next_bank_id
    sim.next_bank_id += 1
    return id
end

function get_loan_id!(sim::Simulation)
    id = sim.next_loan_id
    sim.next_loan_id += 1
    return id
end

function create_simulation(
    banks::Dict{Int, Bank} = Dict{Int, Bank}(),
    scheduled_events::PriorityQueue{Int, AbstractEvent} = PriorityQueue{Int, AbstractEvent}(),
    interbank_loaning_term::Int = 7)
    return Simulation(
        1,  # next_event_id
        1,  # next_bank_id
        1,  # next_loan_id
        0,  # time
        banks,
        Dict{Int, Loan}(),  # client_loans
        Dict{Int, Loan}(),  # bank_loans
        Dict{Int, Loan}(),  # client_deposits
        PriorityQueue{AbstractEvent, Int}(),
        AbstractEvent[],    # executed_events
        interbank_loaning_term,
        Loan[],             # history_client_loans
        Loan[],             # history_bank_loans
        Loan[],             # history_client_deposits
        DataFrame(
            time = Int[],
            id = Int[],
            reserves = Int[],
            total_loan_assets = Int[],
            total_liabilities = Int[])
    )
end

function log_bank_states!(sim::Simulation)
    for (id, bank) in sim.banks
        push!(sim.history_banks, (
            time = sim.time,
            id = id,
            reserves = bank.reserves,
            total_liabilities = bank.total_liabilities,
            total_loan_assets = bank.total_loan_assets
        ))
    end
end