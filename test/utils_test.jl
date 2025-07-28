using Test
using BankSim
@testset "Event Tests" begin

    using BankSim: pop!, check_interbank_loan, random_keys_except, Bank, create_bank
    
    # Test pop! function
    arr = [1, 2, 3, 4]
    dict = Dict(:a => 1, :b => 2, :c => 3)
    @test pop!(dict, :b) == 2
    @test haskey(dict, :b) == false
    @test pop!(dict, :a) == 1
    @test haskey(dict, :a) == false
    @test pop!(dict, :c) == 3
    @test haskey(dict, :c) == false
    @test pop!(dict, :d) == nothing

    #test random_keys_except
    dict = Dict(:a => 1, :b => 2, :c => 3, :d => 4)
    keys_except_b = random_keys_except(dict, :b)
    @test length(keys_except_b) == 3
    @test all(k -> k != :b, keys_except_b)
    @test all(k -> haskey(dict, k), keys_except_b)
    @test length(unique(keys_except_b)) == length(keys_except_b)

    # Test check_interbank_loan function
    bank = create_bank(1, 0, 0.5, 0.05, 0.02, 0.3)
    bank.total_liabilities = 200_000
    bank.reserves = 150_000 
    result1 = check_interbank_loan(bank, 49_999)
    @test result1 isa NamedTuple
    @test keys(result1) == (:is_available, :interest_rate, :max_amount)
    @test result1.is_available == true
    @test result1.interest_rate == 0.02
    @test result1.max_amount == 50_000
    result2 = check_interbank_loan(bank, 50_000)
    @test result2 isa NamedTuple
    @test result2.is_available == true
    @test result2.interest_rate == 0.02
    @test result2.max_amount == 50_000
    result3 = check_interbank_loan(bank, 50_001)
    @test result3 == nothing
    #none of bank attributes should change
    @test bank.reserves == 150_000
    @test bank.total_liabilities == 200_000
    @test bank.total_loan_assets == 0
    @test bank.min_reserves == 0.5
    @test bank.R_bank_loan == 0.02
    @test bank.R_client_loan == 0.05
    @test bank.R_deposit == 0.3

end