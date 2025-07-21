abstract type Agent end

mutable struct Bank <: Agent
    id::Int
    reserves::Int
    reserve_ratio_minimum::Float64
    interest_rate_client::Float64
    interest_rate_bank::Float64 
    interest_rate_deposit::Float64
    #loans_out::Vector{Loan}
    #loans_in::Vector{Loan}
end

mutable struct Client <: Agent
    id::Int
    wealth::Int
    income::Int
    #loans::Vector{Loan}
    #deposits::Vector{Loan}
end