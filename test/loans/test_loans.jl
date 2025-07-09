using Test
include("../../src/loans/loan.jl")

@testset "Loan struct and functions" begin
    loan = Loan_simple(100_00, 0.1, 5)

    @test loan.principal == 100_00
    @test loan.interest == 0.1
    @test loan.due_in == 5

    @test total_due(loan) == 110_00

    update_due!(loan)
    @test loan.due_in == 4

    loan.due_in = 1
    update_due!(loan)
    @test loan.due_in == 0
    @test is_due(loan) == true
end