using Test
include("../../src/agents/agents.jl")

@testset "Agent structs" begin
    #Customer
    c = Customer(1, 500_00)
    @test c.id == 1
    @test c.cash == 500_00

    #Bank
    b = Bank(42, 1_000_00, 5_000_00)
    @test b.id == 42
    @test b.reserves == 1_000_00
    @test b.capital == 5_000_00

    c.cash += 100_00
    @test c.cash == 600_00

    b.reserves -= 200_00
    @test b.reserves == 800_00
end