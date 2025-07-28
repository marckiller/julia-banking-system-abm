include("src/Project.jl")
using .Project
using DataStructures
using DataFrames
using CSV


sim = create_simulation()

bank_id = get_bank_id!(sim)
bank = create_bank(bank_id, 1_000_000, 0.2, 0.25, 0.05, 0.02)
sim.banks[bank_id] = bank
println("Bank $(bank.id) created with initial reserves: ", bank.reserves)


bank_2id = get_bank_id!(sim)
bank_2 = create_bank(bank_2id, 1_000_000, 0.1, 0.2, 0.1, 0.02)
sim.banks[bank_2id] = bank_2
println("Bank $(bank_2.id) created with initial reserves: ", bank_2.reserves)

N = 100000

for i in 1:N
    req_time   = rand(1:10000)
    principal  = rand(500:1000)
    term_days  = rand(30:3000)
    default_p  = 0.01 + rand() * (0.20 - 0.01)
    chosen_bank = rand(keys(sim.banks))

    event = EventRequestClientLoan(
        get_event_id!(sim),
        nothing,
        req_time,
        nothing,
        chosen_bank,
        principal,
        term_days,
        default_p
    )
    schedule_event!(sim, event)
end

run!(sim)
CSV.write("bank_stats.csv", sim.history_banks)

for (id, bank) in sim.banks
    println("\nFinal state of Bank $(id):")
    println("Reserves:          ", bank.reserves)
    println("Total Loan Assets: ", bank.total_loan_assets)
    println("Total Liabilities: ", bank.total_liabilities)
end