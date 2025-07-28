using CSV
using DataFrames
using StatsPlots

using CSV
using DataFrames
using StatsPlots

df = CSV.read("bank_stats.csv", DataFrame)
sort!(df, [:time, :id])
grouped = combine(groupby(df, [:time, :id])) do subdf
    last(subdf, 1)
end

bank_ids = unique(grouped.id)

for bank_id in bank_ids
    bank_df = filter(row -> row.id == bank_id, grouped)

    plot(
        bank_df.time,
        bank_df.reserves,
        label = "reserves",
        xlabel = "time",
        ylabel = "value",
        title = "Bank $(bank_id)",
        legend = :topleft
    )

    plot!(
        bank_df.time,
        bank_df.total_loan_assets,
        label = "loan assets"
    )
    
    plot!(
        bank_df.time,
        bank_df.total_liabilities,
        label = "liabilities"
    )

    savefig("bank_$(bank_id)_plot.png")
end