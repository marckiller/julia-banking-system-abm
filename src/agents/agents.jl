abstract type Agent end

mutable struct Customer <: Agent
    id::Int
    cash::Int
end

mutable struct Bank <: Agent
    id::Int
    reserves::Int
    capital::Int
end