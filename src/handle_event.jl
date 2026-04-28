function handle_event!(simulation::Simulation, event::EventRepaymentClientLoan)
    #TODO: Later pop loans and return to simulation.history 
    loan = simulation.client_loans[event.loan_id]
    bank = simulation.banks[loan.lender]
    if rand() < event.default_probability
        bank.total_loan_assets -= loan.repayment
        loan.is_defaulted = true
        record_event!(
            simulation,
            EventClientLoanDefaulted(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                loan.id,
                loan.lender,
                loan.repayment
            )
        )
    else
        bank.total_loan_assets -= loan.repayment
        bank.reserves += loan.repayment
        record_event!(
            simulation,
            EventClientLoanRepaid(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                loan.id,
                loan.lender,
                loan.repayment
            )
        )
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
        record_event!(
            simulation,
            EventBankLoanRepaid(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                loan.id,
                loan.borrower,
                loan.lender,
                loan.repayment
            )
        )
    else
        # TODO: Handle insufficient reserves, e.g., default logic
        # note: bank at this point may have many other loans,
        # inter-bank loans and deposits
        bank_borrower.total_liabilities -= loan.repayment
        bank_lender.total_loan_assets -= loan.repayment
        loan.is_defaulted = true
        record_event!(
            simulation,
            EventBankLoanDefaulted(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                loan.id,
                loan.borrower,
                loan.lender,
                loan.repayment
            )
        )
    end
end

function handle_event!(simulation::Simulation, event::EventRepaymentDeposit)
    #TODO: Later pop loans and return to simulation.history 
    deposit = simulation.client_deposits[event.deposit_id]
    bank = simulation.banks[deposit.borrower]
    
    if bank.reserves >= deposit.repayment
        bank.reserves -= deposit.repayment
        bank.total_liabilities -= deposit.repayment
        record_event!(
            simulation,
            EventDepositRepaid(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                deposit.id,
                deposit.borrower,
                deposit.repayment
            )
        )
    else
        # TODO: Handle insufficient reserves, e.g., default logic
        # note: bank at this point may have many other loans,
        # inter-bank loans and deposits
        deposit.is_defaulted = true
        bank.total_liabilities -= deposit.repayment
        record_event!(
            simulation,
            EventDepositDefaulted(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                deposit.id,
                deposit.borrower,
                deposit.repayment
            )
        )
   end
end

function handle_event!(simulation::Simulation, event::EventGrantClientDeposit)
    bank = simulation.banks[event.bank_id]
    #client logic skipped in this version
    deposit = BulletLoan(
        event.deposit_id,
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
    bank.reserves += deposit.principal
    bank.total_liabilities += deposit.repayment

    #schedule repayment event
    schedule_event!(simulation, repayment_event)
end

function handle_event!(simulation::Simulation, event::EventGrantClientLoan)
    bank = simulation.banks[event.bank_id]
    loan = BulletLoan(
        event.loan_id,
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
    
    loan = BulletLoan(
        event.loan_id,
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
    rejection_reason = "negative_expected_value_credit_risk"

    if available_reserves >= event.principal
        #grant loan if profitable
        if expected_loan_value > event.principal
            #grant loan
            event_grant_loan = EventGrantClientLoan(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                event.client_id,
                event.bank_id,
                get_loan_id!(simulation),
                event.principal,
                event.term,
                bank.R_client_loan,
                event.default_probability
            )
            execute_event!(simulation, event_grant_loan)
            return true
        end
    else
        if available_reserves < 0
            rejection_reason = "reserve_constraint_violation"
        elseif expected_loan_value <= event.principal
            rejection_reason = "negative_expected_value_credit_risk"
        else
            rejection_reason = "insufficient_liquidity_after_own_reserves"
        end

        #check interbank loan market
        interbank_liquidity_found = false
        other_banks_ids = random_keys_except(simulation.banks, event.bank_id)
        for id in other_banks_ids
            response = check_interbank_loan(simulation.banks[id], event.principal)
            if response !== nothing
                interbank_liquidity_found = true
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
                        event.client_id,
                        event.bank_id,
                        get_loan_id!(simulation),
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

        if interbank_liquidity_found
            rejection_reason = "insufficient_liquidity_even_after_interbank_funding"
        end
    end
    record_event!(
        simulation,
        EventRejectClientLoan(
            get_event_id!(simulation),
            event.event_id,
            event.time,
            event.client_id,
            event.bank_id,
            event.principal,
            event.term,
            event.default_probability,
            rejection_reason
        )
    )
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
            get_loan_id!(simulation),
            event.principal,
            event.term,
            bank_lender.R_bank_loan
        )
        execute_event!(simulation, event_grant_interbank_loan)
        return true
    else
        record_event!(
            simulation,
            EventRejectBankLoan(
                get_event_id!(simulation),
                event.event_id,
                event.time,
                event.bank_borrower_id,
                event.bank_lender_id,
                event.principal,
                event.term,
                "insufficient_lender_liquidity"
            )
        )
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
        get_loan_id!(simulation),
        event.principal,
        event.term,
        bank.R_deposit
    )

    execute_event!(simulation, event_grant_deposit)
    return true
end

function execute_event!(simulation::Simulation, event::AbstractEvent)
    simulation.time = event.time
    record_event!(simulation, event)
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
end

function run_simulation!(simulation::Simulation)
    while !isempty(simulation.scheduled_events)
        (next_event, _) = peek(simulation.scheduled_events)
        current_time = next_event.time
        simulation.time = current_time

        today_events = AbstractEvent[]
        while !isempty(simulation.scheduled_events)
            (e, _) = peek(simulation.scheduled_events)
            if e.time!= current_time
                break
            end
            push!(today_events, dequeue!(simulation.scheduled_events))
        end

        for event_type in simulation.priority_order
            for event in today_events
                if isa(event, event_type)
                    execute_event!(simulation, event)
                end
            end
        end
        log_bank_states!(simulation)
    end
end
