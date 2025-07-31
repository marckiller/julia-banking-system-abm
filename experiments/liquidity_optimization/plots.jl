using CSV
using DataFrames
include("config.jl")

df = CSV.read("results/liquidity_optimization/results.csv", DataFrame)

v_min_reserves_factor =  V_MIN_RESERVES_FACTOR
v_r_client_loan = V_R_CLIENT_LOAN 
v_r_deposit= V_R_DEPOSIT
v_r_bank_loan= V_R_BANK_LOAN

#print the first 10 rows of the DataFrame
println("First 10 rows of the DataFrame:")
println(first(df, 10))