using Datastructures

include("bank.jl")
include("loan.jl")
include("event.jl")
include("event_handler.jl")

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
    
    scheduled_events::PriorityQueue{Int, AbstractEvent}
    executed_events::Vector{AbstractEvent}
end

function schedule_event!(simulation::Simulation, event::AbstractEvent)
    enqueue!(simulation.scheduled_events, event.time, event)
end

function execute_event!(simulation::Simulation, event::AbstractEvent)
    simulation.time = event.time
    handle_event!(simulation, event)
    push!(simulation.executed_events, event)
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