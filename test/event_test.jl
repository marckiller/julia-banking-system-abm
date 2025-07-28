using Test
using BankSim
@testset "Event Tests" begin 

    using BankSim: AbstractEvent, EventRepaymentClientLoan, EventGrantClientLoan, EventRepaymentBankLoan, EventGrantBankLoan, EventRepaymentDeposit, EventGrantClientDeposit,
                    EventRequestClientLoan, EventRequestBankLoan, EventRequestClientDeposit

    e = EventRepaymentClientLoan(1, 2, 3, 4, 0.1)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.loan_id == 4
    @test e.default_probability == 0.1
    e = EventRepaymentClientLoan(1, nothing, 3, 4, 0.1)
    @test e.trigger_event_id == nothing

    e= EventRepaymentBankLoan(1, 2, 3, 4)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.loan_id == 4
    e= EventRepaymentBankLoan(1, nothing, 3, 4)
    @test e.trigger_event_id == nothing

    e = EventRepaymentDeposit(1, 2, 3, 4)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.deposit_id == 4
    e = EventRepaymentDeposit(1, nothing, 3, 4)
    @test e.trigger_event_id == nothing

    e = EventGrantClientLoan(1, 2, 3, 4, 5, 6, 7, 0.1, 0.5)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.client_id == 4
    @test e.bank_id == 5
    @test e.principal == 6
    @test e.term == 7
    @test e.annual_interest_rate == 0.1
    @test e.default_probability == 0.5
    e = EventGrantClientLoan(1, nothing, 3, 4, 5, 6, 7, 0.1, 0.5)
    @test e.trigger_event_id == nothing
    
    e = EventGrantClientDeposit(1, 2, 3, 4, 5, 6, 7, 0.1)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.client_id == 4
    @test e.bank_id == 5
    @test e.principal == 6
    @test e.term == 7
    @test e.annual_interest_rate == 0.1
    e = EventGrantClientDeposit(1, nothing, 3, 4, 5, 6, 7, 0.1)
    @test e.trigger_event_id == nothing

    e = EventGrantBankLoan(1, 2, 3, 4, 5, 6, 7, 0.1)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.bank_borrower_id == 4
    @test e.bank_lender_id == 5
    @test e.principal == 6
    @test e.term == 7
    @test e.annual_interest_rate == 0.1
    e = EventGrantBankLoan(1, nothing, 3, 4, 5, 6, 7, 0.1)
    @test e.trigger_event_id == nothing

    e = EventRequestClientLoan(1, 2, 3, 4, 5, 6, 7, 0.1)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.client_id == 4
    @test e.bank_id == 5
    @test e.principal == 6
    @test e.term == 7
    @test e.default_probability == 0.1
    e = EventRequestClientLoan(1, nothing, 3, nothing, 5, 6, 7, 0.1)
    @test e.trigger_event_id == nothing
    @test e.client_id == nothing
    
    e = EventRequestClientDeposit(1,2,3,4,5,6,7)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.client_id == 4
    @test e.bank_id == 5
    @test e.principal == 6
    @test e.term == 7
    e = EventRequestClientDeposit(1, nothing, 3, nothing, 5, 6, 7)
    @test e.trigger_event_id == nothing
    @test e.client_id == nothing

    e = EventRequestBankLoan(1, 2, 3, 4, 5, 6, 7)
    @test e.event_id == 1
    @test e.trigger_event_id == 2
    @test e.time == 3
    @test e.bank_borrower_id == 4
    @test e.bank_lender_id == 5
    @test e.principal == 6
    @test e.term == 7
    e = EventRequestBankLoan(1, nothing, 3, 4, 5, 6, 7)
    @test e.trigger_event_id == nothing

end