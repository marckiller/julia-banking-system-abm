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
    scheduled_events::PriorityQueue{AbstractEvent, Int} = PriorityQueue{AbstractEvent, Int}(),
    interbank_loaning_term::Int = 1)

    next_bank_id = maximum([e.event_id for e in keys(scheduled_events)]; init=0) + 1
    next_event_id = isempty(scheduled_events) ? 1 :
        maximum([key.event_id for (key, _) in scheduled_events]; init=0) + 1
        
    return Simulation(
        next_event_id,  # next_event_id
        next_bank_id,  # next_bank_id
        1,  # next_loan_id
        0,  # time
        banks,
        Dict{Int, Loan}(),  # client_loans
        Dict{Int, Loan}(),  # bank_loans
        Dict{Int, Loan}(),  # client_deposits
        scheduled_events,
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

function add_bank!(sim::Simulation, initial_reserves::Int, min_reserves::Float64, R_client_loan::Float64, R_bank_loan::Float64, R_deposit::Float64)
    bank_id = get_bank_id!(sim)
    bank = create_bank(bank_id, initial_reserves, min_reserves, R_client_loan, R_bank_loan, R_deposit)
    sim.banks[bank_id] = bank
    println("Bank $(bank.id) created with initial reserves: ", bank.reserves)
    return bank
end