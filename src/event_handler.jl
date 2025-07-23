function handle_client_loan_request_event!(state::SimulationState, event::Event)

    bank_id = event.payload[:bank_id]
    bank = state.banks[bank_id]

    principal = event.payload[:principal]
    term = event.payload[:term]

    bank_reserves_surplus_after_loan = bank.reserves - bank.min_reserves_frac * (bank.total_liabilities)

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

    loan = BulletLoan(loan_id, principal, annual_interest_rate, term, state.time, borrower, lender)
    
    #update the bank's reserves and total loan records
    bank = state.banks[lender]
    bank.reserves -= principal
    bank.total_assets = loan.repay_amount
    
    state.loans[loan_id] = loan

    #create a RepayLoan event to be scheduled at the end_time of the loan
    repay_event = EventRepayLoan(loan.end_time, loan.id)
    schedule_event!(state, repay_event)
    
end