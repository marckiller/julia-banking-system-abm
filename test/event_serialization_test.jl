using Test
using BankSim

@testset "Event Serialization Tests" begin 
    event = EventRequestClientLoan(1, nothing, 10, 42, 3, 10000, 30, 0.05)
    flattened = flatten_event(event)

    @test flattened[:event_id] == 1
    @test flattened[:trigger_event_id] === nothing
    @test flattened[:time] == 10
    @test flattened[:event_type] == "EventRequestClientLoan"
    @test flattened[:client_id] == 42
    @test flattened[:bank_id] == 3
    @test flattened[:principal] == 10000
    @test flattened[:term] == 30
    @test flattened[:default_probability] == 0.05

    event = EventRepaymentClientLoan(2, 1, 11, 100, 0.1)
    flattened = flatten_event(event)
    @test flattened[:loan_id] == 100
    @test flattened[:default_probability] == 0.1

    event = EventRepaymentBankLoan(3, 2, 12, 101)
    flattened = flatten_event(event)
    @test flattened[:loan_id] == 101

    event = EventRepaymentDeposit(4, 3, 13, 102)
    flattened = flatten_event(event)
    @test flattened[:deposit_id] == 102

    event = EventGrantClientLoan(5, 4, 14, 43, 4, 20000, 60, 0.04, 0.02)
    flattened = flatten_event(event)
    @test flattened[:client_id] == 43
    @test flattened[:bank_id] == 4
    @test flattened[:principal] == 20000
    @test flattened[:term] == 60
    @test flattened[:annual_interest_rate] == 0.04
    @test flattened[:default_probability] == 0.02

    event = EventGrantBankLoan(6, 5, 16, 8, 9, 15000, 45, 0.035)
    flattened = flatten_event(event)
    @test flattened[:bank_borrower_id] == 8
    @test flattened[:bank_lender_id] == 9
    @test flattened[:principal] == 15000
    @test flattened[:term] == 45
    @test flattened[:annual_interest_rate] == 0.035

    event = EventRequestClientDeposit(7, 6, 17, 44, 5, 7000, 90)
    flattened = flatten_event(event)
    @test flattened[:client_id] == 44
    @test flattened[:bank_id] == 5
    @test flattened[:principal] == 7000
    @test flattened[:term] == 90

    event = EventRequestBankLoan(8, 7, 18, 10, 11, 18000, 75)
    flattened = flatten_event(event)
    @test flattened[:bank_borrower_id] == 10
    @test flattened[:bank_lender_id] == 11
    @test flattened[:principal] == 18000
    @test flattened[:term] == 75
end


@testset "Event Reconstruction Tests" begin
    # EventGrantClientDeposit
    original = EventGrantClientDeposit(2, 1, 15, 99, 7, 5000, 60, 0.03)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventRepaymentClientLoan
    original = EventRepaymentClientLoan(2, 1, 11, 100, 0.1)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventRepaymentBankLoan
    original = EventRepaymentBankLoan(3, 2, 12, 101)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventRepaymentDeposit
    original = EventRepaymentDeposit(4, 3, 13, 102)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventGrantClientLoan
    original = EventGrantClientLoan(5, 4, 14, 43, 4, 20000, 60, 0.04, 0.02)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventGrantBankLoan
    original = EventGrantBankLoan(6, 5, 16, 8, 9, 15000, 45, 0.035)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventRequestClientLoan
    original = EventRequestClientLoan(1, nothing, 10, 42, 3, 10000, 30, 0.05)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventRequestClientDeposit
    original = EventRequestClientDeposit(7, 6, 17, 44, 5, 7000, 90)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original

    # EventRequestBankLoan
    original = EventRequestBankLoan(8, 7, 18, 10, 11, 18000, 75)
    flattened = flatten_event(original)
    reconstructed = reconstruct_event(flattened)
    @test reconstructed == original
end