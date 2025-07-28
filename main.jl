include("src/Project.jl")
using .Project
using DataStructures
using DataFrames
using CSV

#banks parameters
n_banks = 5
total_banks_initial_reserves = 1_000_000_000_000
bank_min_initial_reserves = 1_000_000_000
bank_min_reserves_factor = 0.3
R_deposit_min = 0.05
R_deposit_max = 0.02
R_client_loan_min = 0.1
R_client_loan_max = 0.25
R_interbank_loan = 0.07

#deposits/loans requests parameters
deposit_min_inflow_per_unit_time = 10 #loan/deposit inflow is proportional to banks rates of interest
deposit_max_inflow_per_unit_time = 100
loan_min_inflow_per_unit_time = 10
loan_max_inflow_per_unit_time = 100

deposit_min_value = 10_000
deposit_max_value = 1_000_000
loan_min_value = 10_000
loan_max_value = 1_000_000

deposits_terms = [10, 20, 30, 60, 90, 180, 360] #days
loans_terms = [30, 60, 90, 180, 360, 720, 1080, 1440] #days
interbank_loans_term = [1]

sim = create_simulation()
bank_ids = Int[]

    