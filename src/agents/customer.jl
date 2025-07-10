include("agent.jl")

mutable struct Customer <: Agent
    id::Int
    cash::Int
    income::Int
end

function receive_income!(customer::Customer)
    customer.cash += customer.income
end