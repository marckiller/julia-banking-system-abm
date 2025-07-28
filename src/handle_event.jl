function handle_event!(simulation::Simulation, event::EventRepaymentClientLoan)
    #TODO: Later pop loans and return to simulation.history 
    loan = simulation.client_loans[event.loan_id]
    bank = simulation.banks[loan.lender]
    if rand() < event.default_probability
        bank.total_loan_assets -= loan.repayment
        loan.is_defaulted = true
    else
        bank.total_loan_assets -= loan.repayment
        bank.reserves += loan.repayment
    end
end

function handle_event!(simulation::Simulation, event::EventRepaymentBankLoan)
    #TODO: Later pop loans and return to simulation.history 
    loan = simulation.bank_loans[event.loan_id]
    bank_borrower = simulation.banks[loan.borrower]
    bank_lender = simulation.banks[loan.lender]
    
    if bank_borrower.reserves >= loan.repayment
        bank_borrower.reserves -= loan.repayment
        bank_borrower.total_liabilities -= loan.repayment
        bank_lender.reserves += loan.repayment
        bank_lender.total_loan_assets -= loan.repayment
    else
        # TODO: Handle insufficient reserves, e.g., default logic
        # note: bank at this point may have many other loans,
        # inter-bank loans and deposits
        bank_borrower.total_liabilities -= loan.repayment
        bank_lender.total_loan_assets -= loan.repayment
        loan.is_defaulted = true
        println("Bank $bank_borrower.id cannot repay loan $loan.id due to insufficient reserves.")
    end
end

function handle_event!(simulation::Simulation, event::EventRepaymentDeposit)
    #TODO: Later pop loans and return to simulation.history 
    deposit = simulation.client_deposits[event.deposit_id]
    bank = simulation.banks[deposit.borrower]
    
    if bank.reserves >= deposit.repayment
        bank.reserves -= deposit.repayment
        bank.total_liabilities -= deposit.repayment
    else
        # TODO: Handle insufficient reserves, e.g., default logic
        # note: bank at this point may have many other loans,
        # inter-bank loans and deposits
        deposit.is_defaulted = true
        println("Bank $bank.id cannot repay deposit $deposit.id due to insufficient reserves.")
    end
end

function handle_event!(simulation::Simulation, event::EventGrantClientDeposit)
    bank = simulation.banks[event.bank_id]
    #client logic skipped in this version
    deposit_id = get_loan_id!(simulation)
    deposit = BulletLoan(
        deposit_id,
        event.principal,
        event.annual_interest_rate,
        event.term,
        event.time,
        event.bank_id, #deposit is a loan where bank is a borrower
        event.client_id  #this version: client_id is nothign
    )

    #schedule repayment event
    repayment_event = EventRepaymentDeposit(
        get_event_id!(simulation),
        event.event_id,
        deposit.time_repay,
        deposit.id
    )
    #update bank state and simulation state
    simulation.client_deposits[deposit.id] = deposit
    bank.total_liabilities += deposit.repayment

    #schedule repayment event
    schedule_event!(simulation, repayment_event)
end

function handle_event!(simulation::Simulation, event::EventGrantClientLoan)
    bank = simulation.banks[event.bank_id]
    loan_id = get_loan_id!(simulation)
    loan = BulletLoan(
        loan_id,
        event.principal,
        event.annual_interest_rate,
        event.term,
        event.time,
        event.client_id,  # this version: client_id is nothing
        event.bank_id
    )

    # schedule repayment event
    repayment_event = EventRepaymentClientLoan(
        get_event_id!(simulation), event.event_id, loan.time_repay, loan.id, event.default_probability
    )
    
    # update bank state and simulation state
    simulation.client_loans[loan.id] = loan
    bank.total_loan_assets += loan.repayment
    bank.reserves -= loan.principal

    # schedule repayment event
    schedule_event!(simulation, repayment_event)
end

function handle_event!(simulation::Simulation, event::EventGrantBankLoan)
    bank_borrower = simulation.banks[event.bank_borrower_id]
    bank_lender = simulation.banks[event.bank_lender_id]
    
    loan_id = get_loan_id!(simulation)
    loan = BulletLoan(
        loan_id,
        event.principal,
        event.annual_interest_rate,
        event.term,
        event.time,
        event.bank_borrower_id,  # borrower is a bank
        event.bank_lender_id      # lender is a bank
    )

    # schedule repayment event
    repayment_event = EventRepaymentBankLoan(
        get_event_id!(simulation),
        event.event_id,
        loan.time_repay,
        loan.id
    )
    
    # update banks' states and simulation state
    simulation.bank_loans[loan.id] = loan

    bank_borrower.total_liabilities += loan.repayment
    bank_borrower.reserves += loan.principal

    bank_lender.total_loan_assets += loan.repayment
    bank_lender.reserves -= loan.principal

    # schedule repayment event
    schedule_event!(simulation, repayment_event)
