function handle_client_loan_request_event!(state::SimulationState, event::Event)

    bank_id = event.payload[:bank_id]
    bank = state.banks[bank_id]

    principal = event.payload[:principal]
    term = event.payload[:term]

    bank_reserves_surplus_after_loan = bank.reserves - bank.min_reserves_frac * (bank.total_deposit_liability + bank.total_interbank_liabilities)

    if bank_reserves_surplus_after_loan >= 0
        #issue the loan (execute event GrantLoan immediately)
    else
        #check if the bank can borrow from the interbank market
    end

end

function handle_grant_loan_event!(state::SimulationState, event::Event)

    loan_id = event.payload[:loan_id]
    borrower = event.payload[:borrower]
    lender = event.payload[:lender]
    principal = event.payload[:principal]
    annual_interest_rate = event.payload[:annual_interest_rate]
    term = event.payload[:term]

    loan = BulletLoan(principal, annual_interest_rate, term, state.time, borrower, lender)

    # Add the loan to the simulation state and update the bank's loan records
    #also add the RepayLoan event to the event queue

end