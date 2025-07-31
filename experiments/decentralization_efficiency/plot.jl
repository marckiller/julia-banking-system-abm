using DataFrames
using CSV

include("config.jl")
include("utils.jl")

file_path = "results/decentralization_efficiency"
file = joinpath(file_path, "results.csv")

df = CSV.read(file, DataFrame)

function add_derived_metrics!(df::DataFrame)
    df[!, :p_client_loans_granted] = df.n_client_loan_granted ./ df.n_client_loan_requests
    df[!, :p_defaulted_deposits] = df.n_defaulted_deposits ./ df.n_client_deposits
    df[!, :bank_net_growth_ratio] = df.total_final_banks_net ./ df.total_initial_banks_net
    df[!, :p_defaulted_interbank_loans] = df.n_defaulted_bank_loans ./ df.n_interbank_loans           
    return df
end

function add_score_column!(
    df::DataFrame;
    a1::Float64 = 1.0,
    a2::Float64 = 1.0,
    a3::Float64 = 1.0
)
    df.score = [
        row.bank_net_growth_ratio <= 0.0 ? 0.0 :
        a1 * (1.0 - row.:p_defaulted_deposits) +
        a2 * row.:p_client_loans_granted +
        a3 * (1.0 - row.:p_defaulted_interbank_loans)
        for row in eachrow(df)
    ]
    return df
end

function avg_metrics(df::DataFrame, averaging_n::Int, columns::Vector{Symbol})
    grouped = groupby(df, [:NUM_BANKS, :MIN_RESERVES_FACTOR])
    result = combine(grouped, columns .=> mean .=> columns)
    return result
end

add_derived_metrics!(df)
add_score_column!(df)

cols_to_average = [
    :p_client_loans_granted,
    :p_defaulted_deposits,
    :bank_net_growth_ratio,
    :p_defaulted_interbank_loans,
    :score
]

avg_df = avg_metrics(df, 5, cols_to_average)

using StatsPlots
using DataFrames

function save_heatmap(df::DataFrame, row_col::Symbol, col_col::Symbol, value_col::Symbol, savepath::String)
    pivot = unstack(df, row_col, col_col, value_col)
    row_vals = pivot[!, row_col]
    mat = Matrix(pivot[:, Not(row_col)])

    heatmap(
        names(pivot)[2:end],
        string.(row_vals),
        mat;
        xlabel=string(col_col),
        ylabel=string(row_col),
        title=string(value_col),
        colorbar_title=string(value_col),
        size=(800, 600)
    )
    savefig(savepath)
    println("Heatmap saved to $savepath")
end

mkpath("results/decentralization_efficiency")

for metric in cols_to_average
    savepath = joinpath("results/decentralization_efficiency", "heatmap_$(metric).png")
    save_heatmap(avg_df, :NUM_BANKS, :MIN_RESERVES_FACTOR, metric, savepath)
end