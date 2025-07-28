using Test
using BankSim
@testset "Bank Tests" begin 

    using BankSim: Bank, create_bank

    bank = create_bank(1, 1_000_000, 0.3, 0.1, 0.05, 0.02)

    @test bank.id == 1
    @test bank.reserves == 1_000_000
    @test bank.min_reserves == 0.3
    @test bank.R_client_loan == 0.1
    @test bank.R_bank_loan == 0.05
    @test bank.R_deposit == 0.02
    @test bank.total_liabilities == 0
    @test bank.total_loan_assets == 0

end