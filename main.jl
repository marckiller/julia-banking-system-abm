using DataStructures

include("src/event.jl")
include("src/simulation.jl")

sim = Simulation(0, PriorityQueue{Event, Int}())

ev1 = Event(10, :print, Dict(:msg => "Hello at t=10"))
ev2 = Event(5, :print, Dict(:msg => "Early hello"))
ev3 = Event(20, :print, Dict(:msg => "Late hello"))

schedule_event!(sim, ev1)
schedule_event!(sim, ev2)
schedule_event!(sim, ev3)

run!(sim, 30)