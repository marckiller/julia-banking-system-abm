using DataStructures

struct Simulation
    current_time::Int
    event_queue::PriorityQueue{Event, Int}
    #customers::Vector{Agent}
    #banks::Vector{Agent}
end

