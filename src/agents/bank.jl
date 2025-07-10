include("agent.jl")

mutable struct Bank <: Agent
    id::Int
    reserves::Int
    capital::Int
end