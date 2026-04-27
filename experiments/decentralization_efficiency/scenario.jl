using Random
using Distributions

struct DemandRequest
    request_type::Symbol
    time::Int
    client_id::Int
    principal::Int
    term::Int
    default_probability::Union{Float64, Nothing}
end

function generate_demand_scenario(
    scenario_seed::Int,
    simulation_duration_days::Int,
    client_loan_amount_range::Tuple{Int, Int},
    client_loan_terms::Vector{Int},
    client_loan_default_prob_range::Tuple{Float64, Float64},
    client_loan_requests_per_day::Float64,
    client_deposit_amount_range::Tuple{Int, Int},
    client_deposit_terms::Vector{Int},
    client_deposit_requests_per_day::Float64
)::Vector{DemandRequest}
    rng = MersenneTwister(scenario_seed)
    requests = DemandRequest[]
    client_id = 1

    for day in 1:simulation_duration_days
        n_loan_requests = rand(rng, Poisson(client_loan_requests_per_day))
        for _ in 1:n_loan_requests
            push!(
                requests,
                DemandRequest(
                    :client_loan,
                    day,
                    client_id,
                    rand(rng, client_loan_amount_range[1]:client_loan_amount_range[2]),
                    rand(rng, client_loan_terms),
                    rand(rng, Uniform(client_loan_default_prob_range...))
                )
            )
            client_id += 1
        end

        n_deposit_requests = rand(rng, Poisson(client_deposit_requests_per_day))
        for _ in 1:n_deposit_requests
            push!(
                requests,
                DemandRequest(
                    :client_deposit,
                    day,
                    client_id,
                    rand(rng, client_deposit_amount_range[1]:client_deposit_amount_range[2]),
                    rand(rng, client_deposit_terms),
                    nothing
                )
            )
            client_id += 1
        end
    end

    return sort(requests; by = request -> (request.time, request.client_id))
end

function route_scenario!(
    sim::Simulation,
    scenario::Vector{DemandRequest},
    num_banks::Int
)
    for request in scenario
        bank_id = rand(1:num_banks)

        if request.request_type == :client_loan
            schedule_event!(
                sim,
                EventRequestClientLoan(
                    get_event_id!(sim),
                    nothing,
                    request.time,
                    request.client_id,
                    bank_id,
                    request.principal,
                    request.term,
                    request.default_probability::Float64
                )
            )
        elseif request.request_type == :client_deposit
            schedule_event!(
                sim,
                EventRequestClientDeposit(
                    get_event_id!(sim),
                    nothing,
                    request.time,
                    request.client_id,
                    bank_id,
                    request.principal,
                    request.term
                )
            )
        else
            error("Unknown request type: $(request.request_type)")
        end
    end
end
