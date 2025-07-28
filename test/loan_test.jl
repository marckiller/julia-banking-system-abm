using Test
using BankSim
@testset "Event Tests" begin 

    using BankSim: BulletLoan

    loan = BulletLoan(1, 1000, 0.05, 365, 0, 2, 3)
    @test loan.id == 1
    @test loan.principal == 1000
    @test loan.interest_rate == 0.05
    @test loan.term == 365
    @test loan.time_issued == 0
    @test loan.time_repay == 365
    @test loan.repayment == 1051
    @test loan.borrower == 2
    @test loan.lender == 3
    @test loan.is_defaulted == false
    loan.is_defaulted = true
    @test loan.is_defaulted == true

    loan = BulletLoan(2, 2000, 0.04, 730, 10, nothing, nothing)
    @test loan.borrower == nothing
    @test loan.lender == nothing


end