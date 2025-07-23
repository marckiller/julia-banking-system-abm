using DataStructures

mutable struct SimulationState

    #counters
    next_bank_id::Int
    next_loan_id::Int

    time::Int
    banks::Dict{Int, Bank}
    loans::Dict{Int, Loan}
    events::PriorityQueue{Int, Event}

    # Additional fields for simulation state
    total_deposits::Int
    total_loans::Int
    total_interbank_assets::Int
    total_interbank_liabilities::Int

    # Statistics for the simulation
    statistics::Dict{Symbol, Any}
end