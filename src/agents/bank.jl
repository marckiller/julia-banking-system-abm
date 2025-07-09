mutable struct Bank
    id::Int
    capital::Int
    reserves::Int
    loans::Dict{Int, Int}
    deposits::Dict{Int, Int}
end
