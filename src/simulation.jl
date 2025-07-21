using DataStructures

struct Simulation
    current_time::Int
    event_queue::PriorityQueue{Event, Int}
    #customers::Vector{Agent}
    #banks::Vector{Agent}
end

function schedule_event!(sim::Simulation, event::Event)
    enqueue!(sim.event_queue, event, event.time)
end

function run!(sim::Simulation, end_time::Int)
    while !isempty(sim.event_queue) && sim.current_time < end_time
        event = dequeue!(sim.event_queue)
        sim.current_time = event.time
        # Process the event
    end
end

function handle_event!(sim::Simulation, event::Event)
    println("[$(event.time)] Event: $(event.type), payload: $(event.payload)")
    # TODO handle the event based on its type
end