end

function handle_event!(simulation::Simulation, event::EventRequestClientLoan)
    bank = simulation.banks[event.bank_id]

    required_reserves = bank.min_reserves * bank.total_liabilities
    available_reserves = bank.reserves - required_reserves

    expected_loan_value = (1 - event.default_probability) * event.principal * (1 + bank.R_client_loan / 365)^event.term

    if available_reserves >= event.principal
        #grant loan if profitable
        if expected_loan_value > event.principal
            #grant loan
            event_grant_loan = EventGrantClientLoan(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                nothing,
                event.bank_id,
                event.principal,
                event.term,
                bank.R_client_loan,
                event.default_probability
            )
            execute_event!(simulation, event_grant_loan)
            return true
        end
    else
        #check interbank loan market
        other_banks_ids = random_keys_except(simulation.banks, event.bank_id)
        for id in other_banks_ids
            response = check_interbank_loan(simulation.banks[id], event.principal)
            if response !== nothing
                #calculate profitability
                interbank_loan_repayment = event.principal * (1 + response.interest_rate / 365)^simulation.interbank_loaning_term
                expected_profit_after_loan = expected_loan_value - interbank_loan_repayment
                if expected_profit_after_loan > 0
                    # take loan from interbank market, grant loan for client
                    event_bank_loan_request = EventRequestBankLoan(
                        get_event_id!(simulation),
                        event.event_id,
                        event.time,
                        event.bank_id,
                        id,
                        event.principal,
                        simulation.interbank_loaning_term
                    )
                    execute_event!(simulation, event_bank_loan_request)

                    event_grant_client_loan = EventGrantClientLoan(
                        get_event_id!(simulation),
                        event.event_id,
                        event.time,
                        nothing,
                        event.bank_id,
                        event.principal,
                        event.term,
                        bank.R_client_loan,
                        event.default_probability
                    )
                    execute_event!(simulation, event_grant_client_loan)
                    return true
                end
            end
        end
    end
    return false
end

function handle_event!(simulation::Simulation, event::EventRequestBankLoan)
    #always accept reserves are sufficient
    bank_lender = simulation.banks[event.bank_lender_id]

    required_reserves = bank_lender.min_reserves * bank_lender.total_liabilities
    available_reserves = bank_lender.reserves - required_reserves

    if available_reserves >= event.principal
        #grant loan. this vesrion doesn't support interbank loans scoring
        event_grant_interbank_loan = EventGrantBankLoan(
            get_event_id!(simulation),
            event.event_id,
            event.time,
            event.bank_borrower_id,
            event.bank_lender_id,
            event.principal,
            event.term,
            bank_lender.R_bank_loan
        )
        execute_event!(simulation, event_grant_interbank_loan)
        return true
    else
        return false
    end
end

function handle_event!(simulation::Simulation, event::EventRequestClientDeposit)
    #aleways accept deposits
    bank = simulation.banks[event.bank_id]
    event_grant_deposit = EventGrantClientDeposit(
        get_event_id!(simulation),
        event.event_id,
        event.time,
        nothing,
        event.bank_id,
        event.principal,
        event.term,
        bank.R_deposit
    )

    execute_event!(simulation, event_grant_deposit)
    return true
end

function execute_event!(simulation::Simulation, event::AbstractEvent)
    simulation.time = event.time
    handle_event!(simulation, event)
    if event isa EventRepaymentClientLoan
        loan = pop!(simulation.client_loans, event.loan_id)
        push!(simulation.history_client_loans, loan)
    elseif event isa EventRepaymentBankLoan
        loan = pop!(simulation.bank_loans, event.loan_id)
        push!(simulation.history_bank_loans, loan)
    elseif event isa EventRepaymentDeposit
        deposit = pop!(simulation.client_deposits, event.deposit_id)
        push!(simulation.history_client_deposits, deposit)
    end
    push!(simulation.executed_events, event)
end

function run_simulation!(simulation::Simulation)
    while !isempty(simulation.scheduled_events)
        event = dequeue!(simulation.scheduled_events)
        simulation.time = max(simulation.time, event.time)
        execute_event!(simulation, event)
        log_bank_states!(simulation)
    end
end