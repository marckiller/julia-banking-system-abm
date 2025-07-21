using DataStructures

mutable struct Simulation
    current_time::Int
    event_queue::PriorityQueue{Event, Int}
    customers::Vector{Client}
    banks::Vector{Bank}
end

function schedule_event!(sim::Simulation, event::Event)
    enqueue!(sim.event_queue, event, event.time)
end

function run!(sim::Simulation, end_time::Int)
    while !isempty(sim.event_queue) && sim.current_time < end_time
        (event, _) = dequeue_pair!(sim.event_queue)
        sim.current_time = event.time
        handle_event!(sim, event)
    end
end

function handle_event!(sim::Simulation, event::Event)
    println("[$(event.time)] Event: $(event.type), payload: $(event.payload)")
    # TODO handle the event based on its type
end
