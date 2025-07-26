function handle_event!(simulation::Simulation, event::EventRepaymentClientLoan)
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
        println("Bank $bank_borrower.id cannot repay loan $loan.id due to insufficient reserves.")
    end
end

function handle_event!(simulation::Simulation, event::EventRepaymentDeposit)
    deposit = simulation.client_deposits[event.deposit_id]
    bank = simulation.banks[deposit.borrower]
    
    if bank.reserves >= deposit.repayment
        bank.reserves -= deposit.repayment
        bank.total_liabilities -= deposit.repayment
    else
        # TODO: Handle insufficient reserves, e.g., default logic
        # note: bank at this point may have many other loans,
        # inter-bank loans and deposits
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
        event.client_id,  #this version: client_id is nothign
        event.bank_id
    )

    #schedule repayment event
    repayment_event = EventRepaymentDeposit(
        event_id = get_event_id!(simulation),
        trigger_event_id = event.event_id,
        time = deposit.time_repay,
        deposit_id = deposit.id
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
        event_id = get_event_id!(simulation),
        trigger_event_id = event.event_id,
        time = loan.time_repay,
        loan_id = loan.id,
        default_probability = event.default_probability
    )
    
    # update bank state and simulation state
    simulation.client_loans[loan.id] = loan
    bank.total_loan_assets += loan.repayment

    # schedule repayment event
    schedule_event!(simulation, repayment_event)
end

