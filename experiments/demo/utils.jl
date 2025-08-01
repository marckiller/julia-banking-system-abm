using BankSim
using Distributions

function generate_initial_reserves(total::Int, n::Int)
    if n <= 0
        error("Number of banks must be positive")
    end
    base = div(total, n)
    extras = total - base * n
    reserves = fill(base, n)
    for i in 1:extras
        reserves[i] += 1
    end
    return reserves
end

function schedule_random_loan_requests!(
    sim::Simulation,
    arrival_rate::Float64,
    amount_range::Tuple{Int, Int},
    terms::Vector{Int},
    default_prob_range::Tuple{Float64, Float64},
    max_time::Int
)
    current_time = 0
    while current_time <= max_time
        current_time += rand(Poisson(1 / arrival_rate))
        if current_time > max_time
            break
        end
        bank_id = rand(1:length(sim.banks))
        principal = rand(amount_range[1]:amount_range[2])
        term = rand(terms)
        default_prob = rand(Uniform(default_prob_range...))
        event = EventRequestClientLoan(
            get_event_id!(sim),
            nothing,
            current_time,
            nothing,
            bank_id,
            principal,
            term,
            default_prob
        )
        schedule_event!(sim, event)
    end
end

function schedule_random_deposit_requests!(
    sim::Simulation,
    arrival_rate::Float64,
    amount_range::Tuple{Int, Int},
    terms::Vector{Int},
    max_time::Int
)
    current_time = 0
    while current_time <= max_time
        current_time += rand(Poisson(1 / arrival_rate))
        if current_time > max_time
            break
        end
        bank_id = rand(1:length(sim.banks))
        principal = rand(amount_range[1]:amount_range[2])
        term = rand(terms)
        event = EventRequestClientDeposit(
            get_event_id!(sim),
            nothing,
            current_time,
            nothing,
            bank_id,
            principal,
            term
        )
        schedule_event!(sim, event)
    end
end