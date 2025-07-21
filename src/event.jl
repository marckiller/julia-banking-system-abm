struct Event
    time::Int
    type::Symbol
    payload::Dict{Symbol, Any}
end

function handle_loan_request!(sim::Simulation, payload::Dict{Symbol, Any})
    client = payload[:client]
    amount = payload[:amount]

    score_model = SimpleScoreModel()
    if score(score_model, client) < 0.5
        println("Loan denied: low credit score.")
        return
    end

    # Find a bank that can grant the loan 
    #TODO: Implement a more sophisticated bank selection process
    # current implementation doesn't force interbank lending 

    for agent in sim.banks
        if agent.reserves >= amount
            bank = agent

            loan = create_amortizing_loan(amount, bank.interest_rate_client, sim.current_time, 3, 7, client, bank)

            push!(client.loans, loan)
            push!(bank.loans_outstanding, loan)

            client.wealth += amount
            bank.reserves -= amount

            (t_next, _) = loan.schedule[1]
            schedule_event!(sim, Event(t_next, :loan_repayment, Dict(:loan => loan, :index => 1)))
            return
        end
    end

    println("No bank could grant the loan: insufficient reserves.")
end

