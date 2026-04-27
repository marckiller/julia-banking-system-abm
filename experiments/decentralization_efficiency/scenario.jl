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
    client_loan_arrival_rate::Float64,
    client_deposit_amount_range::Tuple{Int, Int},
    client_deposit_terms::Vector{Int},
    client_deposit_arrival_rate::Float64
)::Vector{DemandRequest}
    rng = MersenneTwister(scenario_seed)
    requests = DemandRequest[]
    client_id = 1

    current_time_loan = 0
    while current_time_loan <= simulation_duration_days
        current_time_loan += rand(rng, Poisson(1 / client_loan_arrival_rate))
        current_time_loan > simulation_duration_days && break

        push!(
            requests,
            DemandRequest(
                :client_loan,
                current_time_loan,
                client_id,
                rand(rng, client_loan_amount_range[1]:client_loan_amount_range[2]),
                rand(rng, client_loan_terms),
                rand(rng, Uniform(client_loan_default_prob_range...))
            )
        )
        client_id += 1
    end

    current_time_deposit = 0
    while current_time_deposit <= simulation_duration_days
        current_time_deposit += rand(rng, Poisson(1 / client_deposit_arrival_rate))
        current_time_deposit > simulation_duration_days && break

        push!(
            requests,
            DemandRequest(
                :client_deposit,
                current_time_deposit,
                client_id,
                rand(rng, client_deposit_amount_range[1]:client_deposit_amount_range[2]),
                rand(rng, client_deposit_terms),
                nothing
            )
        )
        client_id += 1
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
