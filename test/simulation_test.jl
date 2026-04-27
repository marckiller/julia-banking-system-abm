using Test
using BankSim
using DataStructures
using DataFrames

@testset "Simulation Tests" begin 

    using BankSim: Simulation, schedule_event!, get_event_id!, get_bank_id!, get_loan_id!, create_simulation, log_bank_states!,
                EventRequestClientLoan

    bank1 = create_bank(1, 100_000, 0.1, 0.05, 0.02, 0.3)
    bank2 = create_bank(2, 200_000, 0.15, 0.06, 0.03, 0.4)
    banks = Dict(1 => bank1, 2 => bank2)

    event1 = EventRequestClientLoan(1, nothing, 10, nothing, 1, 1000, 10, 0.0)
    event2 = EventRequestClientLoan(2, nothing, 20, nothing, 2, 2000, 20, 0.0)
    event_queue = PriorityQueue{AbstractEvent, Int}()
    enqueue!(event_queue, event1 => event1.time)
    enqueue!(event_queue, event2 => event2.time)
    sim = create_simulation(banks, event_queue)

    @test sim.next_event_id == 3
    @test sim.next_bank_id == 3
    @test sim.next_loan_id == 1
    log_bank_states!(sim)
    @test nrow(sim.history_banks) == 2
    @test all(sim.history_banks.time .== 0)
    @test sort(sim.history_banks.id) == [1, 2]
    @test sim.history_banks[sim.history_banks.id .== 1, :reserves][1] == 100_000
    @test sim.history_banks[sim.history_banks.id .== 2, :reserves][1] == 200_000

end

@testset "Simulation Event Log Tests" begin
    sim = create_simulation()
    add_bank!(sim, 100_000, 0.1, 0.05, 0.02, 0.01)

    request = EventRequestClientLoan(
        get_event_id!(sim),
        nothing,
        1,
        nothing,
        1,
        1_000,
        1,
        0.0
    )
    schedule_event!(sim, request)
    run_simulation!(sim)

    @test any(e -> e isa EventBankCreated, sim.event_log)
    @test any(e -> e isa EventRequestClientLoan, sim.event_log)
    @test any(e -> e isa EventGrantClientLoan, sim.event_log)
    @test any(e -> e isa EventRepaymentClientLoan, sim.event_log)
    @test any(e -> e isa EventClientLoanRepaid, sim.event_log)
    @test !any(e -> e isa EventClientLoanDefaulted, sim.event_log)

    request_index = findfirst(e -> e isa EventRequestClientLoan, sim.event_log)
    grant_index = findfirst(e -> e isa EventGrantClientLoan, sim.event_log)
    repayment_due_index = findfirst(e -> e isa EventRepaymentClientLoan, sim.event_log)
    repayment_index = findfirst(e -> e isa EventClientLoanRepaid, sim.event_log)
    @test request_index < grant_index < repayment_due_index < repayment_index

    grant = only(filter(e -> e isa EventGrantClientLoan, sim.event_log))
    repayment = only(filter(e -> e isa EventClientLoanRepaid, sim.event_log))
    @test repayment.loan_id == grant.loan_id
    @test repayment.bank_id == grant.bank_id

    replayed_states = replay_bank_states(sim.event_log)
    final_replayed = last(filter(row -> row.id == 1, replayed_states))
    final_bank = sim.banks[1]
    @test final_replayed.reserves == final_bank.reserves
    @test final_replayed.total_liabilities == final_bank.total_liabilities
    @test final_replayed.total_loan_assets == final_bank.total_loan_assets
end
